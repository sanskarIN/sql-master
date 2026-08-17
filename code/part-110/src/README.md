# SQL Full Mastery - Part 110 Companion Project

**Social Platform Feed and Relationship Queries**  
Author: **Ram Sandesh** | Edition: **August 2026**

## Purpose
This PostgreSQL-first project demonstrates durable social-data contracts: user identity, profile search, follows, private-account requests, blocks, mutes, post visibility, comments, one-reaction-per-user, feed fan-out, keyset pagination, moderation queues, notifications, counters, outbox delivery, graph queries, row-level security, reconciliation, and operational evidence.

## Files
- `sql/01_schema.sql` - types, tables, constraints, indexes, search vectors.
- `sql/02_relationship_commands.sql` - visibility, follow, block, publication, reaction functions.
- `sql/03_feed_queries.sql` - write/read fan-out, home feed, suggestions, recursive paths, search.
- `sql/04_moderation_notifications.sql` - work queues, notifications, counter repair, RLS, health queries.
- `sql/05_seed.sql` - deterministic demonstration rows.
- `sql/06_invariant_tests.sql` - database invariant assertions.
- `tests/test_contracts.py` - static contract and safety tests.
- `tests/test_feed_model.py` - executable in-memory model tests for privacy and pagination.
- `docs/architecture.md` and `docs/runbook.md` - decision and production-operation records.

## PostgreSQL run order
```bash
createdb sql_mastery_social
psql -v ON_ERROR_STOP=1 -d sql_mastery_social -f sql/01_schema.sql
psql -v ON_ERROR_STOP=1 -d sql_mastery_social -f sql/02_relationship_commands.sql
psql -v ON_ERROR_STOP=1 -d sql_mastery_social -f sql/03_feed_queries.sql
psql -v ON_ERROR_STOP=1 -d sql_mastery_social -f sql/04_moderation_notifications.sql
psql -v ON_ERROR_STOP=1 -d sql_mastery_social -f sql/05_seed.sql
psql -v ON_ERROR_STOP=1 -d sql_mastery_social -f sql/06_invariant_tests.sql
```
Named parameters such as `:viewer_id` are templates for an application or `psql` variables; execute the exact statement needed rather than the entire query catalog at once.

## Local tests without PostgreSQL
```bash
python -m unittest discover -s tests -v
```
The tests prove required files, constraints, bound query templates, keyset order, block/privacy behavior, stable pages, and idempotency markers. They do not replace PostgreSQL integration, concurrency, migration, failover, backup, or restore tests.

## Official store

**Gumroad:** https://ramsandesh.gumroad.com
