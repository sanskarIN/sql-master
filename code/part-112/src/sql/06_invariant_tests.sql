-- Invariant tests intended for a disposable PostgreSQL database
SET search_path = booking, public;

-- 1. Overlap should fail for the same resource when both allocations are active.
DO $$
DECLARE t BIGINT; c BIGINT; p BIGINT; r BIGINT; cmd1 BIGINT; cmd2 BIGINT; b1 BIGINT; b2 BIGINT;
BEGIN
  SELECT tenant_id INTO t FROM tenants WHERE tenant_code='DEMO';
  SELECT customer_id INTO c FROM customers WHERE tenant_id=t LIMIT 1;
  SELECT resource_pool_id INTO p FROM resource_pools WHERE tenant_id=t LIMIT 1;
  SELECT resource_id INTO r FROM resources WHERE tenant_id=t ORDER BY resource_id LIMIT 1;
  INSERT INTO booking_commands(tenant_id,idempotency_key,command_type,request_hash)
  VALUES(t,'test-overlap-1','CREATE_HOLD',repeat('a',64)) RETURNING booking_command_id INTO cmd1;
  INSERT INTO booking_commands(tenant_id,idempotency_key,command_type,request_hash)
  VALUES(t,'test-overlap-2','CREATE_HOLD',repeat('b',64)) RETURNING booking_command_id INTO cmd2;
  INSERT INTO bookings(tenant_id,booking_reference,customer_id,resource_pool_id,state,starts_at,ends_at,
      display_timezone,hold_expires_at,price_minor,currency_code,policy_version,booking_command_id)
  VALUES(t,'TEST-1',c,p,'HELD','2026-08-20 04:00+00','2026-08-20 04:30+00','Asia/Kolkata',
      CURRENT_TIMESTAMP+interval '10 minutes',0,'INR',1,cmd1) RETURNING booking_id INTO b1;
  INSERT INTO booking_allocations(tenant_id,booking_id,resource_id,occupied_slot,state)
  VALUES(t,b1,r,tstzrange('2026-08-20 04:00+00','2026-08-20 04:30+00','[)'),'HELD');
  BEGIN
    INSERT INTO bookings(tenant_id,booking_reference,customer_id,resource_pool_id,state,starts_at,ends_at,
        display_timezone,hold_expires_at,price_minor,currency_code,policy_version,booking_command_id)
    VALUES(t,'TEST-2',c,p,'HELD','2026-08-20 04:15+00','2026-08-20 04:45+00','Asia/Kolkata',
        CURRENT_TIMESTAMP+interval '10 minutes',0,'INR',1,cmd2) RETURNING booking_id INTO b2;
    INSERT INTO booking_allocations(tenant_id,booking_id,resource_id,occupied_slot,state)
    VALUES(t,b2,r,tstzrange('2026-08-20 04:15+00','2026-08-20 04:45+00','[)'),'HELD');
    RAISE EXCEPTION 'overlap invariant failed';
  EXCEPTION WHEN exclusion_violation THEN NULL;
  END;
END $$;

-- 2. No active booking may lack an active allocation.
DO $$
BEGIN
  IF EXISTS (
      SELECT 1 FROM bookings b
      WHERE b.state IN ('HELD','CONFIRMED')
        AND NOT EXISTS (
            SELECT 1 FROM booking_allocations a
            WHERE a.booking_id=b.booking_id AND a.tenant_id=b.tenant_id
              AND a.state IN ('HELD','CONFIRMED'))
  ) THEN RAISE EXCEPTION 'active booking without active allocation'; END IF;
END $$;
