from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

def read(name):
    return (ROOT / name).read_text(encoding='utf-8')

class BookingSQLContractTests(unittest.TestCase):
    def test_required_files(self):
        for name in [
            'sql/01_schema.sql','sql/02_commands.sql','sql/03_queries.sql',
            'sql/04_operations.sql','sql/05_seed.sql','sql/06_invariant_tests.sql'
        ]:
            self.assertTrue((ROOT/name).exists(), name)

    def test_race_proof_overlap_constraint(self):
        s = read('sql/01_schema.sql').lower()
        self.assertIn('exclude using gist', s)
        self.assertIn('occupied_slot with &&', s)
        self.assertIn("where (state in ('held','confirmed'))", s)

    def test_half_open_ranges(self):
        text = (read('sql/02_commands.sql') + read('sql/03_queries.sql')).lower()
        self.assertIn("tstzrange(:starts_at, :ends_at, '[)')", text)

    def test_idempotency_hash_and_unique_key(self):
        s = read('sql/01_schema.sql').lower()
        self.assertIn('idempotency_key', s)
        self.assertIn('request_hash', s)
        self.assertIn('unique (tenant_id, idempotency_key)', s)

    def test_stable_lock_order_and_skip_locked(self):
        s = read('sql/02_commands.sql').lower()
        self.assertIn('order by r.resource_id', s)
        self.assertIn('for update of r skip locked', s)
        self.assertIn('for update skip locked', s)

    def test_keyset_not_offset(self):
        s = read('sql/03_queries.sql').lower()
        self.assertIn('(starts_at, booking_id) <', s)
        self.assertNotIn(' offset ', s)

    def test_reconciliation_queries_exist(self):
        s = read('sql/03_queries.sql').lower()
        self.assertIn('active_allocations', s)
        self.assertIn('occupied_slot <>', s)

    def test_bound_placeholders_not_string_formatting(self):
        text = read('sql/02_commands.sql') + read('sql/03_queries.sql')
        self.assertIn(':tenant_id', text)
        self.assertNotIn("format('", text.lower())
        self.assertNotIn('execute immediate', text.lower())

    def test_outbox_and_events(self):
        s = read('sql/01_schema.sql').lower()
        self.assertIn('create table booking_events', s)
        self.assertIn('create table outbox_events', s)

if __name__ == '__main__':
    unittest.main()
