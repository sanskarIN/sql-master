# Architecture and Interview Invariants

## Bounded contexts

- **Identity:** tenants and customers
- **Catalog:** products and commercial attributes
- **Inventory:** stock balances and reservation ownership
- **Commerce:** orders and immutable line snapshots
- **Booking:** time-ranged resource allocation
- **Ledger:** immutable entries and balanced postings
- **Work processing:** claimable jobs and retry state
- **Governance:** schema migration and audit evidence

## Core invariants

1. A tenant-owned reference never crosses a tenant boundary.
2. One active customer email is unique only inside its tenant and live-row scope.
3. Reserved stock never exceeds on-hand stock.
4. Order totals reconcile to immutable line snapshots in integer paise.
5. Active exclusive bookings never overlap for the same tenant and resource.
6. Every posted journal entry balances by currency.
7. Repeated commands reuse the same idempotency identity and request hash.
8. Worker claims are disjoint and recoverable.
9. Schema changes preserve mixed-version compatibility during deployment.
10. Recovery is accepted only after restore, integrity checks, and business reconciliation.

## Senior answer standard

For every case, state the contract, invariant owner, enforcement location, failure model, evidence, alternatives, and rollback or recovery path.
