# SQL Full Mastery - Part 117 Companion Package

**Intermediate Query Challenges**  
Author: **Ram Sandesh**  
Primary dialect: PostgreSQL 15+

## Contents

- `schema.sql` - interview-practice schema, constraints, and supporting indexes.
- `seed.sql` - compact adversarial data: zero-row parents, duplicate-like emails, split payments, gaps, overlaps, NULLs, and ties.
- `challenge_bank.csv` - 48 timed intermediate challenges with expected reasoning features.
- `solutions.sql` - complete reference patterns and full solutions for the core challenge families.
- `timed_sets.md` - four structured mock-interview sets.
- `answer_rubric.md` - scoring framework for correctness, grain, NULLs, determinism, performance, and communication.
- `test_contracts.py` - dependency-free package tests.

## Recommended run order

```bash
createdb sql_mastery_117
psql -d sql_mastery_117 -f schema.sql
psql -d sql_mastery_117 -f seed.sql
psql -d sql_mastery_117 -f solutions.sql
python test_contracts.py
```

The SQL files intentionally use PostgreSQL features such as `FILTER`, recursive CTEs, `generate_series`, range types, tuple comparison, and ordered-set aggregates. Adapt those sections explicitly when practising another dialect.
