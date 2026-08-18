import sys, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import app

class InventoryTests(unittest.TestCase):
    def setUp(self):
        self.db = app.connect()
        self.pid = app.add_product(self.db, "SKU-1", "Keyboard", 2)

    def tearDown(self):
        self.db.close()

    def test_adjustments_are_summed(self):
        app.adjust_stock(self.db, self.pid, 10, "opening")
        app.adjust_stock(self.db, self.pid, -3, "sale")
        self.assertEqual(app.stock(self.db, self.pid), 7)

    def test_zero_adjustment_rejected(self):
        with self.assertRaises(ValueError):
            app.adjust_stock(self.db, self.pid, 0, "invalid")

    def test_reorder_report(self):
        app.adjust_stock(self.db, self.pid, 2, "opening")
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM current_stock").fetchone()[0], 1)
        self.assertEqual(len(app.reorder_report(self.db)), 1)

if __name__ == "__main__":
    unittest.main()
