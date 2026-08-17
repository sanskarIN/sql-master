# Intermediate SQL Interview Answer Rubric

Score each dimension from 0 to 4.

| Dimension | 0 | 2 | 4 |
|---|---|---|---|
| Requirement | Misreads output | Mostly correct | States exact output grain, filters, ties, and time rules |
| Correctness | Wrong result | Works on ordinary data | Correct under duplicates, NULLs, missing parents, and ties |
| Query shape | Uncontrolled join | Partly staged | Aggregates at safe grains; stages transformations clearly |
| Determinism | No tie-breaker | Partial order | Total order and stable cursor/window semantics |
| Performance | No reasoning | Generic index claim | Connects predicates/order/cardinality to plan and index |
| Testing | No tests | Happy path | Minimal adversarial dataset with expected outputs |
| Communication | SQL only | Some explanation | Explains assumptions, alternatives, complexity, and validation |

**Interpretation:** 24-28 = strong intermediate; 19-23 = interview-ready with focused practice; 13-18 = concept known but execution inconsistent; below 13 = rebuild grain, joins, NULL, grouping, and window fundamentals.
