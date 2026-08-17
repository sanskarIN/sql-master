# Timed Advanced Interview Sets

## Set A - Window semantics (35 minutes)

1. Compute a running paid-revenue total in event order. Explain `ROWS` versus `RANGE` when timestamps tie.
2. Return the top two distinct price groups per account while preserving ties.
3. Carry the most recent non-NULL page code through an event stream without vendor-specific `IGNORE NULLS`.
4. Produce a seven-calendar-day moving total, including days with no orders.
5. Diagnose why a default window frame returns a surprising last value.

Evidence: output grain, total order, peer behavior, frame boundaries, calendar spine, tests.

## Set B - Product analytics (45 minutes)

1. Sessionize events with a 30-minute inactivity rule; define the exact-boundary behavior.
2. Build an ordered signup-view-cart-purchase funnel inside seven days.
3. Compute weekly signup cohorts and week-N retention with a fixed denominator.
4. Find each user's longest consecutive active-day island.
5. Explain late-event correction and rerun strategy.

Evidence: event versus ingestion time, ordered steps, cohort denominator, deduplication, incremental repair.

## Set C - Temporal and graph SQL (45 minutes)

1. Join each order line to the price valid at order time.
2. Detect overlapping price versions and missing coverage.
3. Traverse an employee hierarchy with depth, path, cycle control, and maximum depth.
4. Return users who performed every event in a required set.
5. Compare recursive traversal with a closure table for a read-heavy system.

Evidence: half-open intervals, tie-breaker, recursion termination, relational division, workload trade-off.

## Set D - Production reasoning (50 minutes)

1. Read an `EXPLAIN (ANALYZE, BUFFERS)` plan with a 100x row-estimation error.
2. Rewrite a non-sargable date predicate.
3. Design stable descending keyset pagination under concurrent inserts.
4. Protect a two-row invariant from write skew.
5. Recover safely when a payment command commits but the response is lost.

Evidence: cardinality, statistics, plan nodes, index order, snapshot semantics, isolation, idempotency hash, retry class.
