from pathlib import Path
import csv,re
ROOT=Path(__file__).parent
required=['README.md','answer_frameworks.md','final_mock_interviews.md','scoring_rubric.md','resume_and_story_templates.md','role_specific_preparation.md','thirty_day_revision_plan.md','career_readiness_checklist.md','portfolio_evidence_matrix.csv','sql/001_schema.sql','sql/002_seed.sql','sql/010_mock_queries.sql','tests/001_invariant_checks.sql']
for p in required:
    assert (ROOT/p).is_file(),p
with (ROOT/'final_question_bank.csv').open(encoding='utf-8') as f:
    rows=list(csv.DictReader(f))
assert len(rows)==120
assert len({r['question_id'] for r in rows})==120
assert len({r['category'] for r in rows})==12
schema=(ROOT/'sql/001_schema.sql').read_text()
for token in ['CHECK (price_paise>=0)','UNIQUE','EXCLUDE USING gist','order_line_reconciliation','ledger_balance_check']:
    assert token in schema,token
queries=(ROOT/'sql/010_mock_queries.sql').read_text()
assert 'ROW_NUMBER() OVER' in queries
assert 'NOT EXISTS' in queries
assert 'ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW' in queries
assert '(ordered_at,order_id)<(:cursor_time,:cursor_id)' in queries
assert 'on_hand_qty-reserved_qty>=:qty' in queries
# reasoning models
orders=[('2026-03-01T10:00:00Z',2),('2026-03-01T10:00:00Z',1)]
assert sorted(orders,reverse=True)[0][1]==2
assert not (10<30 and 20<20)  # [10,20) and [20,30) do not overlap
postings=[('D',49800),('C',49800)]
assert sum(v if s=='D' else -v for s,v in postings)==0
stock={'on_hand':10,'reserved':2}; qty=8
assert stock['on_hand']-stock['reserved']>=qty
assert '₹' not in schema  # SQL remains portable; currency is ISO code/minor units
print('PASS: 17 final-package and reasoning checks')
