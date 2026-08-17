-- Transaction-safe booking commands
SET search_path = booking, public;

-- Release expired holds before searching. Workers use SKIP LOCKED so only one owns a row.
WITH expired AS (
    SELECT booking_id
    FROM bookings
    WHERE tenant_id = :tenant_id
      AND state = 'HELD'
      AND hold_expires_at <= CURRENT_TIMESTAMP
    ORDER BY hold_expires_at, booking_id
    FOR UPDATE SKIP LOCKED
    LIMIT :batch_size
), updated AS (
    UPDATE bookings b
       SET state = 'EXPIRED', version_no = version_no + 1
      FROM expired e
     WHERE b.booking_id = e.booking_id
     RETURNING b.booking_id, b.tenant_id
)
UPDATE booking_allocations a
   SET state = 'EXPIRED', released_at = CURRENT_TIMESTAMP
  FROM updated u
 WHERE a.booking_id = u.booking_id
   AND a.state = 'HELD';

-- Idempotency ownership. A conflicting hash must return 409 rather than replaying another request.
INSERT INTO booking_commands
       (tenant_id, idempotency_key, command_type, request_hash)
VALUES (:tenant_id, :idempotency_key, 'CREATE_HOLD', :request_hash)
ON CONFLICT (tenant_id, idempotency_key) DO NOTHING;

SELECT booking_command_id, request_hash, status_code, result_json
FROM booking_commands
WHERE tenant_id = :tenant_id AND idempotency_key = :idempotency_key
FOR UPDATE;

-- Deterministic candidate allocation. Keep this in the same transaction as booking/allocation inserts.
SELECT r.resource_id
FROM resources r
WHERE r.tenant_id = :tenant_id
  AND r.resource_pool_id = :resource_pool_id
  AND r.state = 'ACTIVE'
  AND NOT EXISTS (
      SELECT 1 FROM blackout_periods bp
      WHERE bp.tenant_id = r.tenant_id
        AND bp.resource_id = r.resource_id
        AND bp.blocked_slot && tstzrange(:starts_at, :ends_at, '[)')
  )
  AND NOT EXISTS (
      SELECT 1 FROM booking_allocations a
      WHERE a.tenant_id = r.tenant_id
        AND a.resource_id = r.resource_id
        AND a.state IN ('HELD','CONFIRMED')
        AND a.occupied_slot && tstzrange(:starts_at, :ends_at, '[)')
  )
ORDER BY r.resource_id
FOR UPDATE OF r SKIP LOCKED
LIMIT 1;

-- Create booking and allocation. The exclusion constraint remains the final race-proof guard.
INSERT INTO bookings
       (tenant_id, booking_reference, customer_id, resource_pool_id, state,
        starts_at, ends_at, display_timezone, hold_expires_at, party_size,
        price_minor, currency_code, policy_version, booking_command_id)
VALUES (:tenant_id, :booking_reference, :customer_id, :resource_pool_id, 'HELD',
        :starts_at, :ends_at, :display_timezone,
        CURRENT_TIMESTAMP + make_interval(mins => :hold_minutes), :party_size,
        :price_minor, :currency_code, :policy_version, :booking_command_id)
RETURNING booking_id;

INSERT INTO booking_allocations
       (tenant_id, booking_id, resource_id, occupied_slot, state)
VALUES (:tenant_id, :booking_id, :resource_id,
        tstzrange(:starts_at, :ends_at, '[)'), 'HELD');

INSERT INTO booking_events (tenant_id, booking_id, event_kind, event_data)
VALUES (:tenant_id, :booking_id, 'HELD', jsonb_build_object('resource_id', :resource_id));

INSERT INTO outbox_events
       (tenant_id, aggregate_type, aggregate_id, event_type, payload_json)
VALUES (:tenant_id, 'BOOKING', :booking_id, 'booking.held', :event_payload);

UPDATE booking_commands
   SET status_code = 201,
       result_json = jsonb_build_object('booking_id', :booking_id, 'reference', :booking_reference),
       completed_at = CURRENT_TIMESTAMP
 WHERE booking_command_id = :booking_command_id;

-- Confirm only a live hold and lock the booking first.
SELECT booking_id, state, hold_expires_at, version_no
FROM bookings
WHERE tenant_id = :tenant_id AND booking_id = :booking_id
FOR UPDATE;

UPDATE bookings
   SET state = 'CONFIRMED', confirmed_at = CURRENT_TIMESTAMP,
       hold_expires_at = NULL, version_no = version_no + 1
 WHERE tenant_id = :tenant_id
   AND booking_id = :booking_id
   AND state = 'HELD'
   AND hold_expires_at > CURRENT_TIMESTAMP
   AND version_no = :expected_version;

UPDATE booking_allocations
   SET state = 'CONFIRMED'
 WHERE tenant_id = :tenant_id AND booking_id = :booking_id AND state = 'HELD';

-- Cancel by state transition; never delete the booking history.
UPDATE bookings
   SET state = 'CANCELLED', cancelled_at = CURRENT_TIMESTAMP,
       version_no = version_no + 1
 WHERE tenant_id = :tenant_id
   AND booking_id = :booking_id
   AND state IN ('HELD','CONFIRMED')
   AND version_no = :expected_version;

UPDATE booking_allocations
   SET state = 'CANCELLED', released_at = CURRENT_TIMESTAMP
 WHERE tenant_id = :tenant_id
   AND booking_id = :booking_id
   AND state IN ('HELD','CONFIRMED');
