-- Demonstration seed data
SET search_path = inventory, public;

INSERT INTO products(sku,normalized_sku,product_name,base_uom,tracking_mode,state) VALUES
('SQL-BOOK-01','sql-book-01','SQL Mastery Workbook','EA','NONE','ACTIVE'),
('SSD-1TB','ssd-1tb','1 TB NVMe SSD','EA','SERIAL','ACTIVE'),
('VACCINE-A','vaccine-a','Temperature Controlled Vaccine A','VIAL','LOT','ACTIVE');

INSERT INTO warehouses(warehouse_code,warehouse_name,timezone_name) VALUES
('DEL-01','Delhi Distribution Centre','Asia/Kolkata'),
('BLR-01','Bengaluru Fulfilment Centre','Asia/Kolkata');

INSERT INTO bins(warehouse_id,bin_code,kind,is_pickable) SELECT warehouse_id,'REC-01','RECEIVING',FALSE FROM warehouses;
INSERT INTO bins(warehouse_id,bin_code,kind,is_pickable) SELECT warehouse_id,'PICK-A01','PICK',TRUE FROM warehouses;
INSERT INTO bins(warehouse_id,bin_code,kind,is_pickable) SELECT warehouse_id,'QUAR-01','QUARANTINE',FALSE FROM warehouses;

INSERT INTO suppliers(supplier_code,supplier_name,default_currency,lead_time_days) VALUES
('SUP-BOOKS','Knowledge Press','INR',7),('SUP-TECH','Reliable Components','INR',14);

INSERT INTO product_suppliers(product_id,supplier_id,min_order_qty,order_multiple,unit_cost_minor,preferred_rank)
SELECT p.product_id,s.supplier_id,10,5,24900,1 FROM products p,suppliers s
WHERE p.sku='SQL-BOOK-01' AND s.supplier_code='SUP-BOOKS';

INSERT INTO reorder_policies(warehouse_id,product_id,reorder_point_qty,target_stock_qty,safety_stock_qty,lead_time_days,policy_version)
SELECT w.warehouse_id,p.product_id,20,80,10,7,'POLICY-2026-08'
FROM warehouses w,products p WHERE w.warehouse_code='DEL-01' AND p.sku='SQL-BOOK-01';
