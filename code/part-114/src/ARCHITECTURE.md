# Architecture Notes

## Invariant
Tenant identity is explicit in every storage, request, cache, job, event, metric, and administrative boundary.

## Storage topologies
- **Shared tables:** lowest operational cost; require tenant keys, composite constraints, RLS, scoped indexes, and strict connection-context hygiene.
- **Dedicated schema:** stronger namespace separation; introduces fleet migration and catalog complexity.
- **Dedicated database:** strongest blast-radius and residency control; highest provisioning, pooling, backup, and observability cost.

## Control plane versus data plane
The control plane owns tenant catalog, routing, plan, entitlement, migration, and lifecycle state. The data plane serves tenant-scoped application traffic. Control-plane failures must not silently widen data access.

## Authoritative versus derived state
Memberships, subscriptions, usage claims, invoices, and audit events are authoritative. Search indexes, caches, usage dashboards, and aggregate metrics are rebuildable and reconciled.

## Tenant mobility
Moves use snapshot, continuous catch-up, independent reconciliation, read-only cutover, route version change, rollback window, and retained evidence.
