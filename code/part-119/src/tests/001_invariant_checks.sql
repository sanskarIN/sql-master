-- Invariant and reconciliation checks. Each query should return zero rows unless noted.
SET search_path = interview119, public;

-- Stock cannot be negative or over-reserved.
SELECT * FROM stock_balance WHERE on_hand_qty < 0 OR reserved_qty < 0 OR reserved_qty > on_hand_qty;

-- Order header must reconcile to lines.
SELECT o.tenant_id,o.order_id,o.total_paise,coalesce(sum(l.quantity*l.unit_price_paise),0) AS line_total
FROM sales_order o LEFT JOIN sales_order_line l USING (tenant_id,order_id)
GROUP BY o.tenant_id,o.order_id,o.total_paise
HAVING o.total_paise <> coalesce(sum(l.quantity*l.unit_price_paise),0);

-- Ledger must balance by entry and currency.
SELECT tenant_id,entry_id,currency_code,
       sum(CASE side WHEN 'D' THEN amount_paise ELSE -amount_paise END) AS net
FROM posting
GROUP BY tenant_id,entry_id,currency_code
HAVING sum(CASE side WHEN 'D' THEN amount_paise ELSE -amount_paise END) <> 0;

-- Cross-tenant references should be impossible through composite FKs.
-- This query is a defensive diagnostic for accidental unscoped columns.
SELECT l.*
FROM sales_order_line l
LEFT JOIN product p ON (p.tenant_id,p.product_id)=(l.tenant_id,l.product_id)
WHERE p.product_id IS NULL;

-- Duplicate live email should be impossible.
SELECT tenant_id,lower(email),count(*)
FROM customer WHERE deleted_at IS NULL AND email IS NOT NULL
GROUP BY tenant_id,lower(email) HAVING count(*)>1;

-- READY jobs should have no claimant; RUNNING jobs should have one.
SELECT * FROM job_queue
WHERE (state='READY' AND claimed_by IS NOT NULL)
   OR (state='RUNNING' AND claimed_by IS NULL);
