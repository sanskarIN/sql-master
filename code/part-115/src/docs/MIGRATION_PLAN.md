# Expand-Contract Migration Plan

1. Preflight counts, nulls, duplicates, index size, lock risk, replica lag, and disk headroom.
2. Add compatible nullable columns or new relation.
3. Deploy compatible writers; dual-write only when the transition requires it.
4. Backfill deterministic batches with checkpoints and bounded transactions.
5. Reconcile old and new representations continuously.
6. Switch readers and observe latency, plans, errors, and drift.
7. Validate constraints and make the new representation authoritative.
8. Remove old structures after the compatibility and rollback windows expire.

Every migration record includes revision, owner, expected locks, statement/lock timeout, progress query, cancellation path, validation query, rollback or forward-fix, and evidence links.
