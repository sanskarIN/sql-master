# SQL Full Mastery - Part 112 Companion Project

**Booking System with Concurrency Control**  
Author: **Ram Sandesh**  
Primary database: **PostgreSQL 15+**

This project demonstrates a production-oriented booking data model with:

- tenant-scoped resources and resource pools;
- weekly availability and blackout windows;
- transaction-owned holds and confirmations;
- `tstzrange` plus GiST exclusion constraints for race-proof overlap prevention;
- request idempotency and conflicting-retry detection;
- payment, cancellation, waitlist, event, and outbox records;
- stable keyset pagination and independent reconciliation;
- worker patterns using `FOR UPDATE SKIP LOCKED`;
- static contract tests and an executable in-memory concurrency model.

## Files

- `sql/01_schema.sql` - types, tables, constraints, exclusion rules, and indexes.
- `sql/02_commands.sql` - hold, confirm, expire, and cancel transaction patterns.
- `sql/03_queries.sql` - availability, paging, reporting, waitlist, and reconciliation.
- `sql/04_operations.sql` - outbox, expiry, mismatch, and plan checks.
- `sql/05_seed.sql` - deterministic demo master data.
- `sql/06_invariant_tests.sql` - disposable-database invariant checks.
- `tests/test_contracts.py` - verifies required SQL safety contracts.
- `tests/test_booking_model.py` - executable booking/concurrency behavior model.
- `docs/architecture.md` - decisions and boundaries.
- `docs/runbook.md` - operational response steps.

## Run local tests

```bash
python -m unittest discover -s tests -v
```

## Load into PostgreSQL

```bash
psql -v ON_ERROR_STOP=1 -f sql/01_schema.sql
psql -v ON_ERROR_STOP=1 -f sql/05_seed.sql
psql -v ON_ERROR_STOP=1 -f sql/06_invariant_tests.sql
```

The placeholder syntax (`:tenant_id`, `:starts_at`, etc.) in command/query files is intentionally driver-oriented. Bind values through the application driver; never interpolate untrusted text into SQL.

## Production warning

The Python model tests prove domain logic, not PostgreSQL lock scheduling. Before production, add integration tests with real concurrent sessions, fault injection, deadlock retries, ambiguous-commit reconciliation, migration-path testing, and backup/restore drills.
