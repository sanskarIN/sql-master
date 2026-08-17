# AtlasOps Architecture

## Principle
Tenant identity, command identity, time basis, money units, authorization, and evidence must survive every boundary.

## Contexts
- Core: tenants, users, memberships, command identity.
- Catalog: stable product identity and effective-dated prices.
- Inventory: balances, immutable movements, reservations, warehouses.
- Booking: resources, holds, confirmations, cancellations, conflict rules.
- Commerce: order snapshots and state transitions.
- Ledger: immutable balanced postings and reversals.
- Integration: transactional outbox and retry evidence.
- Audit: administrative and sensitive-operation evidence.

## Write path
1. Authenticate and resolve tenant context.
2. Validate command and stable idempotency key.
3. Lock or constrain the invariant owner.
4. Write authoritative facts and outbox event in one transaction.
5. Commit once; recover ambiguous outcomes using the original key.

## Read path
Use tenant-scoped projections, bounded keyset pagination, deterministic ordering, explicit time and currency policies, and measured indexes.
