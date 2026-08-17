# Architecture Decision Record

## Decision
Use an append-only stock movement ledger as the authoritative quantity history. Maintain `stock_balances` transactionally as the current enforcement projection. Keep reservations separate from ownership-changing movements. Model transfers with explicit dispatch and receipt events. Treat reorder suggestions and forecasts as derived planning evidence, never as stock truth.

## Core invariants
1. On-hand quantity never becomes negative.
2. Reserved quantity is non-negative and never exceeds on-hand quantity.
3. One retried command reuses one idempotency key and identical request hash.
4. Every posted receipt creates authoritative stock movements.
5. Transfer receipt cannot exceed transfer dispatch.
6. Purchase-order received plus cancelled quantity cannot exceed ordered quantity.
7. Lot quality and expiry are enforced during allocation.
8. Cycle-count variance becomes an explicit adjustment movement after approval; history is not overwritten.
9. Ledger, balance, and active-reservation projections are reconciled independently.
10. Forecast and reorder policy versions are retained with every recommendation.

## Allocation
Use FEFO for expiring lots and deterministic bin/lot order for locks. Consider FIFO, zone priority, package constraints, serial selection, and customer-specific rules only when explicitly required and tested.

---
Official store: **https://ramsandesh.gumroad.com**
