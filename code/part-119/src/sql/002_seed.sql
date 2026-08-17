-- Adversarial seed data for Part 119
BEGIN;
SET search_path = interview119, public;
INSERT INTO tenant (tenant_code,status) VALUES ('ALPHA','ACTIVE'),('BETA','ACTIVE');
INSERT INTO customer (tenant_id,email,display_name,status,created_at)
VALUES
(1,'a@example.test','Asha','ACTIVE','2026-08-01T09:00:00Z'),
(1,'b@example.test','Bharat','ACTIVE','2026-08-01T09:00:00Z'),
(1,NULL,'Guest 1','ACTIVE','2026-08-01T09:00:00Z'),
(2,'a@example.test','Tenant Two Asha','ACTIVE','2026-08-01T09:00:00Z');
INSERT INTO product (tenant_id,sku,name,status,price_paise,currency_code)
VALUES
(1,'SKU-1','Keyboard','ACTIVE',249900,'INR'),
(1,'SKU-2','Mouse','ACTIVE',99900,'INR'),
(1,'SKU-3','Cable','DISCONTINUED',19900,'INR'),
(2,'SKU-1','Tenant Two Keyboard','ACTIVE',259900,'INR');
INSERT INTO warehouse (tenant_id,warehouse_code,time_zone_name)
VALUES (1,'DEL','Asia/Kolkata'),(1,'BLR','Asia/Kolkata'),(2,'DEL','Asia/Kolkata');
INSERT INTO stock_balance VALUES
(1,1,1,10,3,1),(1,1,2,0,0,1),(1,2,1,7,0,1),(2,3,4,50,0,1);
INSERT INTO sales_order (tenant_id,customer_id,idempotency_key,request_hash,status,ordered_at,total_paise,currency_code)
VALUES
(1,1,'ord-001','hash-a','CONFIRMED','2026-08-02T10:00:00Z',349800,'INR'),
(1,1,'ord-002','hash-b','CONFIRMED','2026-08-02T10:00:00Z',99900,'INR'),
(1,2,'ord-003','hash-c','CANCELLED','2026-08-03T11:00:00Z',249900,'INR');
INSERT INTO sales_order_line VALUES
(1,1,1,1,'SKU-1','Keyboard',1,249900),
(1,1,2,2,'SKU-2','Mouse',1,99900),
(1,2,1,2,'SKU-2','Mouse',1,99900),
(1,3,1,1,'SKU-1','Keyboard',1,249900);
INSERT INTO account (tenant_id,account_code,account_type,currency_code)
VALUES (1,'CASH','ASSET','INR'),(1,'SALES','REVENUE','INR'),(1,'REFUNDS','EXPENSE','INR');
INSERT INTO journal_entry (tenant_id,command_key,request_hash,effective_at,description)
VALUES (1,'pay-001','phash-a','2026-08-02T10:01:00Z','Capture order 1');
INSERT INTO posting VALUES (1,1,1,1,'D',349800,'INR'),(1,1,2,2,'C',349800,'INR');
INSERT INTO job_queue (tenant_id,job_type,payload,state,available_at)
VALUES
(1,'EMAIL','{"order_id":1}','READY','2026-08-06T00:00:00Z'),
(1,'EMAIL','{"order_id":2}','READY','2026-08-06T00:00:00Z'),
(1,'EXPORT','{"tenant_id":1}','FAILED','2026-08-05T00:00:00Z');
COMMIT;
