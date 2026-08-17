import csv, unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

class PackageTests(unittest.TestCase):
    def test_required_files(self):
        for p in ['README.md','sql/01_schema.sql','sql/02_seed.sql','sql/03_practice_questions.sql','sql/04_selected_solutions.sql','workbook/flashcards.csv','workbook/mock_interview.md','workbook/answer_framework.md','tools/self_check.py']:
            self.assertTrue((ROOT/p).is_file(), p)
    def test_flashcard_count(self):
        cards=list(csv.DictReader((ROOT/'workbook/flashcards.csv').open(encoding='utf-8')))
        self.assertEqual(60, len(cards))
        self.assertTrue(all(c['question'] and c['strong_answer'] for c in cards))
    def test_integrity_contracts(self):
        s=(ROOT/'sql/01_schema.sql').read_text(encoding='utf-8')
        for token in ['PRIMARY KEY','REFERENCES customers','CHECK (total_paise >= 0)','UNIQUE (order_id, product_id)','CREATE INDEX']:
            self.assertIn(token,s)
    def test_null_safe_antijoin_solution(self):
        s=(ROOT/'sql/04_selected_solutions.sql').read_text(encoding='utf-8')
        self.assertIn('WHERE NOT EXISTS',s)
        self.assertNotIn('NOT IN (',s)
    def test_deterministic_ordering(self):
        s=(ROOT/'sql/04_selected_solutions.sql').read_text(encoding='utf-8')
        self.assertIn('ORDER BY order_date DESC, order_id DESC',s)
    def test_integer_money(self):
        schema=(ROOT/'sql/01_schema.sql').read_text(encoding='utf-8')
        self.assertIn('BIGINT',schema)
        self.assertNotIn('FLOAT',schema)
    def test_parameter_guidance(self):
        cards=list(csv.DictReader((ROOT/'workbook/flashcards.csv').open(encoding='utf-8')))
        text=' '.join(c['question']+' '+c['strong_answer']+' '+c['example_or_pitfall'] for c in cards).lower()
        self.assertIn('parameter',text)
        self.assertIn('injection',text)

if __name__ == '__main__': unittest.main()
