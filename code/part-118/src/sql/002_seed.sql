BEGIN;
SET search_path = lab, public;

INSERT INTO account(account_code, created_at, region_code, plan_code) VALUES
('ACME', '2026-01-01 00:00+00', 'IN', 'PRO'),
('NOVA', '2026-01-10 00:00+00', 'US', 'FREE');

INSERT INTO app_user(account_id, user_code, created_at, status)
SELECT a.account_id, v.user_code, v.created_at, v.status
FROM account a
JOIN (VALUES
 ('ACME','U1','2026-01-03 08:00+00'::timestamptz,'ACTIVE'),
 ('ACME','U2','2026-01-08 08:00+00'::timestamptz,'ACTIVE'),
 ('ACME','U3','2026-02-02 08:00+00'::timestamptz,'ACTIVE'),
 ('NOVA','U1','2026-01-12 08:00+00'::timestamptz,'ACTIVE')
) v(account_code,user_code,created_at,status)
ON a.account_code = v.account_code;

INSERT INTO product(sku, product_name, category_code) VALUES
('SQL-BOOK','SQL Interview Book','BOOK'),
('DB-LAB','Database Practice Lab','COURSE'),
('PLAN-PRO','Pro Plan','SUBSCRIPTION');

INSERT INTO product_price_history(product_id,valid_from,valid_to,price_paise,currency_code)
SELECT p.product_id, v.valid_from, v.valid_to, v.price_paise, v.currency_code
FROM product p
JOIN (VALUES
 ('SQL-BOOK','2026-01-01 00:00+00'::timestamptz,'2026-02-01 00:00+00'::timestamptz,19900,'INR'::char(3)),
 ('SQL-BOOK','2026-02-01 00:00+00'::timestamptz,NULL,24900,'INR'::char(3)),
 ('DB-LAB','2026-01-01 00:00+00'::timestamptz,NULL,49900,'INR'::char(3)),
 ('PLAN-PRO','2026-01-01 00:00+00'::timestamptz,NULL,99900,'INR'::char(3))
) v(sku,valid_from,valid_to,price_paise,currency_code)
ON p.sku = v.sku;

-- Ties, late arrivals, exact 30-minute boundary, repeated events, and a missing purchase.
INSERT INTO event_log(account_id,user_id,event_name,event_time,ingested_at,page_code,order_id,amount_paise,attributes)
SELECT a.account_id,u.user_id,v.event_name,v.event_time,v.ingested_at,v.page_code,v.order_id,v.amount_paise,v.attributes
FROM (VALUES
 ('ACME','U1','signup','2026-01-03 08:00+00'::timestamptz,'2026-01-03 08:00:01+00'::timestamptz,NULL,NULL,NULL,'{}'::jsonb),
 ('ACME','U1','view','2026-01-03 09:00+00','2026-01-03 09:00:02+00','home',NULL,NULL,'{}'),
 ('ACME','U1','view','2026-01-03 09:05+00','2026-01-03 09:05:02+00','pricing',NULL,NULL,'{}'),
 ('ACME','U1','add_to_cart','2026-01-03 09:06+00','2026-01-03 09:06:02+00','pricing',NULL,19900,'{}'),
 ('ACME','U1','purchase','2026-01-03 09:08+00','2026-01-03 09:08:04+00',NULL,101,19900,'{}'),
 ('ACME','U1','view','2026-01-03 09:38+00','2026-01-03 09:38:02+00','help',NULL,NULL,'{}'),
 ('ACME','U1','view','2026-01-03 10:20+00','2026-01-03 10:20:02+00','home',NULL,NULL,'{}'),
 ('ACME','U2','signup','2026-01-08 08:00+00','2026-01-08 08:00:01+00',NULL,NULL,NULL,'{}'),
 ('ACME','U2','view','2026-01-08 08:10+00','2026-01-08 08:10:01+00','home',NULL,NULL,'{}'),
 ('ACME','U2','add_to_cart','2026-01-08 08:12+00','2026-01-08 08:12:01+00','home',NULL,49900,'{}'),
 ('ACME','U2','view','2026-01-15 08:10+00','2026-01-18 08:10:00+00','home',NULL,NULL,'{"late":true}'),
 ('ACME','U3','signup','2026-02-02 08:00+00','2026-02-02 08:00:01+00',NULL,NULL,NULL,'{}'),
 ('ACME','U3','view','2026-02-02 08:10+00','2026-02-02 08:10:01+00','home',NULL,NULL,'{}'),
 ('ACME','U3','add_to_cart','2026-02-02 08:11+00','2026-02-02 08:11:01+00','home',NULL,24900,'{}'),
 ('ACME','U3','purchase','2026-02-02 08:12+00','2026-02-02 08:12:01+00',NULL,103,24900,'{}'),
 ('NOVA','U1','signup','2026-01-12 08:00+00','2026-01-12 08:00:01+00',NULL,NULL,NULL,'{}'),
 ('NOVA','U1','view','2026-01-12 08:02+00','2026-01-12 08:02:01+00','home',NULL,NULL,'{}')
) v(account_code,user_code,event_name,event_time,ingested_at,page_code,order_id,amount_paise,attributes)
JOIN account a ON a.account_code=v.account_code
JOIN app_user u ON u.account_id=a.account_id AND u.user_code=v.user_code;

INSERT INTO sales_order(account_id,user_id,ordered_at,status,total_paise,currency_code,idempotency_key,request_hash)
SELECT a.account_id,u.user_id,v.ordered_at,v.status,v.total_paise,v.currency_code,v.idempotency_key,v.request_hash
FROM (VALUES
 ('ACME','U1','2026-01-03 09:08+00'::timestamptz,'PAID',19900,'INR'::char(3),'ord-101','h101'),
 ('ACME','U1','2026-02-03 09:08+00','PAID',74800,'INR','ord-102','h102'),
 ('ACME','U3','2026-02-02 08:12+00','PAID',24900,'INR','ord-103','h103'),
 ('ACME','U2','2026-02-04 08:12+00','CANCELLED',49900,'INR','ord-104','h104')
) v(account_code,user_code,ordered_at,status,total_paise,currency_code,idempotency_key,request_hash)
JOIN account a ON a.account_code=v.account_code
JOIN app_user u ON u.account_id=a.account_id AND u.user_code=v.user_code;

INSERT INTO order_line(order_id,line_no,product_id,quantity,unit_price_paise)
SELECT o.order_id,v.line_no,p.product_id,v.quantity,v.unit_price_paise
FROM (VALUES
 ('ord-101',1,'SQL-BOOK',1,19900),
 ('ord-102',1,'SQL-BOOK',1,24900),
 ('ord-102',2,'DB-LAB',1,49900),
 ('ord-103',1,'SQL-BOOK',1,24900),
 ('ord-104',1,'DB-LAB',1,49900)
) v(idempotency_key,line_no,sku,quantity,unit_price_paise)
JOIN sales_order o ON o.idempotency_key=v.idempotency_key
JOIN product p ON p.sku=v.sku;

INSERT INTO employee(employee_code,employee_name,manager_id,valid_from,valid_to) VALUES
('CEO','Asha',NULL,'2026-01-01',NULL);
INSERT INTO employee(employee_code,employee_name,manager_id,valid_from,valid_to)
SELECT 'ENG','Bhav',employee_id,'2026-01-01',NULL FROM employee WHERE employee_code='CEO';
INSERT INTO employee(employee_code,employee_name,manager_id,valid_from,valid_to)
SELECT 'DATA','Charu',employee_id,'2026-01-01',NULL FROM employee WHERE employee_code='ENG';
INSERT INTO employee(employee_code,employee_name,manager_id,valid_from,valid_to)
SELECT 'APP','Dev',employee_id,'2026-01-01',NULL FROM employee WHERE employee_code='ENG';

COMMIT;
