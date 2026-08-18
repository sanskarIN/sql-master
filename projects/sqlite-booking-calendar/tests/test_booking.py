import sys, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import booking

class BookingTests(unittest.TestCase):
    def setUp(self):
        self.db = booking.connect()
        self.rid = booking.add_resource(self.db, "Room A")

    def tearDown(self):
        self.db.close()

    def test_non_overlapping(self):
        booking.create_booking(self.db, self.rid, "2026-01-01T10:00", "2026-01-01T11:00")
        booking.create_booking(self.db, self.rid, "2026-01-01T11:00", "2026-01-01T12:00")
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM booking").fetchone()[0], 2)

    def test_overlap_rejected(self):
        booking.create_booking(self.db, self.rid, "2026-01-01T10:00", "2026-01-01T11:00")
        with self.assertRaises(ValueError):
            booking.create_booking(self.db, self.rid, "2026-01-01T10:30", "2026-01-01T11:30")

    def test_invalid_interval(self):
        with self.assertRaises(ValueError):
            booking.create_booking(self.db, self.rid, "2026-01-01T12:00", "2026-01-01T11:00")

if __name__ == "__main__":
    unittest.main()
