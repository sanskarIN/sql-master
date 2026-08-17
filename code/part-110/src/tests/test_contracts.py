from pathlib import Path
import re, unittest
ROOT=Path(__file__).resolve().parents[1]
def read(name): return (ROOT/name).read_text(encoding='utf-8')
class ContractTests(unittest.TestCase):
    def test_required_files(self):
        for p in ['sql/01_schema.sql','sql/02_relationship_commands.sql','sql/03_feed_queries.sql',
                  'sql/04_moderation_notifications.sql','sql/05_seed.sql','sql/06_invariant_tests.sql',
                  'docs/architecture.md','docs/runbook.md']:
            self.assertTrue((ROOT/p).exists(),p)
    def test_relationship_constraints(self):
        s=read('sql/01_schema.sql').lower()
        self.assertIn('check (follower_id <> followed_id)',s)
        self.assertIn('check (blocker_id <> blocked_id)',s)
        self.assertIn('primary key (user_id, post_id)',s)
        self.assertIn('primary key (owner_user_id, post_id)',s)
    def test_visibility_and_block_contracts(self):
        s=read('sql/02_relationship_commands.sql').lower()
        for token in ['can_view_post','is_blocked','security definer','delete from follows','delete from feed_items']:
            self.assertIn(token,s)
    def test_idempotency_contract(self):
        s=read('sql/02_relationship_commands.sql').lower()
        self.assertGreaterEqual(s.count('request_hash'),6)
        self.assertIn('idempotency key reused with different request',s)
        self.assertIn('idempotency conflict',s)
    def test_keyset_not_offset(self):
        s=read('sql/03_feed_queries.sql').lower()
        self.assertIn('(fi.ranked_at,fi.post_id) <',s)
        self.assertIn('order by fi.ranked_at desc,fi.post_id desc',s)
        self.assertNotRegex(s,r'\boffset\s+:')
    def test_bounded_recursive_graph(self):
        s=read('sql/03_feed_queries.sql').lower()
        self.assertIn('with recursive',s)
        self.assertRegex(s,r'g\.depth\s*<\s*4')
        self.assertIn('not f.followed_id=any(g.path)',s)
    def test_queue_and_reconciliation(self):
        s=read('sql/04_moderation_notifications.sql').lower()
        for token in ['for update skip locked','on conflict(recipient_id,dedupe_key) do nothing',
                      'reconcile eventually consistent counters','enable row level security']:
            self.assertIn(token,s)
    def test_no_dangerous_string_sql(self):
        for name in ['sql/02_relationship_commands.sql','sql/03_feed_queries.sql','sql/04_moderation_notifications.sql']:
            s=read(name).lower()
            self.assertNotIn('execute format(',s)
            self.assertNotIn("'|| :query ||'",s)
if __name__=='__main__': unittest.main()
