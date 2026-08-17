-- SQL Full Mastery Part 118 - Advanced interview lab
-- PostgreSQL 15+
BEGIN;

CREATE SCHEMA IF NOT EXISTS lab;
SET search_path = lab, public;

CREATE TABLE account (
    account_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_code    text NOT NULL UNIQUE,
    created_at      timestamptz NOT NULL,
    region_code     text NOT NULL,
    plan_code       text NOT NULL,
    CHECK (account_code <> ''),
    CHECK (region_code ~ '^[A-Z]{2}$')
);

CREATE TABLE app_user (
    user_id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id      bigint NOT NULL REFERENCES account(account_id),
    user_code       text NOT NULL,
    created_at      timestamptz NOT NULL,
    status          text NOT NULL CHECK (status IN ('ACTIVE','SUSPENDED','DELETED')),
    UNIQUE (account_id, user_code),
    UNIQUE (account_id, user_id)
);

CREATE TABLE event_log (
    event_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id      bigint NOT NULL,
    user_id         bigint NOT NULL,
    event_name      text NOT NULL,
    event_time      timestamptz NOT NULL,
    ingested_at     timestamptz NOT NULL DEFAULT clock_timestamp(),
    page_code       text,
    order_id        bigint,
    amount_paise    bigint,
    attributes      jsonb NOT NULL DEFAULT '{}'::jsonb,
    FOREIGN KEY (account_id, user_id)
      REFERENCES app_user(account_id, user_id),
    CHECK (event_name <> ''),
    CHECK (amount_paise IS NULL OR amount_paise >= 0)
);

CREATE TABLE product (
    product_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku             text NOT NULL UNIQUE,
    product_name    text NOT NULL,
    category_code   text NOT NULL
);

CREATE TABLE product_price_history (
    price_version_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id       bigint NOT NULL REFERENCES product(product_id),
    valid_from       timestamptz NOT NULL,
    valid_to         timestamptz,
    price_paise      bigint NOT NULL CHECK (price_paise >= 0),
    currency_code    char(3) NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
    CHECK (valid_to IS NULL OR valid_to > valid_from),
    UNIQUE (product_id, valid_from)
);

CREATE TABLE sales_order (
    order_id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id       bigint NOT NULL REFERENCES account(account_id),
    user_id          bigint NOT NULL,
    ordered_at       timestamptz NOT NULL,
    status           text NOT NULL CHECK (status IN ('PENDING','PAID','CANCELLED','REFUNDED')),
    total_paise      bigint NOT NULL CHECK (total_paise >= 0),
    currency_code    char(3) NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
    idempotency_key  text NOT NULL,
    request_hash     text NOT NULL,
    FOREIGN KEY (account_id, user_id)
      REFERENCES app_user(account_id, user_id),
    UNIQUE (account_id, idempotency_key)
);

CREATE TABLE order_line (
    order_id         bigint NOT NULL REFERENCES sales_order(order_id),
    line_no          integer NOT NULL CHECK (line_no > 0),
    product_id       bigint NOT NULL REFERENCES product(product_id),
    quantity         integer NOT NULL CHECK (quantity > 0),
    unit_price_paise bigint NOT NULL CHECK (unit_price_paise >= 0),
    PRIMARY KEY (order_id, line_no)
);

CREATE TABLE employee (
    employee_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_code    text NOT NULL UNIQUE,
    employee_name    text NOT NULL,
    manager_id       bigint REFERENCES employee(employee_id),
    valid_from       date NOT NULL,
    valid_to         date,
    CHECK (valid_to IS NULL OR valid_to > valid_from)
);

CREATE TABLE api_command (
    account_id       bigint NOT NULL REFERENCES account(account_id),
    idempotency_key  text NOT NULL,
    request_hash     text NOT NULL,
    command_status   text NOT NULL CHECK (command_status IN ('STARTED','SUCCEEDED','FAILED')),
    result_json      jsonb,
    created_at       timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY (account_id, idempotency_key)
);

CREATE INDEX event_user_time_idx
    ON event_log (account_id, user_id, event_time, event_id);
CREATE INDEX event_name_time_idx
    ON event_log (event_name, event_time, event_id);
CREATE INDEX order_user_time_idx
    ON sales_order (account_id, user_id, ordered_at DESC, order_id DESC);
CREATE INDEX price_asof_idx
    ON product_price_history (product_id, valid_from DESC)
    INCLUDE (valid_to, price_paise, currency_code);
CREATE INDEX employee_manager_idx ON employee (manager_id, employee_id);

COMMENT ON TABLE event_log IS 'One immutable observed product event; event_time is business occurrence time and ingested_at is arrival time.';
COMMENT ON COLUMN sales_order.total_paise IS 'Order total in integer minor units; never binary floating point.';

COMMIT;
