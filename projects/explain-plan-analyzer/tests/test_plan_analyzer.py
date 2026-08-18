import sys, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from plan_analyzer import analyze

class PlanTests(unittest.TestCase):
    def test_seq_scan(self):
        r = analyze("Seq Scan on orders  (cost=0.00..10.00 rows=50 width=8)")
        self.assertEqual(r["counts"]["Seq Scan"], 1)
        self.assertTrue(r["warnings"])

    def test_index_scan(self):
        r = analyze("Index Scan using ix_orders on orders (cost=0..4 rows=2 width=8)")
        self.assertEqual(r["counts"]["Index Scan"], 1)

    def test_disk_sort(self):
        r = analyze("Sort Method: external merge  Disk: 2048kB")
        self.assertTrue(any("spilled" in w for w in r["warnings"]))

if __name__ == "__main__":
    unittest.main()
