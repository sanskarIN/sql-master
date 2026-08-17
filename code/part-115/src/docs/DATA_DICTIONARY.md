# Data Dictionary Extract

| Relation | Grain | Authoritative key | Time rule | Sensitivity |
|---|---|---|---|---|
| core.tenant | one platform tenant | tenant_id / tenant_code | created_at UTC | internal |
| catalog.product | one product in tenant | (tenant_id, product_id), scoped SKU | created_at UTC | internal |
| inventory.stock_movement | one quantity-changing event | (tenant_id, movement_id), command_key | occurred_at UTC | operational |
| booking.reservation | one resource time range | (tenant_id, reservation_id), idempotency_key | UTC range; resource TZ retained | customer-linked |
| commerce.sales_order | one customer order | (tenant_id, order_id), idempotency_key | ordered_at UTC | customer-linked |
| ledger.journal_entry | one economic event | (tenant_id, entry_id), idempotency_key | effective and recorded time | financial |
| ledger.posting | one debit/credit leg | (tenant_id, entry_id, posting_no) | inherited effective time | financial |
| integration.outbox_event | one publish intent | event_id plus aggregate version | occurred/published UTC | payload-classified |
