# Test Plan

## Required suites
- DDL: keys, checks, tenant-scoped FKs, exclusions, generated totals.
- Commands: success, duplicate replay, conflicting retry, stale state, unauthorized tenant.
- Concurrency: simultaneous stock reservation, overlapping booking, deterministic multi-row locks.
- Ledger: balance by currency, immutability, reversal linkage.
- Migration: fresh install and supported upgrade paths with representative data.
- Performance: target cardinality, keyset plan, statement and row budgets.
- Security: negative cross-tenant access, role matrix, RLS, redacted logs.
- Recovery: backup restore, integrity queries, outbox replay, reconciliation.

## Exit criteria
No unresolved critical invariant, privacy, restore, or plan regression. Every accepted exception has an owner, expiry, and compensating control.
