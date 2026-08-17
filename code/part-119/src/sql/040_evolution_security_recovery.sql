-- Evolution, security, and recovery interview prompts
SET search_path = interview119, public;

-- Expand-contract migration example:
ALTER TABLE customer ADD COLUMN IF NOT EXISTS email_normalized text;
-- Deploy dual-write/backfill in bounded batches; verify; add NOT VALID constraints/indexes;
-- validate; switch reads; stop old writes; remove old path in a later release.

-- PostgreSQL row security example. Test with pooled-connection context resets.
ALTER TABLE customer ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS customer_tenant_policy ON customer;
CREATE POLICY customer_tenant_policy ON customer
USING (tenant_id = current_setting('app.tenant_id', true)::bigint)
WITH CHECK (tenant_id = current_setting('app.tenant_id', true)::bigint);

-- Least privilege sketch:
-- app_runtime: SELECT/INSERT/UPDATE only required tables and execute trusted functions.
-- migrator: DDL during controlled deployment, not application runtime.
-- auditor: read-only access to approved audit views.
-- backup_operator: backup/restore capability without ordinary application writes.

-- Recovery interview answer must include:
-- RPO/RTO, backup types, WAL/point-in-time recovery, encryption, off-site copies,
-- restore drills, dependency order, integrity checks, reconciliation, and evidence retention.

-- Security answer must include:
-- authentication, authorization, tenant scope, parameter binding, secrets, encryption,
-- logging/redaction, audit, privilege review, negative tests, and incident response.
