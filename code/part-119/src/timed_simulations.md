# Six Timed Senior Interview Simulations

## Simulation 1 - Marketplace checkout (50 minutes)
Design customer, product, price, cart, order, inventory reservation, payment, and outbox data. Prevent overselling and duplicate checkout. Explain indexes, ambiguous payment outcomes, and reconciliation.

## Simulation 2 - Resource booking (45 minutes)
Model resources, availability, holds, confirmed bookings, cancellations, and waitlists across time zones. Prevent overlap under concurrency. Explain half-open ranges, isolation, and expired-hold cleanup.

## Simulation 3 - Financial ledger (50 minutes)
Design accounts, journal entries, postings, transfers, reversals, holds, and external settlement reconciliation. Prove balance by currency and explain immutable correction.

## Simulation 4 - High-volume work queue (40 minutes)
Design scheduled jobs, priorities, leases, retries, poison-message handling, worker claims, and observability. Compare `SKIP LOCKED`, advisory locks, and an external queue.

## Simulation 5 - Zero-downtime migration (45 minutes)
Change a live identifier and add a required derived column across multiple application versions. Produce expand-contract steps, backfill controls, validation, rollback/forward-fix, and release evidence.

## Simulation 6 - Performance and incident review (60 minutes)
A tenant-scoped dashboard regressed from 300 ms to 18 s after growth. Diagnose plan evidence, cardinality/skew, partition pruning, memory spill, index options, write cost, rollout, and post-incident protections.

For each simulation, spend the first five minutes writing assumptions and invariants, reserve the last ten minutes for failure modes, evidence, and recovery.
