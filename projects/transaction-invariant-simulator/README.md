# Transaction Invariant Simulator

A small Python model for practicing transfer invariants and idempotency before implementing real database transactions.

The simulator uses integer minor units and checks that the total across accounts is preserved by an internal transfer.

```bash
python -m unittest discover -s tests
```

Official store: **https://ramsandesh.gumroad.com**
