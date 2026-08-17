-- Trusted transactional commands

CREATE OR REPLACE FUNCTION inventory.reserve_stock(
    p_tenant_id uuid,
    p_product_id uuid,
    p_warehouse_id uuid,
    p_quantity bigint,
    p_command_key text
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = inventory, catalog, core, pg_temp
AS $$
DECLARE
    v_balance inventory.stock_balance%ROWTYPE;
    v_existing inventory.stock_movement%ROWTYPE;
BEGIN
    IF p_quantity <= 0 THEN RAISE EXCEPTION 'quantity must be positive'; END IF;

    SELECT * INTO v_existing
    FROM inventory.stock_movement
    WHERE tenant_id = p_tenant_id AND command_key = p_command_key;
    IF FOUND THEN
        IF v_existing.product_id <> p_product_id OR v_existing.warehouse_id <> p_warehouse_id OR v_existing.quantity_delta <> -p_quantity THEN
            RAISE EXCEPTION 'idempotency conflict';
        END IF;
        RETURN jsonb_build_object('movement_id',v_existing.movement_id,'replayed',true);
    END IF;

    SELECT * INTO STRICT v_balance
    FROM inventory.stock_balance
    WHERE tenant_id=p_tenant_id AND product_id=p_product_id AND warehouse_id=p_warehouse_id
    FOR UPDATE;

    IF v_balance.on_hand_qty - v_balance.reserved_qty < p_quantity THEN
        RAISE EXCEPTION 'insufficient available stock';
    END IF;

    UPDATE inventory.stock_balance
       SET reserved_qty = reserved_qty + p_quantity,
           row_version = row_version + 1
     WHERE tenant_id=p_tenant_id AND product_id=p_product_id AND warehouse_id=p_warehouse_id;

    INSERT INTO inventory.stock_movement
      (tenant_id,product_id,warehouse_id,movement_type,quantity_delta,command_key)
    VALUES (p_tenant_id,p_product_id,p_warehouse_id,'RESERVE',-p_quantity,p_command_key)
    RETURNING * INTO v_existing;

    RETURN jsonb_build_object('movement_id',v_existing.movement_id,'replayed',false);
END; $$;

CREATE OR REPLACE FUNCTION booking.hold_resource(
    p_tenant_id uuid,
    p_resource_id uuid,
    p_customer_ref text,
    p_starts_at timestamptz,
    p_ends_at timestamptz,
    p_hold_minutes integer,
    p_idempotency_key text,
    p_request_hash text
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = booking, core, pg_temp
AS $$
DECLARE v booking.reservation%ROWTYPE;
BEGIN
    SELECT * INTO v FROM booking.reservation
     WHERE tenant_id=p_tenant_id AND idempotency_key=p_idempotency_key;
    IF FOUND THEN
        IF v.request_hash <> p_request_hash THEN RAISE EXCEPTION 'idempotency conflict'; END IF;
        RETURN jsonb_build_object('reservation_id',v.reservation_id,'status',v.status,'replayed',true);
    END IF;

    INSERT INTO booking.reservation
      (tenant_id,resource_id,customer_ref,starts_at,ends_at,status,hold_expires_at,idempotency_key,request_hash)
    VALUES
      (p_tenant_id,p_resource_id,p_customer_ref,p_starts_at,p_ends_at,'HELD',clock_timestamp()+make_interval(mins=>p_hold_minutes),p_idempotency_key,p_request_hash)
    RETURNING * INTO v;

    INSERT INTO integration.outbox_event
      (tenant_id,aggregate_type,aggregate_id,event_type,event_version,payload)
    VALUES
      (p_tenant_id,'booking',v.reservation_id,'BookingHeld',1,jsonb_build_object('starts_at',v.starts_at,'ends_at',v.ends_at));

    RETURN jsonb_build_object('reservation_id',v.reservation_id,'status',v.status,'replayed',false);
EXCEPTION WHEN exclusion_violation THEN
    RAISE EXCEPTION 'booking conflict';
END; $$;

CREATE OR REPLACE FUNCTION ledger.post_balanced_entry(
    p_tenant_id uuid,
    p_effective_at timestamptz,
    p_description text,
    p_idempotency_key text,
    p_request_hash text,
    p_postings jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ledger, core, pg_temp
AS $$
DECLARE
    v_entry ledger.journal_entry%ROWTYPE;
    v_debit bigint;
    v_credit bigint;
BEGIN
    SELECT * INTO v_entry FROM ledger.journal_entry
     WHERE tenant_id=p_tenant_id AND idempotency_key=p_idempotency_key;
    IF FOUND THEN
        IF v_entry.request_hash <> p_request_hash THEN RAISE EXCEPTION 'idempotency conflict'; END IF;
        RETURN jsonb_build_object('entry_id',v_entry.entry_id,'state',v_entry.entry_state,'replayed',true);
    END IF;

    SELECT COALESCE(SUM((x->>'amount_paise')::bigint) FILTER (WHERE x->>'side'='DEBIT'),0),
           COALESCE(SUM((x->>'amount_paise')::bigint) FILTER (WHERE x->>'side'='CREDIT'),0)
      INTO v_debit, v_credit
      FROM jsonb_array_elements(p_postings) x;
    IF v_debit = 0 OR v_debit <> v_credit THEN RAISE EXCEPTION 'unbalanced entry'; END IF;

    INSERT INTO ledger.journal_entry
      (tenant_id,entry_state,effective_at,description,idempotency_key,request_hash,posted_at)
    VALUES (p_tenant_id,'POSTED',p_effective_at,p_description,p_idempotency_key,p_request_hash,clock_timestamp())
    RETURNING * INTO v_entry;

    INSERT INTO ledger.posting (tenant_id,entry_id,posting_no,account_id,side,amount_paise,currency_code)
    SELECT p_tenant_id, v_entry.entry_id, ordinality::int,
           (x->>'account_id')::uuid, (x->>'side')::ledger.posting_side,
           (x->>'amount_paise')::bigint, x->>'currency_code'
      FROM jsonb_array_elements(p_postings) WITH ORDINALITY AS j(x,ordinality);

    RETURN jsonb_build_object('entry_id',v_entry.entry_id,'state','POSTED','replayed',false);
END; $$;
