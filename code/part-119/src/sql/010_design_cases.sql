-- Senior design interview drills
-- For each case, state grain, keys, invariants, history, deletion, and access paths.

-- Case 1: Customer email uniqueness with soft deletion.
-- Strong answer: scoped partial unique index; define reactivation and retention policy.

-- Case 2: Product price history.
-- Strong answer: stable product identity plus effective-dated price versions; no overwrite of historical order facts.

-- Case 3: Multiple addresses per customer with one default address per type.
-- Strong answer: address identity plus partial unique constraint for active default, transactional switch.

-- Case 4: Many-to-many tags with tenant scope.
-- Strong answer: explicit junction grain, composite tenant-safe FKs, pair uniqueness, history policy.

-- Case 5: Booking overlap.
-- Strong answer: half-open ranges and a database exclusion constraint or serialized allocator.

-- Case 6: Ledger postings.
-- Strong answer: immutable journal entry and posting facts, balanced-by-currency invariant at transaction end.

-- Case 7: Derived balances.
-- Strong answer: authoritative movement/posting facts plus transactionally maintained projection and reconciliation.

-- Case 8: Audit log.
-- Strong answer: actor, action, object, before/after, correlation, append-only controls, privacy/retention.

-- Case 9: Multi-tenant foreign keys.
-- Strong answer: tenant_id carried in PK/FK paths; RLS is defense in depth, not a substitute for keys.

-- Case 10: Document attributes.
-- Strong answer: typed columns for governed predicates; JSONB for sparse extensions with validation and indexes only where justified.
