# SQL Full Mastery - Part 118 Companion Package

## Advanced SQL and Window-Function Interviews

Author: Ram Sandesh  
Edition: August 2026  
Series: Part 118 of 120  
GitHub: https://www.github.com/sanskarIN  
Contact: sanskarin@outlook.in

This package turns the manuscript into a reproducible PostgreSQL interview lab. It contains a compact event-commerce schema, adversarial seed data, advanced query solutions, timed challenge sets, a scoring rubric, and dependency-free package checks.

## Folder map

- `sql/001_schema.sql` - tables, keys, constraints, indexes, and comments
- `sql/002_seed.sql` - deliberately tricky rows: ties, gaps, late events, overlaps, NULLs, and duplicates
- `sql/003_window_interviews.sql` - frames, ranking, percentiles, top-N, rolling values, and change detection
- `sql/004_session_funnel_retention.sql` - sessionization, funnels, cohorts, and retention
- `sql/005_temporal_recursive.sql` - as-of joins, interval overlap, hierarchy, recursive paths, and cycle control
- `sql/006_plan_concurrency.sql` - plan diagnosis, sargability, keyset pagination, locking, and isolation cases
- `tests/001_invariant_queries.sql` - SQL checks that should return zero rows on valid data
- `challenge_bank.csv` - 60 advanced interview prompts with difficulty, skill, edge case, and expected evidence
- `timed_sets.md` - four realistic interview simulations
- `answer_rubric.md` - score answers on correctness, determinism, complexity, plan reasoning, and communication
- `docs/production-checklist.md` - release and interview-readiness checklist
- `scripts/package_tests.py` - dependency-free structural and model tests

## Run with PostgreSQL

```bash
createdb sql_mastery_118
psql -v ON_ERROR_STOP=1 -d sql_mastery_118 -f sql/001_schema.sql
psql -v ON_ERROR_STOP=1 -d sql_mastery_118 -f sql/002_seed.sql
psql -v ON_ERROR_STOP=1 -d sql_mastery_118 -f sql/003_window_interviews.sql
psql -v ON_ERROR_STOP=1 -d sql_mastery_118 -f sql/004_session_funnel_retention.sql
psql -v ON_ERROR_STOP=1 -d sql_mastery_118 -f sql/005_temporal_recursive.sql
psql -v ON_ERROR_STOP=1 -d sql_mastery_118 -f sql/006_plan_concurrency.sql
psql -v ON_ERROR_STOP=1 -d sql_mastery_118 -f tests/001_invariant_queries.sql
```

The SQL is designed for PostgreSQL 15+ and uses `timestamptz`, recursive CTEs, window frames, filtered aggregates, range operators, `LATERAL`, and transaction-control examples. Read comments before adapting to another engine.

## Package-only checks

```bash
python scripts/package_tests.py
```

These tests do not require PostgreSQL. They verify the package contract and model the hardest semantics: peer-aware frames, session boundaries, funnel order, cohort denominators, temporal as-of selection, cycle-safe recursion, keyset ordering, and conflicting idempotency requests.

## Interview rule

Do not begin with syntax. Begin by stating the output grain, authoritative input, tie policy, time boundary, NULL policy, and required consistency level. Then construct, test, and explain the query.
