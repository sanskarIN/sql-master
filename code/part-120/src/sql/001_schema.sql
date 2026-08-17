-- SQL Full Mastery Part 120 - Final Interview Lab
-- PostgreSQL 15+
BEGIN;
CREATE SCHEMA IF NOT EXISTS final120;
SET search_path=final120,public;

CREATE TABLE customer (
  customer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email text UNIQUE,
  region text NOT NULL,
  created_at timestamptz NOT NULL,
  status text NOT NULL CHECK (status IN ('ACTIVE','BLOCKED','DELETED'))
);

CREATE TABLE product (
  product_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku text NOT NULL UNIQUE,
  product_name text NOT NULL,
  category text NOT NULL,
  price_paise bigint NOT NULL CHECK (price_paise>=0),
  currency_code char(3) NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$')
);

CREATE TABLE sales_order (
  order_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES customer(customer_id),
  idempotency_key text NOT NULL UNIQUE,
  request_hash text NOT NULL,
  ordered_at timestamptz NOT NULL,
  status text NOT NULL CHECK (status IN ('PENDING','PAID','CANCELLED','FULFILLED')),
  total_paise bigint NOT NULL CHECK (total_paise>=0),
  currency_code char(3) NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$')
);

CREATE TABLE sales_order_line (
  order_id bigint NOT NULL REFERENCES sales_order(order_id),
  line_no integer NOT NULL CHECK (line_no>0),
  product_id bigint NOT NULL REFERENCES product(product_id),
  sku_snapshot text NOT NULL,
  quantity integer NOT NULL CHECK (quantity>0),
  unit_price_paise bigint NOT NULL CHECK (unit_price_paise>=0),
  PRIMARY KEY(order_id,line_no)
);

CREATE TABLE product_event (
  event_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES customer(customer_id),
  event_name text NOT NULL,
  product_id bigint REFERENCES product(product_id),
  occurred_at timestamptz NOT NULL,
  ingested_at timestamptz NOT NULL,
  properties jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX ix_event_customer_time ON product_event(customer_id,occurred_at,event_id);

CREATE TABLE stock_balance (
  product_id bigint PRIMARY KEY REFERENCES product(product_id),
  on_hand_qty integer NOT NULL CHECK (on_hand_qty>=0),
  reserved_qty integer NOT NULL CHECK (reserved_qty>=0 AND reserved_qty<=on_hand_qty),
  row_version integer NOT NULL DEFAULT 1 CHECK (row_version>0)
);

CREATE TABLE booking (
  booking_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  resource_key text NOT NULL,
  customer_id bigint NOT NULL REFERENCES customer(customer_id),
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  status text NOT NULL CHECK (status IN ('HELD','CONFIRMED','CANCELLED','EXPIRED')),
  idempotency_key text NOT NULL UNIQUE,
  CHECK(starts_at<ends_at)
);
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE booking ADD CONSTRAINT ex_booking_no_overlap
EXCLUDE USING gist(resource_key WITH =,tstzrange(starts_at,ends_at,'[)') WITH &&)
WHERE(status IN ('HELD','CONFIRMED'));

CREATE TABLE journal_entry (
  entry_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  command_key text NOT NULL UNIQUE,
  effective_at timestamptz NOT NULL,
  description text NOT NULL
);
CREATE TABLE posting (
  entry_id bigint NOT NULL REFERENCES journal_entry(entry_id),
  posting_no integer NOT NULL,
  account_code text NOT NULL,
  side char(1) NOT NULL CHECK(side IN ('D','C')),
  amount_paise bigint NOT NULL CHECK(amount_paise>0),
  currency_code char(3) NOT NULL,
  PRIMARY KEY(entry_id,posting_no)
);

CREATE VIEW order_line_reconciliation AS
SELECT o.order_id,o.total_paise,
       COALESCE(SUM(l.quantity::bigint*l.unit_price_paise),0) AS line_total_paise,
       o.total_paise-COALESCE(SUM(l.quantity::bigint*l.unit_price_paise),0) AS difference_paise
FROM sales_order o LEFT JOIN sales_order_line l USING(order_id)
GROUP BY o.order_id,o.total_paise;

CREATE VIEW ledger_balance_check AS
SELECT entry_id,currency_code,
       SUM(CASE side WHEN 'D' THEN amount_paise ELSE -amount_paise END) AS net_paise
FROM posting GROUP BY entry_id,currency_code;
COMMIT;
