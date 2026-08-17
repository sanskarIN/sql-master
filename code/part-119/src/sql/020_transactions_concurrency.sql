-- Transaction, concurrency, and idempotency interview patterns
SET search_path = interview119, public;

-- Atomic stock reservation with affected-row proof.
BEGIN;
UPDATE stock_balance
SET reserved_qty = reserved_qty + 2,
    row_version = row_version + 1
WHERE tenant_id = 1 AND warehouse_id = 1 AND product_id = 1
  AND on_hand_qty - reserved_qty >= 2;
-- Application must require row_count = 1, then write reservation/outbox in the same transaction.
COMMIT;

-- Safe worker claiming: disjoint batches without blocking all workers.
WITH picked AS (
  SELECT tenant_id, job_id
  FROM job_queue
  WHERE state='READY' AND available_at <= clock_timestamp()
  ORDER BY available_at, job_id
  FOR UPDATE SKIP LOCKED
  LIMIT 10
)
UPDATE job_queue j
SET state='RUNNING', claimed_by='worker-1', claimed_at=clock_timestamp(), attempt_count=attempt_count+1
FROM picked p
WHERE (j.tenant_id,j.job_id)=(p.tenant_id,p.job_id)
RETURNING j.*;

-- Optimistic update.
UPDATE product
SET price_paise = 239900, row_version = row_version + 1
WHERE tenant_id=1 AND product_id=1 AND row_version=1;
-- Require one row; zero rows means stale version or missing object.

-- Deadlock prevention rule: lock resources in one canonical order.
BEGIN;
SELECT 1 FROM stock_balance
WHERE tenant_id=1 AND (warehouse_id,product_id) IN ((1,1),(2,1))
ORDER BY warehouse_id,product_id
FOR UPDATE;
-- perform transfer
COMMIT;

-- Serializable retry classification (pseudocode in comments):
-- retry serialization failures/deadlocks with bounded exponential jitter;
-- never blindly retry validation or unique-conflict errors;
-- recover ambiguous commit by reading the idempotency record.
