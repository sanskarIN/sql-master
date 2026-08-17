-- Reconciliation, health checks, and operational evidence.

-- Inventory movement projection must equal the maintained balance when all opening
-- stock is represented by movements in a production dataset.
CREATE OR REPLACE VIEW inventory.v_balance_reconciliation AS
SELECT b.tenant_id,b.product_id,b.warehouse_id,b.on_hand_qty,b.reserved_qty,
       COALESCE(SUM(m.quantity_delta) FILTER (WHERE m.movement_type IN ('RECEIPT','SHIP','ADJUSTMENT','TRANSFER_IN','TRANSFER_OUT')),0) AS net_physical_movement
FROM inventory.stock_balance b
LEFT JOIN inventory.stock_movement m
  ON (m.tenant_id,m.product_id,m.warehouse_id)=(b.tenant_id,b.product_id,b.warehouse_id)
GROUP BY b.tenant_id,b.product_id,b.warehouse_id,b.on_hand_qty,b.reserved_qty;

-- Posted journals must balance by currency.
CREATE OR REPLACE VIEW ledger.v_unbalanced_posted_entry AS
SELECT p.tenant_id,p.entry_id,p.currency_code,
       SUM(CASE WHEN p.side='DEBIT' THEN p.amount_paise ELSE -p.amount_paise END) AS signed_paise
FROM ledger.posting p
JOIN ledger.journal_entry e USING (tenant_id,entry_id)
WHERE e.entry_state='POSTED'
GROUP BY p.tenant_id,p.entry_id,p.currency_code
HAVING SUM(CASE WHEN p.side='DEBIT' THEN p.amount_paise ELSE -p.amount_paise END) <> 0;

-- Operations dashboard candidates.
SELECT count(*) AS pending_events,
       COALESCE(max(clock_timestamp()-occurred_at),interval '0') AS oldest_event_age
FROM integration.outbox_event WHERE published_at IS NULL;

SELECT datname,numbackends,xact_commit,xact_rollback,blks_read,blks_hit,temp_files,temp_bytes,deadlocks
FROM pg_stat_database WHERE datname=current_database();

-- Backup and restore evidence belongs in an external retained transcript.
-- Validate restored maximum commit time, critical counts/sums, tenant isolation,
-- command smoke tests, outbox replay, and reconciliation views.
