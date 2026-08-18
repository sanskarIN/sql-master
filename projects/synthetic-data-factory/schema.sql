CREATE TABLE synthetic_customer (
    customer_id BIGINT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    city TEXT NOT NULL,
    lifetime_value_paise BIGINT NOT NULL CHECK (lifetime_value_paise >= 0)
);
