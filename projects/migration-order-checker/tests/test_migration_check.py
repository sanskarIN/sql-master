import sys, tempfile, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from migration_check import inspect

class MigrationCheckTests(unittest.TestCase):
    def test_detects_gap(self):
        with tempfile.TemporaryDirectory() as d:
            Path(d, "001_init.sql").write_text("--")
            Path(d, "003_users.sql").write_text("--")
            self.assertEqual(inspect(d)["missing"], [2])

    def test_detects_duplicate_number(self):
        with tempfile.TemporaryDirectory() as d:
            Path(d, "001_init.sql").write_text("--")
            Path(d, "001_other.sql").write_text("--")
            self.assertEqual(inspect(d)["duplicates"], [1])

    def test_clean_sequence(self):
        with tempfile.TemporaryDirectory() as d:
            for n in range(1,4):
                Path(d, f"{n:03d}_step.sql").write_text("--")
            r = inspect(d)
            self.assertFalse(r["missing"] or r["duplicates"] or r["invalid"])

if __name__ == "__main__":
    unittest.main()
