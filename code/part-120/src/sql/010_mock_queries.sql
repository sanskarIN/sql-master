SET search_path=final120,public;

-- 1. Deterministic latest paid order per customer.
WITH ranked AS (
  SELECT o.*,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY ordered_at DESC,order_id DESC) rn
  FROM sales_order o WHERE status='PAID'
)
SELECT * FROM ranked WHERE rn=1 ORDER BY customer_id;

-- 2. NULL-safe anti-join: customers without paid orders.
SELECT c.customer_id,c.email
FROM customer c
WHERE NOT EXISTS (SELECT 1 FROM sales_order o WHERE o.customer_id=c.customer_id AND o.status='PAID')
ORDER BY c.customer_id;

-- 3. Running paid revenue: explicit ROWS frame plus unique order.
SELECT ordered_at,order_id,total_paise,
       SUM(total_paise) OVER(ORDER BY ordered_at,order_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_paise
FROM sales_order WHERE status='PAID'
ORDER BY ordered_at,order_id;

-- 4. Sessionization: strict >= 30-minute boundary.
WITH x AS (
 SELECT e.*,LAG(occurred_at) OVER(PARTITION BY customer_id ORDER BY occurred_at,event_id) prev_time
 FROM product_event e
), y AS (
 SELECT x.*,CASE WHEN prev_time IS NULL OR occurred_at-prev_time>=interval '30 minutes' THEN 1 ELSE 0 END new_session
 FROM x
), z AS (
 SELECT y.*,SUM(new_session) OVER(PARTITION BY customer_id ORDER BY occurred_at,event_id ROWS UNBOUNDED PRECEDING) session_no
 FROM y
)
SELECT customer_id,session_no,MIN(occurred_at) session_start,MAX(occurred_at) session_end,COUNT(*) events
FROM z GROUP BY customer_id,session_no ORDER BY customer_id,session_no;

-- 5. Keyset page for paid orders.
SELECT order_id,customer_id,ordered_at,total_paise
FROM sales_order
WHERE status='PAID' AND (ordered_at,order_id)<(:cursor_time,:cursor_id)
ORDER BY ordered_at DESC,order_id DESC LIMIT :page_size;

-- 6. Atomic inventory reservation. Require one affected row.
UPDATE stock_balance
SET reserved_qty=reserved_qty+:qty,row_version=row_version+1
WHERE product_id=:product_id AND on_hand_qty-reserved_qty>=:qty;

-- 7. Order reconciliation. Strong interview answer states expected zero differences.
SELECT * FROM order_line_reconciliation WHERE difference_paise<>0;

-- 8. Ledger balance. Strong answer balances every entry and currency.
SELECT * FROM ledger_balance_check WHERE net_paise<>0;

-- 9. Ordered funnel: signup -> view -> cart -> purchase.
WITH signup AS (
 SELECT customer_id,MIN(occurred_at) signup_time FROM product_event WHERE event_name='signup' GROUP BY customer_id
), steps AS (
 SELECT s.customer_id,s.signup_time,v.view_time,c.cart_time,p.purchase_time
 FROM signup s
 LEFT JOIN LATERAL (SELECT MIN(occurred_at) view_time FROM product_event e WHERE e.customer_id=s.customer_id AND e.event_name='view' AND e.occurred_at>=s.signup_time AND e.occurred_at<s.signup_time+interval '7 days') v ON true
 LEFT JOIN LATERAL (SELECT MIN(occurred_at) cart_time FROM product_event e WHERE e.customer_id=s.customer_id AND e.event_name='cart' AND e.occurred_at>=v.view_time AND e.occurred_at<s.signup_time+interval '7 days') c ON v.view_time IS NOT NULL
 LEFT JOIN LATERAL (SELECT MIN(occurred_at) purchase_time FROM product_event e WHERE e.customer_id=s.customer_id AND e.event_name='purchase' AND e.occurred_at>=c.cart_time AND e.occurred_at<s.signup_time+interval '7 days') p ON c.cart_time IS NOT NULL
)
SELECT COUNT(*) signed_up,COUNT(view_time) viewed,COUNT(cart_time) carted,COUNT(purchase_time) purchased FROM steps;

-- 10. Plan review target.
EXPLAIN (ANALYZE,BUFFERS,SETTINGS)
SELECT order_id,ordered_at,total_paise FROM sales_order
WHERE customer_id=:customer_id AND status='PAID'
ORDER BY ordered_at DESC,order_id DESC LIMIT 20;
