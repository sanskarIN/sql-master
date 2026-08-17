-- Receiving, counting, reconciliation, and security
SET search_path = inventory, public;

-- Posting a receipt must lock the PO and all affected balances in stable order.
-- Over-receipt is rejected here; policy-specific tolerances should be explicit columns.
CREATE OR REPLACE FUNCTION post_receipt(p_receipt_id BIGINT,p_command_id UUID,p_actor BIGINT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path=inventory,pg_temp AS $$
DECLARE r RECORD; l RECORD; po_line RECORD; v_wh BIGINT;
BEGIN
  SELECT * INTO r FROM receipts WHERE receipt_id=p_receipt_id FOR UPDATE;
  IF r.state='POSTED' THEN RETURN; END IF;
  IF r.state<>'OPEN' THEN RAISE EXCEPTION 'receipt not open'; END IF;
  v_wh:=r.warehouse_id;
  FOR l IN SELECT * FROM receipt_lines WHERE receipt_id=p_receipt_id ORDER BY product_id,destination_bin_id,lot_id FOR UPDATE LOOP
    IF l.purchase_order_line_id IS NOT NULL THEN
      SELECT * INTO po_line FROM purchase_order_lines
      WHERE purchase_order_line_id=l.purchase_order_line_id FOR UPDATE;
      IF po_line.received_qty+l.accepted_qty>po_line.ordered_qty-po_line.cancelled_qty
      THEN RAISE EXCEPTION 'over receipt'; END IF;
      UPDATE purchase_order_lines SET received_qty=received_qty+l.accepted_qty
      WHERE purchase_order_line_id=l.purchase_order_line_id;
    END IF;
    PERFORM apply_stock_delta(p_command_id,l.product_id,v_wh,l.destination_bin_id,l.lot_id,
      'RECEIPT',l.accepted_qty,'RECEIPT',p_receipt_id,r.received_at,p_actor,'ACCEPTED');
  END LOOP;
  UPDATE receipts SET state='POSTED',posted_at=CURRENT_TIMESTAMP WHERE receipt_id=p_receipt_id;
  UPDATE purchase_orders po SET state=CASE
      WHEN NOT EXISTS (SELECT 1 FROM purchase_order_lines x WHERE x.purchase_order_id=po.purchase_order_id
        AND x.received_qty+x.cancelled_qty<x.ordered_qty) THEN 'RECEIVED'::po_state
      ELSE 'PARTIALLY_RECEIVED'::po_state END
  WHERE po.purchase_order_id=r.purchase_order_id;
  INSERT INTO outbox_events(event_id,aggregate_type,aggregate_id,event_type,payload_json)
  VALUES(gen_random_uuid(),'RECEIPT',p_receipt_id,'RECEIPT.POSTED',jsonb_build_object('receipt_id',p_receipt_id));
END $$;

-- Workers claim planned count lines without duplicate assignment.
WITH claimed AS (
  SELECT ccl.count_line_id
  FROM cycle_count_lines ccl JOIN cycle_counts cc USING(count_id)
  WHERE cc.state='COUNTING' AND ccl.counted_qty IS NULL
  ORDER BY cc.planned_at,ccl.bin_id,ccl.product_id,ccl.count_line_id
  FOR UPDATE OF ccl SKIP LOCKED LIMIT :batch_size
)
SELECT ccl.* FROM cycle_count_lines ccl JOIN claimed USING(count_line_id);

-- Ledger-to-balance reconciliation. Differences are incidents, not automatic truth changes.
WITH ledger AS (
  SELECT product_id,bin_id,lot_id,SUM(quantity_delta) AS ledger_qty
  FROM stock_movements GROUP BY product_id,bin_id,lot_id
)
SELECT COALESCE(l.product_id,sb.product_id) AS product_id,
       COALESCE(l.bin_id,sb.bin_id) AS bin_id,
       COALESCE(l.lot_id,sb.lot_id) AS lot_id,
       COALESCE(l.ledger_qty,0) AS ledger_qty,
       COALESCE(sb.on_hand_qty,0) AS balance_qty,
       COALESCE(l.ledger_qty,0)-COALESCE(sb.on_hand_qty,0) AS drift_qty
FROM ledger l FULL OUTER JOIN stock_balances sb
  ON sb.product_id=l.product_id AND sb.bin_id=l.bin_id
 AND sb.lot_id IS NOT DISTINCT FROM l.lot_id
WHERE COALESCE(l.ledger_qty,0)<>COALESCE(sb.on_hand_qty,0);

-- Rebuild reservation projection for a bounded product/bin range.
WITH expected AS (
  SELECT rl.product_id,rl.bin_id,rl.lot_id,
         SUM(rl.reserved_qty-rl.fulfilled_qty-rl.released_qty) AS expected_reserved
  FROM reservation_lines rl JOIN reservation_headers rh USING(reservation_id)
  WHERE rh.state IN ('ACTIVE','PARTIALLY_FULFILLED')
    AND rl.product_id BETWEEN :from_product AND :to_product
  GROUP BY rl.product_id,rl.bin_id,rl.lot_id
)
SELECT sb.product_id,sb.bin_id,sb.lot_id,sb.reserved_qty,
       COALESCE(e.expected_reserved,0) AS expected_reserved
FROM stock_balances sb LEFT JOIN expected e
 ON e.product_id=sb.product_id AND e.bin_id=sb.bin_id
AND e.lot_id IS NOT DISTINCT FROM sb.lot_id
WHERE sb.product_id BETWEEN :from_product AND :to_product
  AND sb.reserved_qty<>COALESCE(e.expected_reserved,0);

-- Example least-privilege boundary.
REVOKE ALL ON ALL TABLES IN SCHEMA inventory FROM PUBLIC;
GRANT USAGE ON SCHEMA inventory TO inventory_reader,inventory_writer;
GRANT SELECT ON products,warehouses,bins,inventory_lots,stock_balances,reorder_policies TO inventory_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA inventory TO inventory_writer;
GRANT EXECUTE ON FUNCTION reserve_product(VARCHAR,CHAR,VARCHAR,BIGINT,BIGINT,BIGINT,NUMERIC,TIMESTAMPTZ)
  TO inventory_writer;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
-- Add tenant/company keys before enabling a real multi-tenant RLS policy.
