SET search_path = lab, public;

-- Q1. Peer-aware running revenue. ROWS advances one physical row; RANGE treats peers together.
SELECT ordered_at, order_id, total_paise,
       SUM(total_paise) OVER (
         ORDER BY ordered_at, order_id
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_paise
FROM sales_order
WHERE status='PAID'
ORDER BY ordered_at, order_id;

-- Q2. Last non-null-like state pattern using a staged sequence.
WITH sequenced AS (
  SELECT e.*,
         COUNT(page_code) OVER (
           PARTITION BY account_id, user_id
           ORDER BY event_time, event_id
         ) AS page_group
  FROM event_log e
), carried AS (
  SELECT sequenced.*,
         MAX(page_code) OVER (
           PARTITION BY account_id, user_id, page_group
         ) AS carried_page
  FROM sequenced
)
SELECT account_id,user_id,event_time,event_name,page_code,carried_page
FROM carried
ORDER BY account_id,user_id,event_time,event_id;

-- Q3. Top two paid orders per account, exactly two rows unless fewer exist.
WITH ranked AS (
  SELECT o.*,
         ROW_NUMBER() OVER (
           PARTITION BY account_id
           ORDER BY total_paise DESC, ordered_at DESC, order_id DESC
         ) AS rn
  FROM sales_order o
  WHERE status='PAID'
)
SELECT * FROM ranked WHERE rn <= 2 ORDER BY account_id,rn;

-- Q4. Tie-preserving top price groups.
SELECT *
FROM (
  SELECT o.*,
         DENSE_RANK() OVER (
           PARTITION BY account_id
           ORDER BY total_paise DESC
         ) AS price_rank
  FROM sales_order o
  WHERE status='PAID'
) x
WHERE price_rank <= 2;

-- Q5. Seven-day moving paid revenue on a daily spine.
WITH bounds AS (
  SELECT min(ordered_at::date) d0, max(ordered_at::date) d1 FROM sales_order
), spine AS (
  SELECT d::date AS day
  FROM bounds, generate_series(d0,d1,interval '1 day') g(d)
), daily AS (
  SELECT ordered_at::date AS day, SUM(total_paise) AS paid_paise
  FROM sales_order WHERE status='PAID' GROUP BY ordered_at::date
)
SELECT s.day, COALESCE(d.paid_paise,0) paid_paise,
       SUM(COALESCE(d.paid_paise,0)) OVER (
         ORDER BY s.day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ) AS paid_7d_paise
FROM spine s LEFT JOIN daily d USING(day)
ORDER BY s.day;

-- Q6. Percentile and distribution questions.
SELECT account_id, order_id, total_paise,
       PERCENT_RANK() OVER (PARTITION BY account_id ORDER BY total_paise) AS percent_rank,
       CUME_DIST()    OVER (PARTITION BY account_id ORDER BY total_paise) AS cume_dist,
       NTILE(4)       OVER (PARTITION BY account_id ORDER BY total_paise,order_id) AS quartile
FROM sales_order
WHERE status='PAID';

-- Q7. Change detection with explicit unique order.
WITH x AS (
  SELECT e.*,
         LAG(event_name) OVER (
           PARTITION BY account_id,user_id
           ORDER BY event_time,event_id
         ) AS previous_event
  FROM event_log e
)
SELECT * FROM x WHERE previous_event IS DISTINCT FROM event_name
ORDER BY account_id,user_id,event_time,event_id;
