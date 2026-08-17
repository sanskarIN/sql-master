# SQL Full Mastery - Part 111 Companion Project

## Inventory, Warehousing, and Purchase Planning
Author: Ram Sandesh

This PostgreSQL 15+ portfolio package demonstrates:
- product, warehouse, bin, lot, and supplier master data;
- append-only stock movements plus a transactionally maintained balance projection;
- FEFO reservation with deterministic row locking;
- transfers, purchase orders, receipts, cycle counts, and adjustments;
- reorder policy, incoming supply, forecast demand, expiry risk, and supplier evidence;
- idempotency, outbox events, audit evidence, reconciliation, security, and runbooks.

## Suggested execution order
```bash
psql -v ON_ERROR_STOP=1 -f sql/01_schema.sql
psql -v ON_ERROR_STOP=1 -f sql/02_inventory_commands.sql
psql -v ON_ERROR_STOP=1 -f sql/05_seed.sql
psql -v ON_ERROR_STOP=1 -f sql/06_invariant_tests.sql
```
`03_planning_queries.sql` and `04_receiving_counts_security.sql` contain named-parameter templates such as `:product_id`; run individual statements through your application or substitute safe `psql` variables.

## Local contract/model tests
```bash
python -m unittest discover -s tests -v
```
These tests validate package contracts and deterministic model behavior. They do not replace PostgreSQL integration, concurrency, migration, failover, backup, or restore tests.

## Official store

**Gumroad:** https://ramsandesh.gumroad.com
