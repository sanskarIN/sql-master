-- Selected reference solutions
-- Q1
SELECT customer_id, customer_name, city
FROM customers
ORDER BY customer_id;

-- Q2
SELECT customer_id, customer_name
FROM customers
WHERE city IS NULL
ORDER BY customer_id;

-- Q3
SELECT status, COUNT(*) AS order_count
FROM orders
GROUP BY status
ORDER BY status;

-- Q4
SELECT c.customer_id, c.customer_name, COUNT(o.order_id) AS order_count
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY c.customer_id;

-- Q5
SELECT c.customer_id, c.customer_name
FROM customers AS c
WHERE NOT EXISTS (
  SELECT 1 FROM orders AS o WHERE o.customer_id = c.customer_id
)
ORDER BY c.customer_id;

-- Q6
SELECT c.customer_id, c.customer_name,
       COALESCE(SUM(o.total_paise), 0) AS paid_paise
FROM customers AS c
LEFT JOIN orders AS o
  ON o.customer_id = c.customer_id
 AND o.status = 'paid'
GROUP BY c.customer_id, c.customer_name
ORDER BY paid_paise DESC, c.customer_id;

-- Q7 (PostgreSQL window-function solution)
WITH ranked AS (
  SELECT o.*,
         ROW_NUMBER() OVER (
           PARTITION BY customer_id
           ORDER BY order_date DESC, order_id DESC
         ) AS rn
  FROM orders AS o
)
SELECT order_id, customer_id, order_date, status, total_paise
FROM ranked
WHERE rn = 1
ORDER BY customer_id;

-- Q8
SELECT p.product_id, p.product_name
FROM products AS p
WHERE NOT EXISTS (
  SELECT 1 FROM order_items AS oi WHERE oi.product_id = p.product_id
)
ORDER BY p.product_id;

-- Q9
SELECT c.city, SUM(o.total_paise) AS paid_paise
FROM customers AS c
JOIN orders AS o ON o.customer_id = c.customer_id
WHERE o.status = 'paid'
GROUP BY c.city
HAVING SUM(o.total_paise) > 90000
ORDER BY paid_paise DESC, c.city NULLS LAST;

-- Q10: Aggregate order-level totals before joining item-grain rows, or aggregate
-- item facts at item grain. Never sum an order header value once per item row.
