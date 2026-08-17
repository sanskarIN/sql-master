-- Performance and execution-plan interview drills
SET search_path = interview119, public;

-- 1. Latest orders for one customer. Matching index begins with equality keys then order keys.
CREATE INDEX IF NOT EXISTS ix_order_customer_time
ON sales_order (tenant_id, customer_id, ordered_at DESC, order_id DESC)
INCLUDE (status,total_paise,currency_code);

EXPLAIN (ANALYZE, BUFFERS, WAL, SETTINGS)
SELECT order_id, ordered_at, status, total_paise
FROM sales_order
WHERE tenant_id=1 AND customer_id=1
ORDER BY ordered_at DESC, order_id DESC
LIMIT 20;

-- 2. Keyset pagination; avoid OFFSET drift and linear skip cost.
SELECT order_id, ordered_at, status
FROM sales_order
WHERE tenant_id=1
  AND (ordered_at, order_id) < ('2026-08-03T00:00:00Z', 999999)
ORDER BY ordered_at DESC, order_id DESC
LIMIT 20;

-- 3. Diagnose row-estimate error before adding an index.
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.sku, sum(l.quantity) AS qty
FROM sales_order_line l
JOIN sales_order o USING (tenant_id,order_id)
JOIN product p USING (tenant_id,product_id)
WHERE o.tenant_id=1 AND o.status='CONFIRMED'
GROUP BY p.sku;

-- 4. Sargable date boundary.
-- Preferred: ordered_at >= :start AND ordered_at < :end
-- Avoid: date(ordered_at) = :day unless supported by an intentional expression index.

-- 5. Partial index for the ready queue.
-- Already present: ix_job_claim WHERE state='READY'. Verify selectivity, maintenance cost, and ordering.

-- Interview checklist for a plan:
-- actual vs estimated rows; loops; access path; join method/order; filter rows removed;
-- sort/hash memory and spills; buffers/I/O; parallelism; planning time; execution time; write cost.
