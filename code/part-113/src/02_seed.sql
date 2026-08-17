BEGIN;
INSERT INTO control.etl_batch(pipeline_name,to_watermark,code_revision,state,source_rows)
VALUES ('commerce_daily','2026-08-05 23:59:59+00','part113-demo','STARTED',4);

INSERT INTO dw.dim_date VALUES
(20260803,'2026-08-03',2026,8,'August',2026,2,false),
(20260804,'2026-08-04',2026,8,'August',2026,2,false),
(20260805,'2026-08-05',2026,8,'August',2026,2,false);
INSERT INTO dw.dim_channel(channel_code,channel_name) VALUES ('WEB','Web'),('APP','Mobile App');
INSERT INTO dw.dim_entity(entity_code,entity_name,reporting_currency) VALUES ('IN01','India Commerce','INR');

WITH b AS (SELECT max(batch_id) batch_id FROM control.etl_batch)
INSERT INTO landing.order_line_event(source_event_id,source_position,source_schema_version,occurred_at,payload,payload_sha256,ingest_batch_id)
SELECT * FROM (VALUES
('evt-1','0001',1,'2026-08-03 10:00+00'::timestamptz,'{"source_order_line_id":1001,"source_updated_at":"2026-08-03T10:00:00Z","order_number":"ORD-100","customer_bk":"C-1","customer_name":"Aarav Stores","segment_code":"SMB","country_code":"IN","product_bk":"SKU-BOOK","product_name":"SQL Mastery Book","category_name":"Books","standard_cost_paise":12000,"channel_code":"WEB","entity_code":"IN01","quantity":2,"gross_paise":50000,"discount_paise":5000,"tax_paise":8100,"net_paise":53100,"currency_code":"INR"}'::jsonb,'sha-1'),
('evt-2','0002',1,'2026-08-04 11:30+00'::timestamptz,'{"source_order_line_id":1002,"source_updated_at":"2026-08-04T11:30:00Z","order_number":"ORD-101","customer_bk":"C-2","customer_name":"Blue Kite","segment_code":"ENTERPRISE","country_code":"IN","product_bk":"SKU-HUB","product_name":"USB-C Hub","category_name":"Accessories","standard_cost_paise":90000,"channel_code":"APP","entity_code":"IN01","quantity":1,"gross_paise":150000,"discount_paise":10000,"tax_paise":25200,"net_paise":165200,"currency_code":"INR"}'::jsonb,'sha-2'),
('evt-3','0003',1,'2026-08-05 12:15+00'::timestamptz,'{"source_order_line_id":1003,"source_updated_at":"2026-08-05T12:15:00Z","order_number":"ORD-102","customer_bk":"C-1","customer_name":"Aarav Stores","segment_code":"MIDMARKET","country_code":"IN","product_bk":"SKU-BOOK","product_name":"SQL Mastery Book","category_name":"Books","standard_cost_paise":12000,"channel_code":"WEB","entity_code":"IN01","quantity":3,"gross_paise":75000,"discount_paise":0,"tax_paise":13500,"net_paise":88500,"currency_code":"INR"}'::jsonb,'sha-3'),
('evt-4','0004',1,'2026-08-05 14:45+00'::timestamptz,'{"source_order_line_id":1004,"source_updated_at":"2026-08-05T14:45:00Z","order_number":"ORD-103","customer_bk":"C-3","customer_name":"Cedar Labs","segment_code":"SMB","country_code":"IN","product_bk":"SKU-HUB","product_name":"USB-C Hub","category_name":"Accessories","standard_cost_paise":90000,"channel_code":"APP","entity_code":"IN01","quantity":2,"gross_paise":300000,"discount_paise":15000,"tax_paise":51300,"net_paise":336300,"currency_code":"INR"}'::jsonb,'sha-4')
) v(source_event_id,source_position,source_schema_version,occurred_at,payload,payload_sha256)
CROSS JOIN b;
COMMIT;
