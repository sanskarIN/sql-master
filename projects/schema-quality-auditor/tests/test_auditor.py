import sys, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from auditor import audit

class AuditorTests(unittest.TestCase):
    def test_primary_key_clean(self):
        self.assertFalse(audit("CREATE TABLE t(id INTEGER PRIMARY KEY, name TEXT);"))

    def test_missing_pk(self):
        codes = [f.code for f in audit("CREATE TABLE t(name TEXT);")]
        self.assertIn("NO_PK", codes)

    def test_select_star(self):
        codes = [f.code for f in audit("SELECT * FROM t;")]
        self.assertIn("SELECT_STAR", codes)

    def test_float_money(self):
        codes = [f.code for f in audit("CREATE TABLE t(id INTEGER PRIMARY KEY, total REAL);")]
        self.assertIn("FLOAT_MONEY", codes)

if __name__ == "__main__":
    unittest.main()
