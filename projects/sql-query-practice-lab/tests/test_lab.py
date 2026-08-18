import sqlite3, unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class LabTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        self.db.executescript((ROOT/"schema.sql").read_text())
        self.db.executescript((ROOT/"seed.sql").read_text())

    def tearDown(self):
        self.db.close()

    def test_customer_without_order(self):
        rows = self.db.execute(
            "SELECT c.customer_id FROM customer c LEFT JOIN orders o "
            "ON o.customer_id=c.customer_id WHERE o.order_id IS NULL"
        ).fetchall()
        self.assertEqual(rows, [(3,)])

    def test_latest_order(self):
        row = self.db.execute(
            "SELECT order_id FROM orders WHERE customer_id=1 "
            "ORDER BY ordered_at DESC, order_id DESC LIMIT 1"
        ).fetchone()
        self.assertEqual(row[0], 11)

    def test_total_revenue(self):
        self.assertEqual(self.db.execute("SELECT SUM(total_paise) FROM orders").fetchone()[0], 35000)

if __name__ == "__main__":
    unittest.main()
