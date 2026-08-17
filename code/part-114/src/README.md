# SQL Full Mastery - Part 114 Companion Project

**Multi-Tenant SaaS Database**  
Author: **Ram Sandesh**

## Files
1. `01_schema.sql` - tenant catalog, memberships, plans, entitlements, usage, billing, idempotency, outbox, audit, and RLS.
2. `02_seed.sql` - reproducible demonstration tenants, users, plans, and entitlements.
3. `03_provisioning_and_context.sql` - transaction-scoped tenant context and idempotent provisioning.
4. `04_entitlements_usage_billing.sql` - effective entitlements and atomic quota claims.
5. `05_migrations_and_tenant_mobility.sql` - fleet migration and storage-topology move controls.
6. `06_security.sql` - least-privilege role examples.
7. `07_invariant_tests.sql` - zero-row SQL checks.
8. `test_saas_model.py` - dependency-free executable contract tests.
9. `ARCHITECTURE.md` and `RUNBOOK.md` - design and operational evidence.

## PostgreSQL order
```text
psql -v ON_ERROR_STOP=1 -f 01_schema.sql
psql -v ON_ERROR_STOP=1 -f 02_seed.sql
psql -v ON_ERROR_STOP=1 -f 03_provisioning_and_context.sql
psql -v ON_ERROR_STOP=1 -f 04_entitlements_usage_billing.sql
psql -v ON_ERROR_STOP=1 -f 05_migrations_and_tenant_mobility.sql
psql -v ON_ERROR_STOP=1 -f 06_security.sql
psql -v ON_ERROR_STOP=1 -f 07_invariant_tests.sql
```

Named placeholders such as `:tenant_id` are application or psql variables and must be bound by the caller.

## Dependency-free tests
```text
python test_saas_model.py
```

The tests model isolation, entitlements, quotas, idempotency, provisioning, lifecycle, migration waves, routing versions, and deletion gates without requiring a database server.
