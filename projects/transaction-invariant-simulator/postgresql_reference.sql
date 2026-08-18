-- Reference pattern for a real PostgreSQL implementation.
-- Run inside a transaction. Lock rows in deterministic account_id order.

SELECT account_id, balance_paise
FROM account
WHERE account_id IN (:source_id, :target_id)
ORDER BY account_id
FOR UPDATE;

-- After application-side validation, update both balances.
-- Use an idempotency table with UNIQUE(idempotency_key) to reject retries.
