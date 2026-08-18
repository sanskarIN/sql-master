import sys, tempfile, unittest, csv
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import generate

class GeneratorTests(unittest.TestCase):
    def test_deterministic(self):
        self.assertEqual(list(generate.rows(5, 7)), list(generate.rows(5, 7)))

    def test_unique_ids_and_emails(self):
        data = list(generate.rows(20, 1))
        self.assertEqual(len({r["customer_id"] for r in data}), 20)
        self.assertEqual(len({r["email"] for r in data}), 20)

    def test_invalid_domain(self):
        self.assertTrue(all(r["email"].endswith("@example.invalid") for r in generate.rows(10)))

    def test_csv(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d, "x.csv")
            generate.write_csv(p, 3, 2)
            with p.open(newline="", encoding="utf-8") as f:
                self.assertEqual(len(list(csv.DictReader(f))), 3)

if __name__ == "__main__":
    unittest.main()
