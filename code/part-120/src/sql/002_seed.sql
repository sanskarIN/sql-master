SET search_path=final120,public;
BEGIN;
INSERT INTO customer(email,region,created_at,status) VALUES
('a@example.test','North','2026-01-01T09:00:00Z','ACTIVE'),
('b@example.test','West','2026-01-02T09:00:00Z','ACTIVE'),
(NULL,'South','2026-01-03T09:00:00Z','ACTIVE'),
('d@example.test','North','2026-01-04T09:00:00Z','BLOCKED');
INSERT INTO product(sku,product_name,category,price_paise,currency_code) VALUES
('SQL','SQL Mastery','BOOK',24900,'INR'),('DB','Database Design','BOOK',49900,'INR'),('LAB','Query Lab','COURSE',99900,'INR'),('OPS','DBRE Lab','COURSE',149900,'INR');
INSERT INTO sales_order(customer_id,idempotency_key,request_hash,ordered_at,status,total_paise,currency_code) VALUES
(1,'o1','h1','2026-02-01T10:00:00Z','PAID',49800,'INR'),
(1,'o2','h2','2026-02-01T10:00:00Z','PAID',99900,'INR'),
(2,'o3','h3','2026-02-02T10:00:00Z','PAID',49900,'INR'),
(2,'o4','h4','2026-02-03T10:00:00Z','CANCELLED',149900,'INR');
INSERT INTO sales_order_line VALUES (1,1,1,'SQL',2,24900),(2,1,3,'LAB',1,99900),(3,1,2,'DB',1,49900),(4,1,4,'OPS',1,149900);
INSERT INTO product_event(customer_id,event_name,product_id,occurred_at,ingested_at) VALUES
(1,'signup',NULL,'2026-01-01T09:00:00Z','2026-01-01T09:00:01Z'),
(1,'view',1,'2026-01-01T10:00:00Z','2026-01-01T10:00:01Z'),
(1,'cart',1,'2026-01-01T10:02:00Z','2026-01-01T10:02:01Z'),
(1,'purchase',1,'2026-01-01T10:05:00Z','2026-01-01T10:05:01Z'),
(2,'signup',NULL,'2026-01-02T09:00:00Z','2026-01-02T09:00:01Z'),
(2,'purchase',2,'2026-01-02T09:05:00Z','2026-01-02T09:05:01Z'),
(2,'view',2,'2026-01-02T09:06:00Z','2026-01-02T09:06:01Z'),
(3,'view',1,'2026-01-10T09:00:00Z','2026-01-12T09:00:00Z');
INSERT INTO stock_balance VALUES(1,10,2,1),(2,2,2,1),(3,5,0,1),(4,1,0,1);
INSERT INTO journal_entry(command_key,effective_at,description) VALUES('sale-1','2026-02-01T10:00:00Z','Sale 1');
INSERT INTO posting VALUES(1,1,'CASH','D',49800,'INR'),(1,2,'SALES','C',49800,'INR');
COMMIT;
