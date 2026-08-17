SET search_path = lab, public;

-- Q12. Price valid at each order-line event time. Half-open interval [valid_from, valid_to).
SELECT o.order_id,o.ordered_at,l.line_no,p.sku,h.price_paise AS catalog_price_paise,
       l.unit_price_paise AS charged_price_paise
FROM sales_order o
JOIN order_line l USING(order_id)
JOIN product p USING(product_id)
JOIN LATERAL (
  SELECT ph.*
  FROM product_price_history ph
  WHERE ph.product_id=l.product_id
    AND ph.valid_from <= o.ordered_at
    AND (ph.valid_to IS NULL OR o.ordered_at < ph.valid_to)
  ORDER BY ph.valid_from DESC,ph.price_version_id DESC
  LIMIT 1
) h ON true
ORDER BY o.order_id,l.line_no;

-- Q13. Detect overlapping price intervals.
SELECT a.product_id,a.price_version_id AS left_version,b.price_version_id AS right_version
FROM product_price_history a
JOIN product_price_history b
  ON b.product_id=a.product_id
 AND b.price_version_id>a.price_version_id
 AND tstzrange(a.valid_from,a.valid_to,'[)') && tstzrange(b.valid_from,b.valid_to,'[)');

-- Q14. Recursive organization traversal with path and cycle protection.
WITH RECURSIVE org AS (
  SELECT e.employee_id,e.employee_code,e.employee_name,e.manager_id,
         0 AS depth,ARRAY[e.employee_id] AS path,false AS is_cycle
  FROM employee e WHERE e.manager_id IS NULL
  UNION ALL
  SELECT c.employee_id,c.employee_code,c.employee_name,c.manager_id,
         p.depth+1,p.path||c.employee_id,c.employee_id=ANY(p.path)
  FROM org p JOIN employee c ON c.manager_id=p.employee_id
  WHERE NOT p.is_cycle AND p.depth < 20
)
SELECT * FROM org ORDER BY path;

-- Q15. All descendants of one manager with distance.
WITH RECURSIVE descendants AS (
  SELECT e.employee_id,e.manager_id,0 AS distance,ARRAY[e.employee_id] path
  FROM employee e WHERE e.employee_code='ENG'
  UNION ALL
  SELECT c.employee_id,c.manager_id,d.distance+1,d.path||c.employee_id
  FROM descendants d JOIN employee c ON c.manager_id=d.employee_id
  WHERE NOT c.employee_id=ANY(d.path) AND d.distance < 20
)
SELECT d.distance,e.employee_code,e.employee_name
FROM descendants d JOIN employee e USING(employee_id)
ORDER BY d.distance,e.employee_code;

-- Q16. Relational division: users who performed every required event.
WITH required(event_name) AS (VALUES ('view'),('add_to_cart'))
SELECT u.account_id,u.user_id,u.user_code
FROM app_user u
WHERE NOT EXISTS (
  SELECT 1 FROM required r
  WHERE NOT EXISTS (
    SELECT 1 FROM event_log e
    WHERE e.account_id=u.account_id AND e.user_id=u.user_id
      AND e.event_name=r.event_name
  )
)
ORDER BY u.account_id,u.user_id;
