-- 1. Customers with no orders
SELECT c.customer_id, c.name
FROM customer c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;

-- 2. Latest order per customer
WITH ranked AS (
  SELECT o.*, ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY ordered_at DESC, order_id DESC
  ) AS rn
  FROM orders o
)
SELECT customer_id, order_id, total_paise
FROM ranked
WHERE rn = 1
ORDER BY customer_id;

-- 3. Running revenue
SELECT order_id, ordered_at, total_paise,
       SUM(total_paise) OVER (
         ORDER BY ordered_at, order_id
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_revenue_paise
FROM orders
ORDER BY ordered_at, order_id;
