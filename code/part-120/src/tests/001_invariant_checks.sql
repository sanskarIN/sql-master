SET search_path=final120,public;

-- Every query should return zero rows on valid data.
SELECT * FROM order_line_reconciliation WHERE difference_paise<>0;
SELECT * FROM ledger_balance_check WHERE net_paise<>0;
SELECT * FROM stock_balance WHERE reserved_qty>on_hand_qty OR reserved_qty<0 OR on_hand_qty<0;

-- Active booking overlap is prevented by the exclusion constraint; this defensive query should return zero.
SELECT a.booking_id left_id,b.booking_id right_id
FROM booking a JOIN booking b
 ON a.booking_id<b.booking_id AND a.resource_key=b.resource_key
 AND a.status IN ('HELD','CONFIRMED') AND b.status IN ('HELD','CONFIRMED')
 AND tstzrange(a.starts_at,a.ends_at,'[)') && tstzrange(b.starts_at,b.ends_at,'[)');

-- Idempotency identities are unique by constraints; detect conflicting imported data defensively.
SELECT idempotency_key,COUNT(DISTINCT request_hash)
FROM sales_order GROUP BY idempotency_key HAVING COUNT(DISTINCT request_hash)>1;
