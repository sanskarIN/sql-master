-- Provisioning, tenant context, idempotency, and outbox patterns.

-- Application transaction boundary:
BEGIN;
SET LOCAL app.tenant_id = '00000000-0000-0000-0000-000000000101';
SELECT item_id, item_name, created_at
FROM saas.workspace_item
ORDER BY created_at DESC, item_id DESC
LIMIT 50;
COMMIT;

-- A production provisioning service should:
-- 1. claim (tenant_id, command_name, idempotency_key),
-- 2. compare request_hash on replay,
-- 3. create tenant + owner membership + subscription in one transaction,
-- 4. write outbox events in the same transaction,
-- 5. return the stored authoritative response.

INSERT INTO saas.idempotency_command
  (tenant_id, command_name, idempotency_key, request_hash, state)
VALUES
  (:tenant_id, 'PROVISION_TENANT', :idempotency_key, :request_hash, 'STARTED')
ON CONFLICT (tenant_id, command_name, idempotency_key) DO NOTHING;

-- Conflict detection must happen before performing side effects.
SELECT request_hash, state, response_json
FROM saas.idempotency_command
WHERE tenant_id = :tenant_id
  AND command_name = 'PROVISION_TENANT'
  AND idempotency_key = :idempotency_key
FOR UPDATE;

INSERT INTO saas.outbox_event
  (tenant_id, aggregate_type, aggregate_id, event_type, payload)
VALUES
  (:tenant_id, 'TENANT', :tenant_id::text, 'TENANT_ACTIVATED',
   jsonb_build_object('tenant_id', :tenant_id, 'region', :home_region));
