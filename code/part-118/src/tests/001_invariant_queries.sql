SET search_path = lab, public;

-- Each query should return zero rows on valid seed data.

-- Duplicate business user identities.
SELECT account_id,user_code,COUNT(*)
FROM app_user GROUP BY account_id,user_code HAVING COUNT(*)<>1;

-- Order totals that do not reconcile to lines (cancelled orders are still arithmetically valid).
SELECT o.order_id,o.total_paise,COALESCE(SUM(l.quantity*l.unit_price_paise),0) line_total
FROM sales_order o LEFT JOIN order_line l USING(order_id)
GROUP BY o.order_id,o.total_paise
HAVING o.total_paise<>COALESCE(SUM(l.quantity*l.unit_price_paise),0);

-- Overlapping temporal prices.
SELECT a.product_id,a.price_version_id,b.price_version_id
FROM product_price_history a
JOIN product_price_history b
  ON b.product_id=a.product_id
 AND b.price_version_id>a.price_version_id
 AND tstzrange(a.valid_from,a.valid_to,'[)') && tstzrange(b.valid_from,b.valid_to,'[)');

-- Events that cross account/user scope.
SELECT e.event_id FROM event_log e
LEFT JOIN app_user u ON u.account_id=e.account_id AND u.user_id=e.user_id
WHERE u.user_id IS NULL;

-- Conflicting command key cannot coexist because of PK; this checks accidental duplicates after imports.
SELECT account_id,idempotency_key,COUNT(DISTINCT request_hash)
FROM api_command GROUP BY account_id,idempotency_key
HAVING COUNT(DISTINCT request_hash)>1;
