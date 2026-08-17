SET search_path = lab, public;

-- Q17. Sargable range predicate. Avoid event_time::date = DATE '2026-01-03'.
EXPLAIN (ANALYZE,BUFFERS,VERBOSE)
SELECT * FROM event_log
WHERE account_id=1
  AND event_time >= timestamptz '2026-01-03 00:00+00'
  AND event_time <  timestamptz '2026-01-04 00:00+00'
ORDER BY user_id,event_time,event_id;

-- Q18. Keyset pagination with a total order and matching index direction.
SELECT order_id,ordered_at,total_paise
FROM sales_order
WHERE account_id=1
  AND status='PAID'
  AND (ordered_at,order_id) < (timestamptz '2026-03-01 00:00+00',9223372036854775807)
ORDER BY ordered_at DESC,order_id DESC
LIMIT 20;

-- Q19. Claim a command safely. A repeated key with another hash is a conflict, not a replay.
BEGIN;
INSERT INTO api_command(account_id,idempotency_key,request_hash,command_status)
VALUES (1,'pay-9001','sha256:abc','STARTED')
ON CONFLICT (account_id,idempotency_key) DO NOTHING;
SELECT * FROM api_command
WHERE account_id=1 AND idempotency_key='pay-9001'
FOR UPDATE;
-- Application compares request_hash, performs the one business transaction, stores result_json, then commits.
ROLLBACK;

-- Q20. Prevent a write skew by locking the authoritative scope or using SERIALIZABLE.
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- Read the invariant scope, perform conditional writes, COMMIT, and retry only serialization failures.
ROLLBACK;

-- Q21. Latest order per user. DISTINCT ON is PostgreSQL-specific; ordering is complete.
SELECT DISTINCT ON (account_id,user_id)
       account_id,user_id,order_id,ordered_at,status,total_paise
FROM sales_order
ORDER BY account_id,user_id,ordered_at DESC,order_id DESC;

-- Diagnostic checklist for any EXPLAIN plan:
-- 1. Are estimated and actual rows close at each node?
-- 2. Did a join multiply rows beyond the declared grain?
-- 3. Are filters applied early enough?
-- 4. Are sorts spilling? Are hashes batching?
-- 5. Is the chosen index selective and ordered for the query?
-- 6. Are repeated loops multiplying inner-node cost?
-- 7. Is parallelism helping after coordination overhead?
