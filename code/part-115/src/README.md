# SQL Full Mastery - Part 115 Companion Project

## AtlasOps Production Database Capstone

Author: Ram Sandesh  
Series: SQL Full Mastery, Part 115 of 120  
Publication Edition: August 2026

This PostgreSQL project joins tenant identity, catalog, inventory, booking, commerce, double-entry ledger, outbox delivery, audit evidence, reconciliation, migrations, security, observability, backup and recovery, and portfolio documentation into one capstone.

## Quick start

1. Start PostgreSQL 16:
   `docker compose up -d`
2. Build the database:
   `make reset`
3. Run SQL invariant checks:
   `make sql-test`
4. Run dependency-free model and package tests:
   `make model-test`
5. Open the demo queries:
   `psql "$DATABASE_URL" -f sql/04_queries_and_indexes.sql`

Default local URL:
`postgresql://postgres:postgres@localhost:55432/atlasops`

## Evidence map

- Schema and constraints: `sql/01_schema.sql`
- Seed and representative states: `sql/02_seed.sql`
- Trusted commands and concurrency: `sql/03_commands.sql`
- Bounded queries and index plans: `sql/04_queries_and_indexes.sql`
- Least privilege and RLS examples: `sql/05_security.sql`
- Reconciliation and operational checks: `sql/06_operations.sql`
- Executable SQL assertions: `sql/07_invariant_tests.sql`
- Architecture, ADRs, dictionary, migration plan, test plan, runbook: `docs/`
- Dependency-free contract/model tests: `tests/test_capstone_model.py`
- Package structure verification: `tests/verify_package.py`

## Production caution

The project is an educational reference. Review PostgreSQL version behavior, role ownership, encryption, backup tooling, extension policy, operational thresholds, and organization-specific compliance requirements before production use.

GitHub: https://www.github.com/sanskarIN  
Suggestions and inquiries: sanskarin@outlook.in
