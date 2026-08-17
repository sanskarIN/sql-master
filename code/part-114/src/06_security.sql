-- Illustrative least-privilege roles. Adapt names to the deployment.
DO $$ BEGIN
  CREATE ROLE saas_runtime NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE ROLE saas_billing_worker NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE ROLE saas_migration_worker NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE ROLE saas_auditor NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

REVOKE ALL ON SCHEMA saas FROM PUBLIC;
GRANT USAGE ON SCHEMA saas TO saas_runtime, saas_billing_worker, saas_migration_worker, saas_auditor;
GRANT SELECT, INSERT, UPDATE ON saas.workspace_item, saas.usage_counter, saas.idempotency_command, saas.outbox_event TO saas_runtime;
GRANT SELECT, INSERT, UPDATE ON saas.invoice, saas.subscription, saas.usage_counter TO saas_billing_worker;
GRANT SELECT, INSERT, UPDATE ON saas.tenant_schema_version, saas.tenant_move TO saas_migration_worker;
GRANT SELECT ON saas.audit_event, saas.tenant, saas.membership TO saas_auditor;

-- Never grant runtime roles BYPASSRLS. Administrative access should be separately authenticated,
-- approved, time-bounded, logged, and reconciled.
