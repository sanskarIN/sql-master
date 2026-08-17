# Production Runbook

## Stale dashboard
1. Read `control.certified_snapshot` and identify the last certified batch.
2. Determine whether lag is at source, landing, transformation, validation, publication, cache, or client.
3. Keep the previous certified snapshot visible and display a stale-data warning.
4. Do not manually advance a watermark.

## Quality failure
1. Keep the batch in `FAILED` or `VALIDATED`-blocked state.
2. Capture failing rows and the smallest affected scope.
3. Classify source defect, mapping defect, late data, duplication, omission, or threshold issue.
4. Repair with a new batch or superseding run; never erase the failed evidence.

## Backfill
1. Create a separate run identity and bounded event-time range.
2. Load into isolated partitions/tables.
3. Compare row counts, checksums, totals, SCD intervals, and dashboard metrics.
4. Certify and atomically publish only after approval.

## Restore test
1. Restore source-independent warehouse backup into an isolated environment.
2. Rebuild semantic views and aggregates.
3. Reconcile certified totals and security grants.
4. Record duration, data-loss boundary, owner, defects, and next test date.
