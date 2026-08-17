# Resume and Project-Story Templates

## Quantified resume bullet

**Action + system + scale + engineering decision + measured result + evidence**

Example template: “Designed a PostgreSQL order and inventory workflow for [scale], using [constraint/transaction/index pattern], reducing [latency/error/cost] from [before] to [after], verified by [tests/plans/dashboard/reconciliation].”

Never invent numbers. Use measured local benchmark results, explicitly label synthetic scale, or describe qualitative outcomes honestly.

## Three-minute project story

1. Product problem and users.
2. The hardest invariant or ambiguity.
3. Your schema and transaction boundary.
4. A failure discovered in testing or review.
5. The performance/security/evolution trade-off.
6. Measured result and reproducible evidence.
7. What you would change at ten times the scale.

## Portfolio README order

- Problem and scope
- Architecture diagram
- Invariants and data contracts
- Setup and reproducible seed
- Core workflows
- Tests and expected outputs
- Performance evidence
- Security and privacy decisions
- Migration and recovery notes
- Demo script
- Known limits and next steps
