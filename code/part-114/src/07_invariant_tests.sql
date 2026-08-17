-- Zero-row invariant checks. Every query should return zero rows.

-- Active memberships must reference active tenants.
SELECT m.tenant_id, m.user_id
FROM saas.membership m
JOIN saas.tenant t ON t.tenant_id = m.tenant_id
WHERE m.state = 'ACTIVE' AND t.state <> 'ACTIVE';

-- Exactly one current subscription period should contain an instant per tenant.
SELECT a.tenant_id, a.subscription_id, b.subscription_id
FROM saas.subscription a
JOIN saas.subscription b
  ON b.tenant_id = a.tenant_id AND b.subscription_id > a.subscription_id
 AND tstzrange(a.period_start,a.period_end,'[)') && tstzrange(b.period_start,b.period_end,'[)')
WHERE a.state IN ('TRIAL','ACTIVE') AND b.state IN ('TRIAL','ACTIVE');

-- Successful idempotency records must retain a response.
SELECT tenant_id, command_name, idempotency_key
FROM saas.idempotency_command
WHERE state = 'SUCCEEDED' AND response_json IS NULL;

-- Published outbox rows must have a delivery timestamp.
SELECT tenant_id, event_id FROM saas.outbox_event
WHERE published_at IS NOT NULL AND attempt_count < 0;

-- Deleted tenants must not remain active in the routing catalog.
SELECT tenant_id FROM saas.tenant
WHERE state = 'DELETED' AND closed_at IS NULL;
