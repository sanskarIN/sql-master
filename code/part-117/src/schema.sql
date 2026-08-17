-- SQL Full Mastery Part 117 - Intermediate Query Challenges
-- Primary dialect: PostgreSQL 15+
BEGIN;
DROP SCHEMA IF EXISTS iq117 CASCADE;
CREATE SCHEMA iq117;
SET search_path = iq117, public;

CREATE TABLE customers (
  customer_id bigint PRIMARY KEY,
  customer_name text NOT NULL,
  email text,
  region text NOT NULL,
  created_at timestamptz NOT NULL
);
CREATE TABLE departments (
  department_id bigint PRIMARY KEY,
  department_name text NOT NULL UNIQUE
);
CREATE TABLE employees (
  employee_id bigint PRIMARY KEY,
  employee_name text NOT NULL,
  department_id bigint NOT NULL REFERENCES departments,
  manager_id bigint REFERENCES employees,
  salary_paise bigint NOT NULL CHECK (salary_paise >= 0),
  active boolean NOT NULL DEFAULT true
);
CREATE TABLE products (
  product_id bigint PRIMARY KEY,
  sku text NOT NULL UNIQUE,
  product_name text NOT NULL,
  category text NOT NULL,
  unit_price_paise bigint NOT NULL CHECK (unit_price_paise >= 0),
  unit_cost_paise bigint NOT NULL CHECK (unit_cost_paise >= 0)
);
CREATE TABLE orders (
  order_id bigint PRIMARY KEY,
  order_number bigint NOT NULL UNIQUE,
  customer_id bigint NOT NULL REFERENCES customers,
  employee_id bigint REFERENCES employees,
  ordered_at timestamptz NOT NULL,
  status text NOT NULL CHECK (status IN ('pending','completed','cancelled','refunded')),
  stored_total_paise bigint NOT NULL CHECK (stored_total_paise >= 0),
  refund_paise bigint NOT NULL DEFAULT 0 CHECK (refund_paise >= 0)
);
CREATE TABLE order_items (
  order_id bigint NOT NULL REFERENCES orders ON DELETE CASCADE,
  line_no integer NOT NULL CHECK (line_no > 0),
  product_id bigint NOT NULL REFERENCES products,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price_paise bigint NOT NULL CHECK (unit_price_paise >= 0),
  PRIMARY KEY (order_id, line_no)
);
CREATE TABLE payments (
  payment_id bigint PRIMARY KEY,
  order_id bigint NOT NULL REFERENCES orders,
  amount_paise bigint NOT NULL CHECK (amount_paise >= 0),
  payment_status text NOT NULL CHECK (payment_status IN ('authorized','captured','failed','refunded')),
  paid_at timestamptz NOT NULL
);
CREATE TABLE login_events (
  user_id bigint NOT NULL,
  login_at timestamptz NOT NULL,
  PRIMARY KEY (user_id, login_at)
);
CREATE TABLE subscriptions (
  subscription_id bigint PRIMARY KEY,
  customer_id bigint NOT NULL REFERENCES customers,
  plan_code text NOT NULL,
  starts_on date NOT NULL,
  ends_on date,
  status text NOT NULL CHECK (status IN ('active','paused','cancelled')),
  CHECK (ends_on IS NULL OR ends_on >= starts_on)
);
CREATE TABLE required_products (product_id bigint PRIMARY KEY REFERENCES products);
CREATE TABLE bundle_products (bundle_code text NOT NULL, product_id bigint NOT NULL REFERENCES products, PRIMARY KEY(bundle_code, product_id));
CREATE TABLE staging_orders (staging_id bigint PRIMARY KEY, customer_id bigint, source_ref text NOT NULL);
CREATE TABLE stock_movements (
  movement_id bigint PRIMARY KEY,
  product_id bigint NOT NULL REFERENCES products,
  location_code text NOT NULL,
  moved_at timestamptz NOT NULL,
  quantity_delta integer NOT NULL CHECK (quantity_delta <> 0)
);

CREATE INDEX ix_orders_customer_time ON orders(customer_id, ordered_at DESC, order_id DESC);
CREATE INDEX ix_orders_time ON orders(ordered_at DESC, order_id DESC);
CREATE INDEX ix_order_items_product_order ON order_items(product_id, order_id);
CREATE INDEX ix_login_user_time ON login_events(user_id, login_at);
CREATE INDEX ix_subscription_customer_plan_period ON subscriptions(customer_id, plan_code, starts_on, ends_on);
COMMIT;
