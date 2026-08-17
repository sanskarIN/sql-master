# Part 118 Production and Interview Checklist

- The output grain is written in one sentence.
- Every join cardinality is predicted before SQL is written.
- Every window declares partition, complete order, frame, and tie policy.
- Calendar windows use a date spine when zero-event periods matter.
- Session boundary uses an explicit `>` or `>=` rule.
- Funnel steps are ordered and bounded from a declared anchor.
- Cohort denominator is fixed and reproducible.
- Temporal joins use one interval convention, normally `[start, end)`.
- Recursive queries have seed, transition, cycle control, and depth control.
- Every chosen single row has a unique tie-breaker.
- Plan reasoning compares estimated and actual rows at each critical node.
- Index advice matches equality predicates, range, and output order.
- Concurrency answers name the invariant owner and isolation/locking strategy.
- Idempotent commands bind a stable key to a request hash and stored result.
- Tests include ties, NULLs, duplicates, empty inputs, boundary time, late rows, and concurrent mutation.
- The final answer communicates assumptions, SQL, evidence, complexity, and alternatives.
