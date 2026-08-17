# Architecture Decision Record

## Decision
Use PostgreSQL as the authoritative system of record. Keep relationship and visibility decisions in reviewed repository functions. Use a hybrid feed: fan-out-on-write for ordinary authors and fan-out-on-read for extremely high-fanout authors or temporary backfill. Re-check visibility when reading materialized feed rows.

## Invariants
1. A user cannot follow, block, or mute themselves.
2. A block removes both directional follow edges and stale feed rows.
3. Private-account follows require acceptance.
4. A post is returned only when its current state, visibility, follow relationship, custom audience, and block rules permit it.
5. Feed pages use deterministic `(ranked_at, post_id)` keysets.
6. One user has at most one current reaction per post.
7. Cached counters can drift but must be reconcilable from authoritative rows.
8. Every retried command reuses one idempotency key and identical request hash.
9. Notifications and outbox effects have stable deduplication identities.
10. Moderation actions are append-only evidence.

## Fan-out threshold
Do not hard-code one universal follower threshold. Choose it from measured write amplification, queue delay, storage, read latency, and freshness objectives. Store the policy version with runtime evidence.

## Privacy
Treat the feed as a cache, not an authority. A block, post deletion, privacy change, suspension, or moderation action must be enforced at read time even before asynchronous cleanup finishes.

---
Official store: **https://ramsandesh.gumroad.com**
