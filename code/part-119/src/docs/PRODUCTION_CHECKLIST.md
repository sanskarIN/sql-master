# Production Evidence Checklist

## Design
- [ ] Grain, keys, cardinality, NULL, time, history, deletion, and tenant scope documented
- [ ] Invariants mapped to constraints, trusted transactions, tests, and owners
- [ ] Read/write workload and retention assumptions recorded

## Transactions
- [ ] Transaction boundary matches one business command
- [ ] Lost update, write skew, phantoms, deadlock, timeout, and ambiguous commit considered
- [ ] Idempotency key, request hash, result recovery, and retry classification tested

## Performance
- [ ] Representative-scale plan captured with actual rows and buffers
- [ ] Index benefit, write cost, maintenance, selectivity, and fallback measured
- [ ] Pagination and ordering contracts are deterministic

## Evolution and Security
- [ ] Expand-contract path, compatibility window, backfill, validation, and forward-fix defined
- [ ] Least privilege, tenant isolation, parameter binding, secret handling, and audit tests pass

## Recovery and Operations
- [ ] RPO/RTO approved; backups encrypted and off-site
- [ ] Restore drill completed with integrity and reconciliation evidence
- [ ] Metrics, alerts, runbooks, owners, and review dates are current
