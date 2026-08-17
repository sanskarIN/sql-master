-- Fleet migration and tenant-mobility control tables.
CREATE TABLE IF NOT EXISTS saas.tenant_schema_version (
  tenant_id uuid PRIMARY KEY REFERENCES saas.tenant(tenant_id),
  current_version integer NOT NULL CHECK (current_version >= 0),
  target_version integer NOT NULL CHECK (target_version >= current_version),
  state text NOT NULL CHECK (state IN ('READY','QUEUED','RUNNING','VERIFYING','FAILED','COMPLETE')),
  lease_owner text,
  lease_until timestamptz,
  last_error text,
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE IF NOT EXISTS saas.tenant_move (
  move_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES saas.tenant(tenant_id),
  source_class text NOT NULL,
  destination_class text NOT NULL,
  state text NOT NULL CHECK (state IN ('PLANNED','SNAPSHOT','COPYING','CATCHING_UP','VERIFYING','CUTOVER','COMPLETE','FAILED')),
  source_position text,
  destination_position text,
  reconciliation_json jsonb,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

-- Workers claim bounded batches with SKIP LOCKED, retain leases, and verify before marking complete.
SELECT tenant_id, current_version, target_version
FROM saas.tenant_schema_version
WHERE state = 'QUEUED'
ORDER BY updated_at, tenant_id
FOR UPDATE SKIP LOCKED
LIMIT 20;
