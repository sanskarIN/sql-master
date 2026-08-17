# Booking System Production Runbook

## Primary signals

- expired holds still in `HELD` state;
- exclusion-constraint conflicts and availability retry rate;
- lock wait and deadlock rate by command;
- active booking without active allocation;
- allocation interval different from booking interval;
- confirmed booking without required payment evidence;
- cancellation requiring refund but lacking refund evidence;
- waitlist offer age and promotion failure rate;
- outbox lag and repeated delivery failures;
- booking/search/calendar projection drift.

## Incident: availability says free but hold fails

1. Preserve tenant, pool, requested interval, query fingerprint, and trace ID.
2. Check concurrent allocations and blackouts using the exact `[start,end)` range.
3. Confirm the exclusion violation is handled as a normal conflict, not a server error.
4. Inspect resource lock order and query plan.
5. Retry only with the original idempotency key and bounded policy.
6. Reconcile the stored command result before reporting failure.

## Incident: expired holds block capacity

1. Measure oldest expired hold and worker lag.
2. Check worker leases, transaction duration, and `SKIP LOCKED` claim rate.
3. Run a bounded expiry batch; do not issue one unbounded update.
4. Reconcile booking and allocation states.
5. Verify alerts clear and document the failed dependency.

## Incident: payment outcome is uncertain

1. Do not create a second payment attempt with a new identity.
2. Query the provider by the original provider reference/request key.
3. Reconcile provider fact, payment row, booking state, and outbox events.
4. Confirm or cancel only through the normal command path.
5. Retain evidence and customer-visible resolution.

## Recovery and migration

- Restore backups into an isolated environment regularly.
- Rebuild read models and compare booking/allocation/payment counts and hashes.
- Test every supported upgrade path with held and confirmed bookings in flight.
- Use expand-contract changes and retain rollback/forward-fix criteria.
