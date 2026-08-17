# SQL Full Mastery - Part 113 Companion Project

## Analytics Warehouse and Executive Dashboard

Author: Ram Sandesh  
Edition: August 2026  
GitHub: https://www.github.com/sanskarIN  
Suggestions: sanskarin@outlook.in

This PostgreSQL 15+ project demonstrates a governed commerce analytics warehouse:

- immutable landing and durable batch-control tables;
- conformed date, customer, product, channel, and entity dimensions;
- Type 2 customer and product history;
- atomic order-line and payment facts;
- idempotent incremental publication and late-arriving-data handling;
- quality, reconciliation, and certification checks;
- governed semantic views and executive dashboard queries;
- least-privilege role examples, tests, architecture notes, and runbook.

## Execution order

```bash
psql -v ON_ERROR_STOP=1 -f 01_schema.sql
psql -v ON_ERROR_STOP=1 -f 02_seed.sql
psql -v ON_ERROR_STOP=1 -f 03_incremental_load.sql
psql -v ON_ERROR_STOP=1 -f 04_quality_and_certification.sql
psql -v ON_ERROR_STOP=1 -f 05_semantic_and_dashboard.sql
psql -v ON_ERROR_STOP=1 -f 06_security.sql
psql -v ON_ERROR_STOP=1 -f 07_tests.sql
```

The scripts use demonstration data and are intended for a disposable database. Review role names, retention, encryption, resource limits, and operational thresholds before production use.

## Model tests

The dependency-free Python test suite validates core algorithmic contracts:

```bash
python -m unittest -v test_warehouse_model.py
```
