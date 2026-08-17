-- Entitlement and quota enforcement patterns.

-- Hard quota claim. The predicate and increment are one statement.
INSERT INTO saas.usage_counter(tenant_id, feature_code, period_start, used_value)
VALUES (:tenant_id, :feature_code, :period_start, :delta)
ON CONFLICT (tenant_id, feature_code, period_start)
DO UPDATE SET
  used_value = saas.usage_counter.used_value + EXCLUDED.used_value,
  counter_version = saas.usage_counter.counter_version + 1,
  updated_at = clock_timestamp()
WHERE saas.usage_counter.used_value + EXCLUDED.used_value <= :limit_value
RETURNING used_value, counter_version;

-- A zero-row result means the quota claim failed. Do not query then update.

-- Effective entitlement view.
CREATE OR REPLACE VIEW saas.v_current_entitlement AS
SELECT s.tenant_id,
       pe.feature_code,
       pe.enabled,
       pe.limit_value,
       f.unit_code,
       f.enforcement_mode
FROM saas.subscription s
JOIN saas.plan_entitlement pe ON pe.plan_code = s.plan_code
JOIN saas.feature f ON f.feature_code = pe.feature_code
WHERE s.state IN ('TRIAL','ACTIVE')
  AND clock_timestamp() >= s.period_start
  AND clock_timestamp() < s.period_end;

-- Reconciliation: usage must never exceed a hard quota.
SELECT u.tenant_id, u.feature_code, u.period_start, u.used_value, e.limit_value
FROM saas.usage_counter u
JOIN saas.v_current_entitlement e
  ON e.tenant_id = u.tenant_id AND e.feature_code = u.feature_code
WHERE e.enforcement_mode = 'HARD_QUOTA'
  AND e.limit_value IS NOT NULL
  AND u.used_value > e.limit_value;
