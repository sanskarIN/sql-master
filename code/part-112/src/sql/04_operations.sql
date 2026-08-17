-- Operational checks and worker patterns
SET search_path = booking, public;

-- Outbox claim.
WITH claimed AS (
    SELECT outbox_event_id
    FROM outbox_events
    WHERE published_at IS NULL
      AND next_attempt_at <= CURRENT_TIMESTAMP
    ORDER BY next_attempt_at, outbox_event_id
    FOR UPDATE SKIP LOCKED
    LIMIT :batch_size
)
SELECT o.*
FROM outbox_events o
JOIN claimed c USING (outbox_event_id)
ORDER BY o.outbox_event_id;

-- Long-lived holds.
SELECT tenant_id, resource_pool_id,
       count(*) AS expired_hold_rows,
       min(hold_expires_at) AS oldest_expired_hold
FROM bookings
WHERE state = 'HELD' AND hold_expires_at <= CURRENT_TIMESTAMP
GROUP BY tenant_id, resource_pool_id;

-- Orphaned or contradictory states.
SELECT b.booking_id, b.state AS booking_state, a.state AS allocation_state
FROM bookings b
JOIN booking_allocations a ON a.booking_id = b.booking_id AND a.tenant_id = b.tenant_id
WHERE (b.state = 'CONFIRMED' AND a.state <> 'CONFIRMED')
   OR (b.state IN ('CANCELLED','EXPIRED') AND a.state IN ('HELD','CONFIRMED'));

-- Payment/booking mismatch.
SELECT b.booking_id, b.state, max(p.state) AS latest_payment_state
FROM bookings b
LEFT JOIN payment_attempts p ON p.booking_id = b.booking_id AND p.tenant_id = b.tenant_id
WHERE b.tenant_id = :tenant_id
GROUP BY b.booking_id, b.state
HAVING (b.state = 'CONFIRMED' AND bool_or(p.state IN ('CAPTURED','AUTHORIZED')) IS NOT TRUE)
    OR (b.state = 'CANCELLED' AND bool_or(p.state = 'CAPTURED') IS TRUE);

-- Lock/plan evidence targets.
EXPLAIN (ANALYZE, BUFFERS, WAL, SETTINGS)
SELECT r.resource_id
FROM resources r
WHERE r.tenant_id = :tenant_id
  AND r.resource_pool_id = :resource_pool_id
  AND r.state = 'ACTIVE'
  AND NOT EXISTS (
      SELECT 1 FROM booking_allocations a
      WHERE a.tenant_id = r.tenant_id
        AND a.resource_id = r.resource_id
        AND a.state IN ('HELD','CONFIRMED')
        AND a.occupied_slot && tstzrange(:starts_at, :ends_at, '[)')
  )
ORDER BY r.resource_id
LIMIT 1;
