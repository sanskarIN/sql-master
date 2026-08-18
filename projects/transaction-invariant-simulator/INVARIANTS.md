# Transaction Invariants

- Money is stored as integer minor units (paise), not floating point.
- Transfer amount must be positive.
- Source and target must differ.
- No account may become negative unless the product explicitly supports overdrafts.
- The sum of balances is conserved by a pure internal transfer.
- An idempotency key may apply at most once.
