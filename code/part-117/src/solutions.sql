-- SQL Full Mastery Part 117 - Selected and Reference Solutions
SET search_path = iq117, public;

-- IQ001: one row per customer; aggregate orders before joining.
WITH order_facts AS (
  SELECT customer_id, COUNT(*) AS order_count,
         SUM(stored_total_paise) FILTER (WHERE status='completed') AS revenue_paise
  FROM orders GROUP BY customer_id
)
SELECT c.customer_id, c.customer_name,
       COALESCE(f.order_count,0) AS order_count,
       COALESCE(f.revenue_paise,0) AS revenue_paise
FROM customers c LEFT JOIN order_facts f USING(customer_id)
ORDER BY c.customer_id;

-- IQ002: independent item/payment aggregates avoid m x n multiplication.
WITH item_facts AS (
  SELECT order_id, COUNT(*) item_count, COUNT(DISTINCT product_id) product_count,
         SUM(quantity*unit_price_paise) line_total_paise
  FROM order_items GROUP BY order_id
), payment_facts AS (
  SELECT order_id, SUM(amount_paise) FILTER (WHERE payment_status='captured') captured_paise
  FROM payments GROUP BY order_id
)
SELECT o.order_id, COALESCE(i.item_count,0) item_count, COALESCE(i.product_count,0) product_count,
       COALESCE(i.line_total_paise,0) line_total_paise, COALESCE(p.captured_paise,0) captured_paise
FROM orders o LEFT JOIN item_facts i USING(order_id) LEFT JOIN payment_facts p USING(order_id);

-- IQ003
SELECT p.product_id, p.product_name, COALESCE(SUM(oi.quantity),0) units_sold,
       COUNT(DISTINCT o.customer_id) unique_buyers
FROM products p
LEFT JOIN order_items oi ON oi.product_id=p.product_id
LEFT JOIN orders o ON o.order_id=oi.order_id AND o.status='completed'
 AND o.ordered_at >= TIMESTAMPTZ '2026-08-01' AND o.ordered_at < TIMESTAMPTZ '2026-09-01'
GROUP BY p.product_id,p.product_name ORDER BY p.product_id;

-- IQ004
WITH employee_sales AS (
 SELECT employee_id, SUM(stored_total_paise) revenue_paise
 FROM orders WHERE status='completed' GROUP BY employee_id
)
SELECT d.department_id,d.department_name,COUNT(e.employee_id) employee_count,
       COALESCE(SUM(es.revenue_paise),0) revenue_paise
FROM departments d LEFT JOIN employees e USING(department_id)
LEFT JOIN employee_sales es USING(employee_id)
GROUP BY d.department_id,d.department_name;

-- IQ005
WITH counts AS (
 SELECT c.customer_id, COUNT(o.order_id) order_count
 FROM customers c LEFT JOIN orders o USING(customer_id) GROUP BY c.customer_id
)
SELECT * FROM counts WHERE order_count > (SELECT AVG(order_count::numeric) FROM counts);

-- IQ006
WITH ranked AS (
 SELECT o.*, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY ordered_at DESC, order_id DESC) rn
 FROM orders o
)
SELECT * FROM ranked WHERE rn=1;

-- IQ007
SELECT e.employee_id,e.employee_name,COUNT(DISTINCT o.customer_id) customers_served
FROM employees e LEFT JOIN orders o ON o.employee_id=e.employee_id AND o.status='completed'
GROUP BY e.employee_id,e.employee_name;

-- IQ008
WITH product_revenue AS (
 SELECT p.product_id,p.product_name,p.category,
        COALESCE(SUM(oi.quantity*oi.unit_price_paise) FILTER(WHERE o.status='completed'),0) revenue_paise
 FROM products p LEFT JOIN order_items oi USING(product_id) LEFT JOIN orders o USING(order_id)
 GROUP BY p.product_id,p.product_name,p.category
)
SELECT *,SUM(revenue_paise) OVER(PARTITION BY category) category_revenue_paise
FROM product_revenue;

-- IQ009
SELECT date_trunc('month',ordered_at)::date month_start,COUNT(*) order_count,
       SUM(stored_total_paise) gross_paise,SUM(refund_paise) refund_paise,
       SUM(stored_total_paise-refund_paise) net_paise
FROM orders GROUP BY 1 ORDER BY 1;

-- IQ010
SELECT region,
 SUM(stored_total_paise) FILTER(WHERE ordered_at >= '2026-08-01' AND ordered_at < '2026-09-01') aug_paise,
 SUM(stored_total_paise) FILTER(WHERE ordered_at >= '2026-07-01' AND ordered_at < '2026-08-01') jul_paise
FROM customers c JOIN orders o USING(customer_id) GROUP BY region
HAVING SUM(stored_total_paise) FILTER(WHERE ordered_at >= '2026-08-01' AND ordered_at < '2026-09-01')
     > SUM(stored_total_paise) FILTER(WHERE ordered_at >= '2026-07-01' AND ordered_at < '2026-08-01');

-- IQ011
WITH category_orders AS (
 SELECT p.category,o.order_id,SUM(oi.quantity*oi.unit_price_paise) total_paise
 FROM orders o JOIN order_items oi USING(order_id) JOIN products p USING(product_id)
 WHERE o.status='completed' GROUP BY p.category,o.order_id
)
SELECT category,COUNT(*) orders,AVG(total_paise) avg_order_paise
FROM category_orders GROUP BY category HAVING COUNT(*)>=5 AND AVG(total_paise)>150000;

-- IQ012
SELECT o.customer_id,COUNT(DISTINCT p.category) categories
FROM orders o JOIN order_items oi USING(order_id) JOIN products p USING(product_id)
WHERE o.status='completed' GROUP BY o.customer_id HAVING COUNT(DISTINCT p.category)>=3;

-- IQ013
WITH counts AS (SELECT status,COUNT(*) n FROM orders GROUP BY status)
SELECT status,n,ROUND(100.0*n/SUM(n) OVER(),2) pct FROM counts ORDER BY status;

-- IQ014
WITH pr AS (
 SELECT p.product_id,p.product_name,p.category,
        SUM(oi.quantity*oi.unit_price_paise) revenue_paise
 FROM products p JOIN order_items oi USING(product_id) JOIN orders o USING(order_id)
 WHERE o.status='completed' GROUP BY p.product_id,p.product_name,p.category
)
SELECT *,ROUND(100.0*revenue_paise/NULLIF(SUM(revenue_paise) OVER(PARTITION BY category),0),2) category_pct
FROM pr;

-- IQ015
WITH daily AS (
 SELECT ordered_at::date d,SUM(stored_total_paise) revenue_paise FROM orders WHERE status='completed' GROUP BY 1
), x AS (
 SELECT *,AVG(revenue_paise) OVER(ORDER BY d ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING) prior7_avg
 FROM daily
)
SELECT * FROM x WHERE revenue_paise >= 1.30*prior7_avg;

-- IQ016: every active employee has at least one completed order.
SELECT d.* FROM departments d
WHERE NOT EXISTS (
 SELECT 1 FROM employees e WHERE e.department_id=d.department_id AND e.active
 AND NOT EXISTS (SELECT 1 FROM orders o WHERE o.employee_id=e.employee_id AND o.status='completed')
);

-- IQ017
SELECT p.* FROM products p
WHERE unit_price_paise > (SELECT AVG(p2.unit_price_paise) FROM products p2 WHERE p2.category=p.category);

-- IQ018
WITH months AS (SELECT DISTINCT date_trunc('month',ordered_at) m FROM orders), cm AS (
 SELECT DISTINCT customer_id,date_trunc('month',ordered_at) m FROM orders
)
SELECT c.customer_id FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM months m WHERE NOT EXISTS (
 SELECT 1 FROM cm WHERE cm.customer_id=c.customer_id AND cm.m=m.m));

-- IQ019
SELECT * FROM (
 SELECT o.*,AVG(stored_total_paise) OVER(PARTITION BY customer_id) customer_avg
 FROM orders o
) x WHERE stored_total_paise>customer_avg;

-- IQ020
SELECT e.employee_id FROM employees e
WHERE NOT EXISTS (SELECT 1 FROM required_products rp WHERE NOT EXISTS (
 SELECT 1 FROM orders o JOIN order_items oi USING(order_id)
 WHERE o.employee_id=e.employee_id AND o.status='completed' AND oi.product_id=rp.product_id));

-- IQ021
SELECT c.* FROM customers c WHERE NOT EXISTS (
 SELECT 1 FROM orders o WHERE o.customer_id=c.customer_id AND o.status='completed');

-- IQ022
WITH RECURSIVE org AS (
 SELECT employee_id,employee_name,manager_id,0 depth,ARRAY[employee_id] path
 FROM employees WHERE manager_id IS NULL
 UNION ALL
 SELECT e.employee_id,e.employee_name,e.manager_id,o.depth+1,o.path||e.employee_id
 FROM employees e JOIN org o ON e.manager_id=o.employee_id
 WHERE NOT e.employee_id=ANY(o.path)
)
SELECT * FROM org ORDER BY path;

-- IQ023
SELECT * FROM (
 SELECT e.*,DENSE_RANK() OVER(PARTITION BY department_id ORDER BY salary_paise DESC) rnk
 FROM employees e
) x WHERE rnk=2;

-- IQ024
SELECT o.order_id FROM orders o JOIN order_items oi USING(order_id)
JOIN bundle_products b ON b.product_id=oi.product_id AND b.bundle_code='STARTER'
GROUP BY o.order_id HAVING COUNT(DISTINCT b.product_id)=(SELECT COUNT(*) FROM bundle_products WHERE bundle_code='STARTER');

-- IQ025
WITH s AS (SELECT employee_id,SUM(stored_total_paise) revenue_paise FROM orders WHERE status='completed' GROUP BY employee_id)
SELECT e.employee_id,e.employee_name,e.department_id,COALESCE(s.revenue_paise,0) revenue_paise,
 DENSE_RANK() OVER(PARTITION BY e.department_id ORDER BY COALESCE(s.revenue_paise,0) DESC) rnk
FROM employees e LEFT JOIN s USING(employee_id);

-- IQ026
SELECT customer_id,order_id,ordered_at,stored_total_paise,
 SUM(stored_total_paise) OVER(PARTITION BY customer_id ORDER BY ordered_at,order_id ROWS UNBOUNDED PRECEDING) running_paise
FROM orders WHERE status='completed';

-- IQ027
SELECT customer_id,order_id,stored_total_paise,
 stored_total_paise-LAG(stored_total_paise) OVER(PARTITION BY customer_id ORDER BY ordered_at,order_id) diff_paise
FROM orders;

-- IQ028
WITH pr AS (
 SELECT p.category,p.product_id,p.product_name,SUM(oi.quantity*oi.unit_price_paise) revenue_paise
 FROM products p JOIN order_items oi USING(product_id) JOIN orders o USING(order_id)
 WHERE o.status='completed' GROUP BY p.category,p.product_id,p.product_name
), r AS (SELECT *,DENSE_RANK() OVER(PARTITION BY category ORDER BY revenue_paise DESC) rnk FROM pr)
SELECT * FROM r WHERE rnk<=3;

-- IQ029
WITH calendar AS (
 SELECT generate_series((SELECT min(ordered_at)::date FROM orders),(SELECT max(ordered_at)::date FROM orders),'1 day')::date d
), daily AS (
 SELECT ordered_at::date d,SUM(stored_total_paise) FILTER(WHERE status='completed') revenue_paise FROM orders GROUP BY 1
)
SELECT c.d,COALESCE(d.revenue_paise,0) revenue_paise,
 SUM(COALESCE(d.revenue_paise,0)) OVER(ORDER BY c.d ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) rolling30_paise
FROM calendar c LEFT JOIN daily d USING(d);

-- IQ030
SELECT * FROM (
 SELECT o.*,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY ordered_at,order_id) first_rn,
 ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY ordered_at DESC,order_id DESC) last_rn
 FROM orders o
) x WHERE first_rn=1 OR last_rn=1;

-- IQ031
SELECT c.region,percentile_cont(0.5) WITHIN GROUP(ORDER BY o.stored_total_paise) median_order_paise
FROM orders o JOIN customers c USING(customer_id) GROUP BY c.region;

-- IQ032
WITH s AS (
 SELECT c.customer_id,COALESCE(SUM(o.stored_total_paise) FILTER(WHERE o.status='completed'),0) spend_paise
 FROM customers c LEFT JOIN orders o USING(customer_id) GROUP BY c.customer_id
)
SELECT *,NTILE(4) OVER(ORDER BY spend_paise DESC,customer_id) quartile FROM s;

-- IQ033
WITH x AS (
 SELECT *,SUM(quantity_delta) OVER(PARTITION BY product_id,location_code ORDER BY moved_at,movement_id) balance
 FROM stock_movements
), y AS (SELECT *,ROW_NUMBER() OVER(PARTITION BY product_id,location_code ORDER BY moved_at,movement_id) rn FROM x WHERE balance<0)
SELECT * FROM y WHERE rn=1;

-- IQ034
WITH m AS (
 SELECT date_trunc('month',ordered_at)::date month_start,SUM(stored_total_paise) revenue_paise
 FROM orders WHERE status='completed' GROUP BY 1
)
SELECT *,LAG(revenue_paise,12) OVER(ORDER BY month_start) prior_year_paise FROM m;

-- IQ035
WITH d AS (SELECT DISTINCT user_id,login_at::date login_date FROM login_events),
 x AS (SELECT *,login_date-(ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY login_date))::int island_key FROM d)
SELECT user_id,MIN(login_date) starts_on,MAX(login_date) ends_on,COUNT(*) days
FROM x GROUP BY user_id,island_key ORDER BY user_id,starts_on;

-- IQ036: touching/overlapping intervals with running previous maximum.
WITH x AS (
 SELECT s.*,MAX(COALESCE(ends_on,'infinity'::date)) OVER(PARTITION BY customer_id,plan_code ORDER BY starts_on,subscription_id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) prev_max_end
 FROM subscriptions s
), b AS (
 SELECT *,CASE WHEN prev_max_end IS NULL OR starts_on>prev_max_end+1 THEN 1 ELSE 0 END boundary
 FROM x
), g AS (
 SELECT *,SUM(boundary) OVER(PARTITION BY customer_id,plan_code ORDER BY starts_on,subscription_id) grp FROM b
)
SELECT customer_id,plan_code,MIN(starts_on),MAX(ends_on) FROM g GROUP BY customer_id,plan_code,grp;

-- IQ037
WITH x AS (SELECT order_number,LAG(order_number) OVER(ORDER BY order_number) prev_no FROM orders)
SELECT prev_no+1 gap_start,order_number-1 gap_end FROM x WHERE order_number>prev_no+1;

-- IQ038
WITH daily AS (
 SELECT ordered_at::date d,SUM(stored_total_paise) revenue_paise FROM orders WHERE status='completed' GROUP BY 1
), qualifying AS (SELECT * FROM daily WHERE revenue_paise>1000000),
 x AS (SELECT *,d-(ROW_NUMBER() OVER(ORDER BY d))::int grp FROM qualifying)
SELECT MIN(d) starts_on,MAX(d) ends_on,COUNT(*) days FROM x GROUP BY grp HAVING COUNT(*)>=3;

-- IQ039
SELECT lower(btrim(email)) normalized_email,COUNT(*) n,array_agg(customer_id ORDER BY customer_id) customer_ids
FROM customers WHERE email IS NOT NULL GROUP BY lower(btrim(email)) HAVING COUNT(*)>1;

-- IQ040
WITH lines AS (SELECT order_id,SUM(quantity*unit_price_paise) calculated_paise FROM order_items GROUP BY order_id)
SELECT o.order_id,o.stored_total_paise,l.calculated_paise FROM orders o JOIN lines l USING(order_id)
WHERE o.stored_total_paise<>l.calculated_paise;

-- IQ041
SELECT s.* FROM staging_orders s LEFT JOIN customers c ON c.customer_id=s.customer_id
WHERE s.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- IQ042
SELECT a.subscription_id,b.subscription_id FROM subscriptions a JOIN subscriptions b
 ON a.customer_id=b.customer_id AND a.plan_code=b.plan_code AND a.subscription_id<b.subscription_id
 AND daterange(a.starts_on,COALESCE(a.ends_on,'infinity'::date),'[]') && daterange(b.starts_on,COALESCE(b.ends_on,'infinity'::date),'[]')
WHERE a.status='active' AND b.status='active';

-- IQ043
SELECT * FROM orders
WHERE (ordered_at,order_id) < (:cursor_ordered_at,:cursor_order_id)
ORDER BY ordered_at DESC,order_id DESC LIMIT :page_size;

-- IQ047 skeleton: build each metric at customer grain, then join.
WITH order_metrics AS (
 SELECT customer_id,MAX(ordered_at) last_order_at,COUNT(*) FILTER(WHERE status='completed') completed_orders,
 SUM(stored_total_paise) FILTER(WHERE status='completed' AND ordered_at>=CURRENT_DATE-INTERVAL '90 days') spend90_paise,
 SUM(refund_paise)::numeric/NULLIF(SUM(stored_total_paise),0) refund_rate
 FROM orders GROUP BY customer_id
)
SELECT c.customer_id,c.customer_name,om.*,
 CASE WHEN om.last_order_at<CURRENT_DATE-INTERVAL '180 days' THEN 'HIGH'
      WHEN COALESCE(om.refund_rate,0)>0.20 THEN 'MEDIUM' ELSE 'LOW' END risk_tier
FROM customers c LEFT JOIN order_metrics om USING(customer_id);

-- IQ048 skeleton: product spine plus month spine preserves unsold products.
WITH months AS (
 SELECT generate_series(date_trunc('month',(SELECT min(ordered_at) FROM orders)),date_trunc('month',(SELECT max(ordered_at) FROM orders)),'1 month')::date month_start
), spine AS (SELECT p.product_id,p.product_name,p.category,m.month_start FROM products p CROSS JOIN months m),
 facts AS (
 SELECT oi.product_id,date_trunc('month',o.ordered_at)::date month_start,
 SUM(oi.quantity*oi.unit_price_paise) revenue_paise,
 SUM(oi.quantity*(oi.unit_price_paise-p.unit_cost_paise)) margin_paise
 FROM orders o JOIN order_items oi USING(order_id) JOIN products p USING(product_id)
 WHERE o.status='completed' GROUP BY oi.product_id,2
), x AS (
 SELECT s.*,COALESCE(f.revenue_paise,0) revenue_paise,COALESCE(f.margin_paise,0) margin_paise
 FROM spine s LEFT JOIN facts f USING(product_id,month_start)
)
SELECT *,DENSE_RANK() OVER(PARTITION BY category,month_start ORDER BY revenue_paise DESC) category_rank,
 revenue_paise-LAG(revenue_paise) OVER(PARTITION BY product_id ORDER BY month_start) mom_change_paise
FROM x ORDER BY month_start,category,category_rank,product_id;
