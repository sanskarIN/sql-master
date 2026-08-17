-- Illustrative least-privilege and tenant-isolation controls.
-- Review ownership and role names for the target environment.

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='atlasops_app') THEN CREATE ROLE atlasops_app NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='atlasops_report') THEN CREATE ROLE atlasops_report NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='atlasops_dispatcher') THEN CREATE ROLE atlasops_dispatcher NOLOGIN; END IF;
END $$;

REVOKE ALL ON SCHEMA core,catalog,inventory,booking,commerce,ledger,integration,audit FROM PUBLIC;
GRANT USAGE ON SCHEMA core,catalog,inventory,booking,commerce,ledger,integration TO atlasops_app;
GRANT SELECT,INSERT,UPDATE ON ALL TABLES IN SCHEMA commerce,booking TO atlasops_app;
GRANT SELECT ON ALL TABLES IN SCHEMA catalog,inventory TO atlasops_app;
GRANT EXECUTE ON FUNCTION inventory.reserve_stock(uuid,uuid,uuid,bigint,text) TO atlasops_app;
GRANT EXECUTE ON FUNCTION booking.hold_resource(uuid,uuid,text,timestamptz,timestamptz,integer,text,text) TO atlasops_app;
GRANT EXECUTE ON FUNCTION ledger.post_balanced_entry(uuid,timestamptz,text,text,text,jsonb) TO atlasops_app;

ALTER TABLE commerce.sales_order ENABLE ROW LEVEL SECURITY;
CREATE POLICY sales_order_tenant_policy ON commerce.sales_order
USING (tenant_id = nullif(current_setting('app.tenant_id',true),'')::uuid)
WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id',true),'')::uuid);

ALTER TABLE booking.reservation ENABLE ROW LEVEL SECURITY;
CREATE POLICY reservation_tenant_policy ON booking.reservation
USING (tenant_id = nullif(current_setting('app.tenant_id',true),'')::uuid)
WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id',true),'')::uuid);

-- Sensitive values should be redacted from logs and support views.
CREATE OR REPLACE VIEW core.membership_support AS
SELECT tenant_id,user_id,role_code,active,granted_at
FROM core.membership;
