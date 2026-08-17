# Senior Database Interview Answer Rubric (100 points)

| Dimension | Points | Full-credit evidence |
|---|---:|---|
| Contract and assumptions | 15 | Grain, keys, time, NULLs, scale, consistency, and non-goals are explicit |
| Data model and invariants | 20 | Correct entities/relationships, constraints, history, tenant scope, and invariant ownership |
| Transaction and failure safety | 20 | Boundary, isolation, locks/versions, idempotency, retries, and ambiguous outcomes |
| Performance reasoning | 15 | Workload-based indexes, actual plan evidence, selectivity/skew, memory/I/O, and write cost |
| Evolution and compatibility | 10 | Expand-contract, mixed-version window, backfill, validation, forward-fix, and evidence |
| Security and privacy | 10 | Least privilege, tenant isolation, parameters, secrets, audit, negative tests, and retention |
| Recovery and communication | 10 | RPO/RTO, restore/reconciliation, alternatives, trade-offs, review trigger, concise structure |

## Score interpretation

- **90-100:** senior/staff-ready; falsifiable contracts and production evidence
- **75-89:** strong; one boundary needs deeper proof or recovery detail
- **60-74:** workable; important assumptions or failure modes are implicit
- **Below 60:** syntax or feature listing without system-level correctness
