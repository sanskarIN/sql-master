-- Representative capstone seed data
BEGIN;

INSERT INTO core.tenant (tenant_id, tenant_code, tenant_name)
VALUES
('00000000-0000-0000-0000-000000000001','northwind-demo','Northwind Demo'),
('00000000-0000-0000-0000-000000000002','contoso-demo','Contoso Demo');

INSERT INTO core.app_user (user_id, email, display_name)
VALUES ('10000000-0000-0000-0000-000000000001','admin@example.test','Demo Admin');

INSERT INTO core.membership (tenant_id,user_id,role_code)
VALUES ('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','ADMIN');

INSERT INTO catalog.product (tenant_id,product_id,sku,product_name)
VALUES
('00000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','SQL-BOOK','SQL Mastery Book'),
('00000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','DB-COURSE','Database Course');

INSERT INTO catalog.product_price (tenant_id,product_id,valid_from,unit_price_paise,currency_code)
VALUES
('00000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','2026-08-01T00:00:00Z',24900,'INR'),
('00000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','2026-08-01T00:00:00Z',99900,'INR');

INSERT INTO inventory.warehouse (tenant_id,warehouse_id,warehouse_code,warehouse_name)
VALUES ('00000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','DEL-01','Delhi Warehouse');

INSERT INTO inventory.stock_balance (tenant_id,product_id,warehouse_id,on_hand_qty,reserved_qty)
VALUES
('00000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',100,0),
('00000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000001',20,0);

INSERT INTO booking.resource (tenant_id,resource_id,resource_code,resource_name,time_zone)
VALUES ('00000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','CONSULT-01','Database Consultation Room','Asia/Kolkata');

INSERT INTO ledger.account (tenant_id,account_id,account_code,account_name,currency_code)
VALUES
('00000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','CASH','Cash','INR'),
('00000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000002','SALES','Sales Revenue','INR');

COMMIT;
