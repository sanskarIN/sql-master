# Production Runbook

## Inventory reservation failures
Check tenant/product/warehouse identity, available quantity, lock wait, duplicate command key, and conflicting request hash. Do not bypass the invariant with a direct balance update.

## Booking conflict spike
Confirm genuine demand versus stale HELD rows. Run expiry worker, inspect exclusion violations and lock duration, and verify resource/time-zone input.

## Outbox backlog
Measure oldest event age, attempts, dispatcher health, poison events, and downstream availability. Claim with SKIP LOCKED; never delete undelivered intent to hide backlog.

## Slow query regression
Compare fingerprint, plan, actual rows, buffers, statistics, index use, lock/pool wait, and release revision. Roll back the query path or feature before attempting speculative tuning.

## Ambiguous command outcome
Reuse the original idempotency key and request hash. Read the authoritative stored result. Never create a new key until the original outcome is classified.

## Restore drill
Restore into isolated infrastructure, replace secrets and callbacks, apply WAL to target, validate maximum commit time, run constraints and reconciliation, execute critical smoke flows, record RPO/RTO, and retain the transcript.
