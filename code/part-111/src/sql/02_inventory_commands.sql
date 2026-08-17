-- Transactional inventory commands
SET search_path = inventory, public;

-- The stock ledger is authoritative. stock_balances is a transactionally maintained
-- projection used to enforce non-negative stock and reservation capacity.
CREATE OR REPLACE FUNCTION apply_stock_delta(
    p_command_id UUID,
    p_product_id BIGINT,
    p_warehouse_id BIGINT,
    p_bin_id BIGINT,
    p_lot_id BIGINT,
    p_kind movement_kind,
    p_delta NUMERIC,
    p_reference_type VARCHAR,
    p_reference_id BIGINT,
    p_occurred_at TIMESTAMPTZ,
    p_actor_id BIGINT,
    p_reason VARCHAR DEFAULT NULL
) RETURNS BIGINT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = inventory, pg_temp AS $$
DECLARE v_movement_id BIGINT; v_on_hand NUMERIC; v_reserved NUMERIC;
BEGIN
    IF p_delta = 0 THEN RAISE EXCEPTION 'zero movement'; END IF;
    IF NOT EXISTS (SELECT 1 FROM bins b WHERE b.bin_id=p_bin_id AND b.warehouse_id=p_warehouse_id AND b.active)
       THEN RAISE EXCEPTION 'bin warehouse mismatch or inactive'; END IF;

    INSERT INTO stock_balances(product_id,bin_id,lot_id,on_hand_qty,reserved_qty)
    VALUES (p_product_id,p_bin_id,p_lot_id,0,0)
    ON CONFLICT DO NOTHING;

    SELECT on_hand_qty,reserved_qty INTO v_on_hand,v_reserved
    FROM stock_balances
    WHERE product_id=p_product_id AND bin_id=p_bin_id AND lot_id IS NOT DISTINCT FROM p_lot_id
    FOR UPDATE;

    IF v_on_hand + p_delta < v_reserved THEN
        RAISE EXCEPTION 'insufficient unreserved stock';
    END IF;

    INSERT INTO stock_movements(command_id,occurred_at,product_id,warehouse_id,bin_id,lot_id,
        movement_kind,quantity_delta,reference_type,reference_id,reason_code,actor_id)
    VALUES (p_command_id,p_occurred_at,p_product_id,p_warehouse_id,p_bin_id,p_lot_id,
        p_kind,p_delta,p_reference_type,p_reference_id,p_reason,p_actor_id)
    ON CONFLICT (command_id,product_id,bin_id,COALESCE(lot_id,0),movement_kind)
    DO NOTHING
    RETURNING movement_id INTO v_movement_id;

    IF v_movement_id IS NULL THEN
        SELECT movement_id INTO v_movement_id FROM stock_movements
        WHERE command_id=p_command_id AND product_id=p_product_id AND bin_id=p_bin_id
          AND lot_id IS NOT DISTINCT FROM p_lot_id AND movement_kind=p_kind;
        RETURN v_movement_id;
    END IF;

    UPDATE stock_balances
    SET on_hand_qty=on_hand_qty+p_delta, version_no=version_no+1,
        updated_at=CURRENT_TIMESTAMP
    WHERE product_id=p_product_id AND bin_id=p_bin_id
      AND lot_id IS NOT DISTINCT FROM p_lot_id;

    RETURN v_movement_id;
END $$;

-- FEFO reservation: lock candidate rows in deterministic expiry/bin order.
CREATE OR REPLACE FUNCTION reserve_product(
    p_request_key VARCHAR,
    p_request_hash CHAR(64),
    p_owner_type VARCHAR,
    p_owner_id BIGINT,
    p_warehouse_id BIGINT,
    p_product_id BIGINT,
    p_quantity NUMERIC,
    p_expires_at TIMESTAMPTZ
) RETURNS BIGINT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = inventory, pg_temp AS $$
DECLARE v_reservation_id BIGINT; v_remaining NUMERIC := p_quantity; r RECORD; v_take NUMERIC;
BEGIN
    IF p_quantity <= 0 OR p_expires_at <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'invalid reservation request';
    END IF;

    SELECT reservation_id INTO v_reservation_id
    FROM reservation_headers WHERE request_key=p_request_key;
    IF FOUND THEN
        IF (SELECT request_hash FROM reservation_headers WHERE reservation_id=v_reservation_id) <> p_request_hash
        THEN RAISE EXCEPTION 'idempotency conflict'; END IF;
        RETURN v_reservation_id;
    END IF;

    INSERT INTO reservation_headers(request_key,request_hash,owner_type,owner_id,warehouse_id,expires_at)
    VALUES (p_request_key,p_request_hash,p_owner_type,p_owner_id,p_warehouse_id,p_expires_at)
    RETURNING reservation_id INTO v_reservation_id;

    FOR r IN
        SELECT sb.product_id,sb.bin_id,sb.lot_id,(sb.on_hand_qty-sb.reserved_qty) AS available
        FROM stock_balances sb
        JOIN bins b ON b.bin_id=sb.bin_id
        LEFT JOIN inventory_lots l ON l.lot_id=sb.lot_id
        WHERE sb.product_id=p_product_id AND b.warehouse_id=p_warehouse_id
          AND b.is_pickable AND b.active
          AND sb.on_hand_qty>sb.reserved_qty
          AND (l.lot_id IS NULL OR (l.quality_state='RELEASED' AND (l.expires_on IS NULL OR l.expires_on>CURRENT_DATE)))
        ORDER BY l.expires_on NULLS LAST,b.bin_code,sb.lot_id NULLS FIRST
        FOR UPDATE OF sb
    LOOP
        EXIT WHEN v_remaining<=0;
        v_take:=LEAST(v_remaining,r.available);
        UPDATE stock_balances SET reserved_qty=reserved_qty+v_take,version_no=version_no+1,
            updated_at=CURRENT_TIMESTAMP
        WHERE product_id=r.product_id AND bin_id=r.bin_id
          AND lot_id IS NOT DISTINCT FROM r.lot_id;
        INSERT INTO reservation_lines(reservation_id,product_id,bin_id,lot_id,reserved_qty)
        VALUES(v_reservation_id,p_product_id,r.bin_id,r.lot_id,v_take);
        v_remaining:=v_remaining-v_take;
    END LOOP;

    IF v_remaining>0 THEN RAISE EXCEPTION 'insufficient available stock'; END IF;
    RETURN v_reservation_id;
END $$;

CREATE OR REPLACE FUNCTION release_reservation(p_reservation_id BIGINT,p_reason VARCHAR)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path=inventory,pg_temp AS $$
DECLARE r RECORD; v_release NUMERIC;
BEGIN
  PERFORM 1 FROM reservation_headers WHERE reservation_id=p_reservation_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'reservation not found'; END IF;
  FOR r IN SELECT * FROM reservation_lines WHERE reservation_id=p_reservation_id FOR UPDATE LOOP
    v_release:=r.reserved_qty-r.fulfilled_qty-r.released_qty;
    IF v_release>0 THEN
      UPDATE stock_balances SET reserved_qty=reserved_qty-v_release,version_no=version_no+1,
        updated_at=CURRENT_TIMESTAMP
      WHERE product_id=r.product_id AND bin_id=r.bin_id AND lot_id IS NOT DISTINCT FROM r.lot_id;
      UPDATE reservation_lines SET released_qty=released_qty+v_release
      WHERE reservation_line_id=r.reservation_line_id;
    END IF;
  END LOOP;
  UPDATE reservation_headers SET state='RELEASED',completed_at=CURRENT_TIMESTAMP
  WHERE reservation_id=p_reservation_id AND state IN ('ACTIVE','PARTIALLY_FULFILLED');
  INSERT INTO audit_events(action_code,object_type,object_id,details_json)
  VALUES('RESERVATION_RELEASED','RESERVATION',p_reservation_id,jsonb_build_object('reason',p_reason));
END $$;

-- Dispatch and receive a transfer as two explicit economic/physical events.
CREATE OR REPLACE FUNCTION dispatch_transfer(
    p_transfer_id BIGINT,p_command_id UUID,p_source_bin BIGINT,p_actor BIGINT
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path=inventory,pg_temp AS $$
DECLARE t RECORD; l RECORD;
BEGIN
  SELECT * INTO t FROM transfers WHERE transfer_id=p_transfer_id FOR UPDATE;
  IF t.state<>'DRAFT' THEN RAISE EXCEPTION 'invalid transfer state'; END IF;
  FOR l IN SELECT * FROM transfer_lines WHERE transfer_id=p_transfer_id ORDER BY product_id,lot_id FOR UPDATE LOOP
    PERFORM apply_stock_delta(p_command_id,l.product_id,t.from_warehouse_id,p_source_bin,l.lot_id,
      'TRANSFER_OUT',-l.requested_qty,'TRANSFER',p_transfer_id,CURRENT_TIMESTAMP,p_actor,'DISPATCH');
    UPDATE transfer_lines SET dispatched_qty=requested_qty WHERE transfer_line_id=l.transfer_line_id;
  END LOOP;
  UPDATE transfers SET state='DISPATCHED',dispatched_at=CURRENT_TIMESTAMP,version_no=version_no+1
  WHERE transfer_id=p_transfer_id;
END $$;

-- Expiry worker claims reservations without duplicate work.
WITH claimed AS (
  SELECT reservation_id FROM reservation_headers
  WHERE state IN ('ACTIVE','PARTIALLY_FULFILLED') AND expires_at<=CURRENT_TIMESTAMP
  ORDER BY expires_at,reservation_id
  FOR UPDATE SKIP LOCKED LIMIT :batch_size
)
SELECT release_reservation(reservation_id,'EXPIRED') FROM claimed;
