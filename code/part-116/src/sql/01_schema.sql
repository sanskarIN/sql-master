-- SQL Full Mastery - Part 116
-- Beginner Interview Lab (PostgreSQL-oriented)
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR(80) NOT NULL,
    city VARCHAR(40),
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    sku VARCHAR(30) NOT NULL UNIQUE,
    product_name VARCHAR(100) NOT NULL,
    price_paise BIGINT NOT NULL CHECK (price_paise >= 0)
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending','paid','cancelled')),
    total_paise BIGINT NOT NULL CHECK (total_paise >= 0)
);

CREATE TABLE order_items (
    order_id INTEGER NOT NULL REFERENCES orders(order_id),
    line_no INTEGER NOT NULL CHECK (line_no > 0),
    product_id INTEGER NOT NULL REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_paise BIGINT NOT NULL CHECK (unit_price_paise >= 0),
    PRIMARY KEY (order_id, line_no),
    UNIQUE (order_id, product_id)
);

CREATE INDEX ix_orders_customer_date
    ON orders (customer_id, order_date DESC, order_id DESC);
