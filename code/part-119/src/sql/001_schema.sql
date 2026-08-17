-- SQL Full Mastery Part 119 - Interview Lab Schema
-- PostgreSQL 15+
BEGIN;
CREATE SCHEMA IF NOT EXISTS interview119;
SET search_path = interview119, public;

CREATE TABLE tenant (
    tenant_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_code    text NOT NULL UNIQUE,
    status         text NOT NULL CHECK (status IN ('ACTIVE','SUSPENDED','DELETED')),
    created_at     timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE customer (
    tenant_id      bigint NOT NULL REFERENCES tenant(tenant_id),
    customer_id    bigint GENERATED ALWAYS AS IDENTITY,
    email          text,
    display_name   text NOT NULL,
    status         text NOT NULL CHECK (status IN ('ACTIVE','BLOCKED','DELETED')),
    created_at     timestamptz NOT NULL DEFAULT clock_timestamp(),
    deleted_at     timestamptz,
    PRIMARY KEY (tenant_id, customer_id),
    CHECK ((status = 'DELETED') = (deleted_at IS NOT NULL))
);
CREATE UNIQUE INDEX ux_customer_live_email
ON customer (tenant_id, lower(email))
WHERE deleted_at IS NULL AND email IS NOT NULL;

CREATE TABLE product (
    tenant_id      bigint NOT NULL REFERENCES tenant(tenant_id),
    product_id     bigint GENERATED ALWAYS AS IDENTITY,
    sku            text NOT NULL,
    name           text NOT NULL,
    status         text NOT NULL CHECK (status IN ('ACTIVE','DISCONTINUED')),
    price_paise    bigint NOT NULL CHECK (price_paise >= 0),
    currency_code  char(3) NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
    row_version    integer NOT NULL DEFAULT 1 CHECK (row_version > 0),
    PRIMARY KEY (tenant_id, product_id),
    UNIQUE (tenant_id, sku)
);

CREATE TABLE warehouse (
    tenant_id      bigint NOT NULL REFERENCES tenant(tenant_id),
    warehouse_id   bigint GENERATED ALWAYS AS IDENTITY,
    warehouse_code text NOT NULL,
    time_zone_name text NOT NULL,
    PRIMARY KEY (tenant_id, warehouse_id),
    UNIQUE (tenant_id, warehouse_code)
);

CREATE TABLE stock_balance (
    tenant_id      bigint NOT NULL,
    warehouse_id   bigint NOT NULL,
    product_id     bigint NOT NULL,
    on_hand_qty    bigint NOT NULL CHECK (on_hand_qty >= 0),
    reserved_qty   bigint NOT NULL CHECK (reserved_qty >= 0 AND reserved_qty <= on_hand_qty),
    row_version    integer NOT NULL DEFAULT 1,
    PRIMARY KEY (tenant_id, warehouse_id, product_id),
    FOREIGN KEY (tenant_id, warehouse_id) REFERENCES warehouse(tenant_id, warehouse_id),
    FOREIGN KEY (tenant_id, product_id) REFERENCES product(tenant_id, product_id)
);

CREATE TABLE sales_order (
    tenant_id      bigint NOT NULL,
    order_id       bigint GENERATED ALWAYS AS IDENTITY,
    customer_id    bigint NOT NULL,
    idempotency_key text NOT NULL,
    request_hash   text NOT NULL,
    status         text NOT NULL CHECK (status IN ('PENDING','CONFIRMED','CANCELLED','FULFILLED')),
    ordered_at     timestamptz NOT NULL,
    total_paise    bigint NOT NULL CHECK (total_paise >= 0),
    currency_code  char(3) NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
    PRIMARY KEY (tenant_id, order_id),
    UNIQUE (tenant_id, idempotency_key),
    FOREIGN KEY (tenant_id, customer_id) REFERENCES customer(tenant_id, customer_id)
);

CREATE TABLE sales_order_line (
    tenant_id      bigint NOT NULL,
    order_id       bigint NOT NULL,
    line_no        integer NOT NULL CHECK (line_no > 0),
    product_id     bigint NOT NULL,
    sku_snapshot   text NOT NULL,
    name_snapshot  text NOT NULL,
    quantity       integer NOT NULL CHECK (quantity > 0),
    unit_price_paise bigint NOT NULL CHECK (unit_price_paise >= 0),
    PRIMARY KEY (tenant_id, order_id, line_no),
    FOREIGN KEY (tenant_id, order_id) REFERENCES sales_order(tenant_id, order_id),
    FOREIGN KEY (tenant_id, product_id) REFERENCES product(tenant_id, product_id)
);

CREATE TABLE resource_booking (
    tenant_id      bigint NOT NULL REFERENCES tenant(tenant_id),
    booking_id     bigint GENERATED ALWAYS AS IDENTITY,
    resource_key   text NOT NULL,
    customer_id    bigint NOT NULL,
    starts_at      timestamptz NOT NULL,
    ends_at        timestamptz NOT NULL,
    status         text NOT NULL CHECK (status IN ('HELD','CONFIRMED','CANCELLED','EXPIRED')),
    idempotency_key text NOT NULL,
    request_hash   text NOT NULL,
    PRIMARY KEY (tenant_id, booking_id),
    UNIQUE (tenant_id, idempotency_key),
    FOREIGN KEY (tenant_id, customer_id) REFERENCES customer(tenant_id, customer_id),
    CHECK (starts_at < ends_at)
);
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE resource_booking
ADD CONSTRAINT ex_booking_no_overlap
EXCLUDE USING gist (
  tenant_id WITH =,
  resource_key WITH =,
  tstzrange(starts_at, ends_at, '[)') WITH &&
) WHERE (status IN ('HELD','CONFIRMED'));

CREATE TABLE account (
    tenant_id      bigint NOT NULL REFERENCES tenant(tenant_id),
    account_id     bigint GENERATED ALWAYS AS IDENTITY,
    account_code   text NOT NULL,
    account_type   text NOT NULL CHECK (account_type IN ('ASSET','LIABILITY','EQUITY','REVENUE','EXPENSE')),
    currency_code  char(3) NOT NULL,
    PRIMARY KEY (tenant_id, account_id),
    UNIQUE (tenant_id, account_code)
);

CREATE TABLE journal_entry (
    tenant_id      bigint NOT NULL REFERENCES tenant(tenant_id),
    entry_id       bigint GENERATED ALWAYS AS IDENTITY,
    command_key    text NOT NULL,
    request_hash   text NOT NULL,
    effective_at   timestamptz NOT NULL,
    posted_at      timestamptz NOT NULL DEFAULT clock_timestamp(),
    description    text NOT NULL,
    reversal_of_entry_id bigint,
    PRIMARY KEY (tenant_id, entry_id),
    UNIQUE (tenant_id, command_key),
    FOREIGN KEY (tenant_id, reversal_of_entry_id) REFERENCES journal_entry(tenant_id, entry_id)
);

CREATE TABLE posting (
    tenant_id      bigint NOT NULL,
    entry_id       bigint NOT NULL,
    posting_no     integer NOT NULL,
    account_id     bigint NOT NULL,
    side           char(1) NOT NULL CHECK (side IN ('D','C')),
    amount_paise   bigint NOT NULL CHECK (amount_paise > 0),
    currency_code  char(3) NOT NULL,
    PRIMARY KEY (tenant_id, entry_id, posting_no),
    FOREIGN KEY (tenant_id, entry_id) REFERENCES journal_entry(tenant_id, entry_id),
    FOREIGN KEY (tenant_id, account_id) REFERENCES account(tenant_id, account_id)
);

CREATE TABLE job_queue (
    tenant_id      bigint NOT NULL REFERENCES tenant(tenant_id),
    job_id         bigint GENERATED ALWAYS AS IDENTITY,
    job_type       text NOT NULL,
    payload        jsonb NOT NULL,
    state          text NOT NULL CHECK (state IN ('READY','RUNNING','DONE','FAILED')),
    available_at   timestamptz NOT NULL,
    claimed_by     text,
    claimed_at     timestamptz,
    attempt_count  integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    PRIMARY KEY (tenant_id, job_id)
);
CREATE INDEX ix_job_claim ON job_queue (available_at, job_id) WHERE state = 'READY';

CREATE TABLE schema_migration (
    version        bigint PRIMARY KEY,
    description    text NOT NULL,
    applied_at     timestamptz NOT NULL DEFAULT clock_timestamp(),
    checksum       text NOT NULL UNIQUE
);

CREATE TABLE audit_event (
    audit_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id      bigint,
    actor_id       text NOT NULL,
    action         text NOT NULL,
    object_type    text NOT NULL,
    object_key     text NOT NULL,
    occurred_at    timestamptz NOT NULL DEFAULT clock_timestamp(),
    before_state   jsonb,
    after_state    jsonb,
    correlation_id text NOT NULL
);
CREATE INDEX ix_audit_tenant_time ON audit_event (tenant_id, occurred_at DESC, audit_id DESC);
COMMIT;
