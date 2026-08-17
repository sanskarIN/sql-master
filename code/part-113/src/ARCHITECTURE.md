# Architecture Decisions

1. **Atomic facts are authoritative.** Dashboard aggregates can be rebuilt.
2. **Landing is immutable.** Invalid records are quarantined; they are not silently deleted.
3. **Every fact has declared grain.** A source line version is unique by `(source_order_line_id, source_updated_at)`.
4. **Historical dimensions use event time.** Type 2 joins use `[valid_from, valid_to)`.
5. **Money uses integer paise plus currency.** Ratios are computed from aggregate components.
6. **Publication is gated.** A dashboard reads only the current certified snapshot.
7. **Incremental loads are replay safe.** Stable source identity and uniqueness prevent duplication.
8. **Quality and reconciliation are retained.** Results belong to a batch and are incident evidence.
9. **The semantic layer owns metric meaning.** Dashboards do not redefine core measures.
10. **Least privilege is schema-based.** Dashboard readers cannot access landing payloads.
