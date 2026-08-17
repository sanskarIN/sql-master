# Answer Frameworks

## CONTRACT - technical design answer

1. **C - Clarify:** actor, command/query, scale, latency, consistency, retention, and failure assumptions.
2. **O - Output or invariant:** define row grain or state rule and the expected result.
3. **N - Normalize the problem:** identities, relationships, keys, time, money, NULL, history, and tenant scope.
4. **T - Transaction and trust boundary:** transaction owner, constraints, locks/isolation, idempotency, and external calls.
5. **R - Read path and runtime evidence:** indexes, plans, cardinality, memory/I/O, metrics, and representative tests.
6. **A - Alternatives:** rejected options, trade-offs, and the condition that would change the choice.
7. **C - Compatibility and continuity:** migration, mixed versions, backup, restore, and reconciliation.
8. **T - Tell it clearly:** assumptions first, concise stages, evidence, risks, and review trigger.

## ROWS - live SQL answer

- **R:** Result grain and required rows.
- **O:** Ordering, ties, NULL rules, and time boundary.
- **W:** Write the query in named stages.
- **S:** Small adversarial data and expected output.

## TRACE - performance or incident answer

- **T:** Trigger and user-visible impact.
- **R:** Reproduce with query ID, parameters, scale, and baseline.
- **A:** Actual versus estimated rows, loops, I/O, memory, locks, and waits.
- **C:** Controlled change with correctness proof and rollback/forward-fix.
- **E:** Evidence after release and incident learning.

## STAR-E - behavioral/project answer

- **Situation:** concrete product or operational context.
- **Task:** your responsibility and success boundary.
- **Action:** decisions, alternatives, tests, collaboration, and recovery.
- **Result:** measured correctness, latency, cost, reliability, or delivery result.
- **Evidence:** repository, plan, test, dashboard, runbook, or review artifact.
