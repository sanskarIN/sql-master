# Architecture Decision Records

## ADR-001 - PostgreSQL as authoritative engine
Status: Accepted. The capstone requires transactions, constraints, range exclusions, JSON payloads, indexing, RLS, and recovery tooling in one platform.

## ADR-002 - Integer paise for stored monetary amounts
Status: Accepted. Prevents binary floating-point error and makes rounding boundaries explicit.

## ADR-003 - Append-only movements and postings
Status: Accepted. Authoritative economic and inventory events are corrected by new facts, not destructive update.

## ADR-004 - Transactional outbox
Status: Accepted. Business state and publish intent commit together; transport delivery is retried independently.

## ADR-005 - Keyset pagination on high-volume timelines
Status: Accepted. Stable bounded pages avoid offset drift and deep-scan cost.

## ADR-006 - Expand-contract migrations
Status: Accepted. Compatibility, bounded backfill, validation, and delayed removal reduce release risk.
