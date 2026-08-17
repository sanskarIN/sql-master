-- Small deterministic demonstration dataset
SET search_path = booking, public;

INSERT INTO tenants (tenant_code, tenant_name, default_timezone)
VALUES ('DEMO','Sanskar Booking Demo','Asia/Kolkata');

INSERT INTO customers (tenant_id, external_key, display_name, email_normalized)
SELECT tenant_id, 'CUS-001', 'Aarav Sharma', 'aarav@example.test' FROM tenants WHERE tenant_code='DEMO';

INSERT INTO resource_pools
       (tenant_id, pool_code, pool_name, timezone_name, default_duration_minutes, hold_minutes)
SELECT tenant_id, 'CONSULT', 'Consultation Rooms', 'Asia/Kolkata', 30, 10
FROM tenants WHERE tenant_code='DEMO';

INSERT INTO resources (tenant_id, resource_pool_id, resource_code, resource_name)
SELECT t.tenant_id, rp.resource_pool_id, x.code, x.name
FROM tenants t
JOIN resource_pools rp ON rp.tenant_id=t.tenant_id AND rp.pool_code='CONSULT'
CROSS JOIN (VALUES ('ROOM-1','Consultation Room 1'),('ROOM-2','Consultation Room 2')) x(code,name)
WHERE t.tenant_code='DEMO';

INSERT INTO weekly_availability
       (tenant_id, resource_id, iso_weekday, local_start, local_end, valid_from)
SELECT r.tenant_id, r.resource_id, d.day_no, TIME '09:00', TIME '18:00', DATE '2026-08-01'
FROM resources r CROSS JOIN generate_series(1,6) AS d(day_no);
