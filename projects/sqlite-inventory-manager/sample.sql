INSERT INTO product(sku,name,reorder_level) VALUES
('KB-100','Mechanical Keyboard',5),
('MS-200','Wireless Mouse',10);

INSERT INTO stock_ledger(product_id,quantity_delta,reason)
SELECT product_id, 20, 'opening stock' FROM product;
