-- Executable SQL assertions. The script raises an error on failure.
BEGIN;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM inventory.stock_balance WHERE reserved_qty > on_hand_qty) THEN
    RAISE EXCEPTION 'reserved stock exceeds on hand';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM ledger.v_unbalanced_posted_entry) THEN
    RAISE EXCEPTION 'posted journal is unbalanced';
  END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM commerce.sales_order o
    LEFT JOIN (
      SELECT tenant_id,order_id,SUM(line_total_paise) subtotal
      FROM commerce.sales_order_line GROUP BY tenant_id,order_id
    ) l USING (tenant_id,order_id)
    WHERE COALESCE(l.subtotal,0) <> o.subtotal_paise
  ) THEN RAISE EXCEPTION 'order line subtotal mismatch'; END IF;
END $$;

DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM booking.reservation a
    JOIN booking.reservation b
      ON a.tenant_id=b.tenant_id AND a.resource_id=b.resource_id
     AND a.reservation_id < b.reservation_id
     AND tstzrange(a.starts_at,a.ends_at,'[)') && tstzrange(b.starts_at,b.ends_at,'[)')
    WHERE a.status IN ('HELD','CONFIRMED') AND b.status IN ('HELD','CONFIRMED')
  ) THEN RAISE EXCEPTION 'active reservation overlap'; END IF;
END $$;

ROLLBACK;
SELECT 'ALL SQL INVARIANT TESTS PASSED' AS result;
