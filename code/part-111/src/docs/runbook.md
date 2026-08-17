# Production Runbook

## Primary signals
- Inventory command latency, lock wait, deadlock, retry, and idempotency-conflict rate.
- Available stock by product/warehouse and reservation expiry backlog.
- Ledger-to-balance and reservation-to-balance drift.
- Receipt posting age, open purchase-order age, transfer-in-transit age, and cycle-count queue age.
- Expiry risk, negative-availability prevention events, supplier OTIF, and reorder suggestion volume.
- Outbox oldest event, attempt count, pool wait, statement timeout, WAL growth, backup and restore status.

## Incident: apparent negative or missing stock
1. Freeze the affected product/bin command path; preserve request IDs and movement IDs.
2. Compare movement ledger, current balance, active reservations, open transfer, and posted receipt facts.
3. Do not edit the ledger. Post an approved reversal or adjustment with reason and evidence.
4. Verify all downstream allocations, picks, orders, and planning projections.
5. Record root cause, writer version, corrective migration, and reconciliation scope.

## Incident: reservation backlog
1. Check expiry worker leases, oldest active expiry, and database lock waits.
2. Claim bounded batches with `SKIP LOCKED`; never scan and update the entire table at once.
3. Reconcile reserved projection before bulk repair.
4. Confirm availability recovered without exceeding on-hand stock.

## Release evidence
Retain migration revision, supported upgrade paths, representative volumes, lock/concurrency tests, query plans, rollback or forward-fix plan, backup/restore proof, alert ownership, and review date.

---
Official store: **https://ramsandesh.gumroad.com**
