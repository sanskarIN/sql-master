-- Availability, pagination, reporting, and reconciliation queries
SET search_path = booking, public;

-- Candidate count for an exclusive-resource pool.
SELECT count(*) AS available_units
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
  );

-- Stable customer history with keyset pagination.
SELECT booking_id, booking_reference, state, starts_at, ends_at,
       price_minor, currency_code
FROM bookings
WHERE tenant_id = :tenant_id
  AND customer_id = :customer_id
  AND (starts_at, booking_id) < (:cursor_starts_at, :cursor_booking_id)
ORDER BY starts_at DESC, booking_id DESC
LIMIT :page_size;

-- Occupancy by local day. Display conversion never changes stored UTC facts.
SELECT timezone(rp.timezone_name, date_trunc('day', timezone(rp.timezone_name, b.starts_at))) AS local_day,
       count(*) FILTER (WHERE b.state = 'CONFIRMED') AS confirmed_bookings,
       count(*) FILTER (WHERE b.state = 'NO_SHOW') AS no_shows,
       sum(b.price_minor) FILTER (WHERE b.state IN ('CONFIRMED','COMPLETED','NO_SHOW')) AS booked_value_minor
FROM bookings b
JOIN resource_pools rp ON rp.resource_pool_id = b.resource_pool_id
WHERE b.tenant_id = :tenant_id
  AND b.starts_at >= :from_utc AND b.starts_at < :to_utc
GROUP BY rp.timezone_name, local_day
ORDER BY local_day;

-- Reconciliation: every active booking must have an active allocation.
SELECT b.booking_id, b.state, count(a.booking_allocation_id) AS active_allocations
FROM bookings b
LEFT JOIN booking_allocations a
  ON a.tenant_id = b.tenant_id
 AND a.booking_id = b.booking_id
 AND a.state IN ('HELD','CONFIRMED')
WHERE b.tenant_id = :tenant_id
  AND b.state IN ('HELD','CONFIRMED')
GROUP BY b.booking_id, b.state
HAVING count(a.booking_allocation_id) = 0;

-- Reconciliation: allocation slot must equal the booking interval.
SELECT b.booking_id, a.booking_allocation_id, b.starts_at, b.ends_at, a.occupied_slot
FROM bookings b
JOIN booking_allocations a ON a.booking_id = b.booking_id AND a.tenant_id = b.tenant_id
WHERE b.tenant_id = :tenant_id
  AND a.occupied_slot <> tstzrange(b.starts_at, b.ends_at, '[)');

-- Waitlist claim order: priority then age, with one worker owner.
SELECT waitlist_entry_id
FROM waitlist_entries
WHERE tenant_id = :tenant_id
  AND resource_pool_id = :resource_pool_id
  AND state = 'WAITING'
  AND desired_slot && tstzrange(:starts_at, :ends_at, '[)')
ORDER BY priority_score DESC, created_at, waitlist_entry_id
FOR UPDATE SKIP LOCKED
LIMIT 1;
