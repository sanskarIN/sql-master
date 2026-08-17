# Advanced SQL Interview Answer Rubric

Score each dimension from 0 to 4. A strong answer is usually 18/24 or better and has no correctness failure.

| Dimension | 0 | 2 | 4 |
|---|---|---|---|
| Result contract | No grain or ambiguous output | Partial grain and filters | Exact grain, keys, time/NULL/tie policy |
| Correctness | Query is wrong | Works on happy path | Handles duplicates, NULLs, boundaries, empty sets |
| Determinism | Unspecified order | Mostly stable | Complete total order and explicit tie behavior |
| Decomposition | Unstructured syntax | Some staging | Named stages with one grain/invariant each |
| Performance | No plan reasoning | Generic index claim | Cardinality, plan nodes, memory, loops, matching index |
| Communication | Cannot defend | Explains syntax | States assumptions, alternatives, tests, production trade-offs |

## Automatic red flags

- Aggregating after two independent child joins without proving multiplicity.
- Using `NOT IN` when the subquery may contain `NULL`.
- Using `ROW_NUMBER()` without a unique tie-breaker when exactly one row is required.
- Treating `RANGE` and `ROWS` as interchangeable.
- Computing cohort retention with the active population as the denominator.
- Joining temporal tables without a half-open validity contract.
- Recursive SQL without cycle and depth controls.
- Recommending an index without reading estimated versus actual rows.
- Retrying every transaction error instead of only documented transient classes.
- Using `OFFSET` for a mutable, deep, user-facing feed without discussing drift.

## Five-minute answer pattern

1. Restate the result grain and required edge behavior.
2. Name the authoritative relations and keys.
3. Build one stage per grain change.
4. State partition, order, frame, and tie behavior for each window.
5. Test with one normal row, one tie, one missing row, one duplicate, and one boundary.
6. Explain the likely plan and matching index.
7. Name the consistency level when concurrent writes matter.
