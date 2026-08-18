import sys, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from simulator import Ledger

class LedgerTests(unittest.TestCase):
    def setUp(self):
        self.l = Ledger({"A": 1000, "B": 500})

    def test_total_preserved(self):
        before = self.l.total()
        self.l.transfer("A","B",250,"k1")
        self.assertEqual(self.l.total(), before)

    def test_idempotent(self):
        self.assertTrue(self.l.transfer("A","B",100,"k1"))
        self.assertFalse(self.l.transfer("A","B",100,"k1"))
        self.assertEqual(self.l.balances["A"], 900)

    def test_insufficient_funds(self):
        with self.assertRaises(ValueError):
            self.l.transfer("B","A",9999,"k")

if __name__ == "__main__":
    unittest.main()
