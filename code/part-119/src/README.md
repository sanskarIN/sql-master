# SQL Full Mastery - Part 119 Companion Package

**Title:** Database Design, Transactions, and Performance Interviews  
**Author:** Ram Sandesh  
**Edition:** August 2026  
**Target database:** PostgreSQL 15+

This package supports the full Part 119 manuscript with a reproducible interview lab. It is designed for senior-level reasoning rather than memorized syntax.

## Package contents

- `sql/001_schema.sql` - multi-tenant commerce, booking, ledger, inventory, and job-processing lab schema
- `sql/002_seed.sql` - adversarial seed data with ties, NULLs, skew, late facts, and boundary cases
- `sql/010_design_cases.sql` - schema-design and constraint scenarios
- `sql/020_transactions_concurrency.sql` - isolation, locking, deadlock, idempotency, and retry patterns
- `sql/030_performance_plans.sql` - indexing and execution-plan interview drills
- `sql/040_evolution_security_recovery.sql` - migrations, row isolation, backup, and recovery prompts
- `tests/001_invariant_checks.sql` - executable invariant and reconciliation queries
- `case_bank.csv` - 72 senior interview cases
- `timed_simulations.md` - six complete timed interview simulations
- `answer_rubric.md` - scoring framework for design, correctness, evidence, and communication
- `model_tests.py` - dependency-free package and reasoning tests
- `docs/ARCHITECTURE.md` - system boundaries and declared invariants
- `docs/PRODUCTION_CHECKLIST.md` - release and operational evidence checklist

## Recommended use

1. Read one scenario without opening the solution file.
2. State the output or write invariant, failure model, and assumptions.
3. Sketch the schema or transaction boundary before writing SQL.
4. Produce a baseline answer and a proof plan.
5. Compare against the solution notes.
6. Record the missed edge case and repeat under a time limit.

## Run package tests

```bash
python model_tests.py
```

## PostgreSQL run order

```bash
psql -v ON_ERROR_STOP=1 -f sql/001_schema.sql
psql -v ON_ERROR_STOP=1 -f sql/002_seed.sql
psql -v ON_ERROR_STOP=1 -f tests/001_invariant_checks.sql
```

The SQL files are educational and intentionally include comments describing interview assumptions. Review permissions and resource limits before using any pattern in production.
