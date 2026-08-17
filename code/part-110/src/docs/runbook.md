# Production Runbook

## Primary signals
- API and repository latency by query fingerprint and result size.
- Pool wait, active sessions, lock waits, deadlocks, cancellations, and statement timeouts.
- Feed fan-out queue depth, oldest unpublished outbox event, rows generated per event, and retry rate.
- Home-feed empty/error rate, duplicate rate, cursor failures, and visibility-filter rejection rate.
- Moderation queue age, notification delay, counter drift, search latency, and index growth.

## Incident: feed delay
1. Confirm the oldest unpublished outbox event and worker lease health.
2. Separate database saturation, worker failure, poison payload, and downstream outage.
3. Pause unsafe retries; preserve event identity and attempt history.
4. Scale only within the database session and write budget.
5. Backfill bounded author/time ranges and verify no duplicate `(owner_user_id, post_id)` rows.

## Incident: privacy leak suspicion
1. Disable the affected read path or feature flag immediately.
2. Preserve request, actor, viewer, post, policy version, SQL fingerprint, and audit evidence.
3. Test blocks, current follows, post state, custom audience, suspension, and cache invalidation.
4. Remove stale feed/search/cache rows, but fix the authoritative policy first.
5. Notify the security/privacy owner and follow the approved incident process.

## Counter drift
Recompute bounded post ranges from `reactions` and visible `comments`; compare before updating. Track recurrence by writer version and event source.

## Release evidence
Retain migration revision, compatibility window, query plans, representative volumes, concurrency tests, rollback/forward-fix plan, backup/restore proof, owners, and review date.

---
Official store: **https://ramsandesh.gumroad.com**
