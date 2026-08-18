import sqlite3, sys, unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from quality_runner import Rule, run_rules, all_passed

class QualityRunnerTests(unittest.TestCase):
    def test_pass_and_fail(self):
        db = sqlite3.connect(":memory:")
        db.executescript("CREATE TABLE t(v INTEGER); INSERT INTO t VALUES (1),(-1);")
        results = run_rules(db, [
            Rule("no_nulls", "SELECT * FROM t WHERE v IS NULL"),
            Rule("positive", "SELECT * FROM t WHERE v <= 0"),
        ])
        self.assertTrue(results[0]["passed"])
        self.assertFalse(results[1]["passed"])
        self.assertFalse(all_passed(results))
        db.close()

    def test_all_pass(self):
        db = sqlite3.connect(":memory:")
        db.executescript("CREATE TABLE t(v INTEGER); INSERT INTO t VALUES (1);")
        results = run_rules(db, [Rule("positive", "SELECT * FROM t WHERE v <= 0")])
        self.assertTrue(all_passed(results))
        db.close()

if __name__ == "__main__":
    unittest.main()
