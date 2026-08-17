# Production Runbook

## Suspected cross-tenant exposure
1. Freeze affected routes and revoke suspect credentials.
2. Preserve request, connection, query, cache-key, job, and audit evidence.
3. Identify the policy version and tenant-context source.
4. Prove affected rows and consumers; do not estimate from logs alone.
5. Correct by approved migration or compensating action, then reconcile.

## Quota drift
Compare authoritative usage events with counters, stop destructive enforcement, rebuild affected periods, and retain before/after evidence.

## Noisy neighbour
Inspect pool waits, CPU, I/O, lock time, queue depth, and per-tenant rate. Apply bounded concurrency, workload classes, or tenant relocation.

## Fleet migration failure
Stop new claims for the failed wave, retain lease/error evidence, verify partial DDL state, use forward-fix when rollback is unsafe, and resume only after representative validation.

## Tenant restore
Restore into an isolated location, verify tenant identity and row counts, reconcile critical business totals, rotate credentials, then perform a versioned routing cutover.
