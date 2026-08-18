CREATE TABLE customer(
  customer_id INTEGER PRIMARY KEY,
  name TEXT NOT NULL
);
CREATE TABLE orders(
  order_id INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customer(customer_id),
  ordered_at TEXT NOT NULL,
  total_paise INTEGER NOT NULL CHECK(total_paise >= 0)
);
CREATE INDEX ix_orders_customer_time ON orders(customer_id, ordered_at DESC, order_id DESC);
