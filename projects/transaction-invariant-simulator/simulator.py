from __future__ import annotations
from dataclasses import dataclass, field

@dataclass
class Ledger:
    balances: dict[str, int]
    applied_keys: set[str] = field(default_factory=set)

    def total(self):
        return sum(self.balances.values())

    def transfer(self, source, target, amount, idempotency_key):
        if amount <= 0:
            raise ValueError("amount must be positive")
        if source == target:
            raise ValueError("source and target must differ")
        if idempotency_key in self.applied_keys:
            return False
        if source not in self.balances or target not in self.balances:
            raise KeyError("unknown account")
        if self.balances[source] < amount:
            raise ValueError("insufficient funds")
        before = self.total()
        self.balances[source] -= amount
        self.balances[target] += amount
        if self.total() != before:
            raise AssertionError("money conservation violated")
        self.applied_keys.add(idempotency_key)
        return True
