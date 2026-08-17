from pathlib import Path
import re, unittest
ROOT=Path(__file__).resolve().parents[1]
def read(name): return (ROOT/name).read_text(encoding='utf-8')
class ContractTests(unittest.TestCase):
    def test_required_files(self):
        for p in ['sql/01_schema.sql','sql/02_inventory_commands.sql','sql/03_planning_queries.sql',
                  'sql/04_receiving_counts_security.sql','sql/05_seed.sql','sql/06_invariant_tests.sql',
                  'docs/architecture.md','docs/runbook.md']:
            self.assertTrue((ROOT/p).exists(),p)
    def test_balance_constraints(self):
        s=read('sql/01_schema.sql').lower()
        self.assertIn('check (on_hand_qty >= 0)',s)
        self.assertIn('check (reserved_qty <= on_hand_qty)',s)
        self.assertIn('check (received_qty <= dispatched_qty)',s)
        self.assertIn('received_qty + cancelled_qty <= ordered_qty',s)
    def test_authoritative_ledger(self):
        s=read('sql/01_schema.sql').lower()
        self.assertIn('create table stock_movements',s)
        self.assertIn('reversal_of_movement_id',s)
        self.assertIn('create table stock_balances',s)
    def test_deterministic_allocation_and_locks(self):
        s=read('sql/02_inventory_commands.sql').lower()
        self.assertIn('order by l.expires_on nulls last,b.bin_code',s)
        self.assertIn('for update of sb',s)
        self.assertIn('skip locked',s)
    def test_idempotency_contract(self):
        s=read('sql/02_inventory_commands.sql').lower()
        self.assertIn('request_hash',s)
        self.assertIn('idempotency conflict',s)
        self.assertIn('on conflict',s)
    def test_reorder_uses_supply_and_demand(self):
        s=read('sql/03_planning_queries.sql').lower()
        for token in ['available_qty','open_po_qty','lead_time_demand','target_stock_qty','policy_version']:
            self.assertIn(token,s)
    def test_keyset_not_offset(self):
        s=read('sql/03_planning_queries.sql').lower()
        self.assertIn('cursor_expiry',s)
        self.assertNotRegex(s,r'\boffset\s*:')
    def test_reconciliation_and_security(self):
        s=read('sql/04_receiving_counts_security.sql').lower()
        for token in ['ledger-to-balance reconciliation','reservation projection','revoke all','enable row level security']:
            self.assertIn(token,s)
    def test_no_dynamic_string_sql(self):
        for name in ['sql/02_inventory_commands.sql','sql/03_planning_queries.sql','sql/04_receiving_counts_security.sql']:
            s=read(name).lower()
            self.assertNotIn('execute format(',s)
            self.assertNotIn("'|| :",s)
if __name__=='__main__': unittest.main()
