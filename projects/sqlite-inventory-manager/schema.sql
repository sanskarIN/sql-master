PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS product (
    product_id INTEGER PRIMARY KEY,
    sku TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    reorder_level INTEGER NOT NULL DEFAULT 0 CHECK (reorder_level >= 0)
);

CREATE TABLE IF NOT EXISTS stock_ledger (
    ledger_id INTEGER PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES product(product_id),
    quantity_delta INTEGER NOT NULL CHECK (quantity_delta <> 0),
    reason TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE VIEW IF NOT EXISTS current_stock AS
SELECT p.product_id, p.sku, p.name, p.reorder_level,
       COALESCE(SUM(l.quantity_delta), 0) AS quantity
FROM product p
LEFT JOIN stock_ledger l ON l.product_id = p.product_id
GROUP BY p.product_id, p.sku, p.name, p.reorder_level;
