-- Invariant and reconciliation checks
SET search_path = inventory, public;

-- 1. No balance is negative and reservations never exceed stock.
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM stock_balances WHERE on_hand_qty<0 OR reserved_qty<0 OR reserved_qty>on_hand_qty)
 THEN RAISE EXCEPTION 'invalid stock balance'; END IF;
END $$;

-- 2. Every transfer dispatch quantity is bounded by request and receipt by dispatch.
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM transfer_lines WHERE dispatched_qty>requested_qty OR received_qty>dispatched_qty)
 THEN RAISE EXCEPTION 'invalid transfer quantities'; END IF;
END $$;

-- 3. Purchase-order quantities reconcile.
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM purchase_order_lines WHERE received_qty+cancelled_qty>ordered_qty)
 THEN RAISE EXCEPTION 'invalid PO quantities'; END IF;
END $$;

-- 4. Posted receipts have a posting timestamp.
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM receipts WHERE state='POSTED' AND posted_at IS NULL)
 THEN RAISE EXCEPTION 'posted receipt missing timestamp'; END IF;
END $$;

-- 5. Stock ledger and balance projection agree.
DO $$ BEGIN
 IF EXISTS (
   WITH l AS (SELECT product_id,bin_id,lot_id,SUM(quantity_delta) q FROM stock_movements GROUP BY 1,2,3)
   SELECT 1 FROM l FULL JOIN stock_balances sb
    ON sb.product_id=l.product_id AND sb.bin_id=l.bin_id AND sb.lot_id IS NOT DISTINCT FROM l.lot_id
   WHERE COALESCE(l.q,0)<>COALESCE(sb.on_hand_qty,0)
 ) THEN RAISE EXCEPTION 'ledger balance drift'; END IF;
END $$;

-- 6. Active reservations reconcile to the balance projection.
DO $$ BEGIN
 IF EXISTS (
   WITH e AS (
     SELECT rl.product_id,rl.bin_id,rl.lot_id,
       SUM(rl.reserved_qty-rl.fulfilled_qty-rl.released_qty) q
     FROM reservation_lines rl JOIN reservation_headers rh USING(reservation_id)
     WHERE rh.state IN ('ACTIVE','PARTIALLY_FULFILLED') GROUP BY 1,2,3
   )
   SELECT 1 FROM stock_balances sb LEFT JOIN e
    ON e.product_id=sb.product_id AND e.bin_id=sb.bin_id AND e.lot_id IS NOT DISTINCT FROM sb.lot_id
   WHERE sb.reserved_qty<>COALESCE(e.q,0)
 ) THEN RAISE EXCEPTION 'reservation drift'; END IF;
END $$;
