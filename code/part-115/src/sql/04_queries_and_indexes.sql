-- Bounded read paths and plan-review examples

-- Customer order history using stable keyset pagination.
PREPARE order_history(uuid,text,timestamptz,uuid,int) AS
SELECT order_id, ordered_at, status, total_paise, currency_code
FROM commerce.sales_order
WHERE tenant_id=$1 AND customer_ref=$2
  AND (ordered_at,order_id) < ($3,$4)
ORDER BY ordered_at DESC, order_id DESC
LIMIT $5;

-- Available inventory by product and warehouse.
SELECT p.sku, w.warehouse_code,
       b.on_hand_qty, b.reserved_qty,
       b.on_hand_qty-b.reserved_qty AS available_qty
FROM inventory.stock_balance b
JOIN catalog.product p USING (tenant_id,product_id)
JOIN inventory.warehouse w USING (tenant_id,warehouse_id)
WHERE b.tenant_id = '00000000-0000-0000-0000-000000000001'
ORDER BY p.sku,w.warehouse_code;

-- Trial balance by currency.
SELECT p.currency_code,
       SUM(CASE WHEN p.side='DEBIT' THEN p.amount_paise ELSE 0 END) AS debit_paise,
       SUM(CASE WHEN p.side='CREDIT' THEN p.amount_paise ELSE 0 END) AS credit_paise
FROM ledger.posting p
JOIN ledger.journal_entry e USING (tenant_id,entry_id)
WHERE p.tenant_id='00000000-0000-0000-0000-000000000001'
  AND e.entry_state='POSTED'
GROUP BY p.currency_code;

-- Pending outbox worker claim pattern.
WITH claimed AS (
  SELECT tenant_id,event_id
  FROM integration.outbox_event
  WHERE published_at IS NULL
  ORDER BY occurred_at,event_id
  FOR UPDATE SKIP LOCKED
  LIMIT 100
)
SELECT o.* FROM integration.outbox_event o JOIN claimed USING (tenant_id,event_id);
