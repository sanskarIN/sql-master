from __future__ import annotations
import csv, re
from pathlib import Path
ROOT=Path(__file__).parent

def read(name): return (ROOT/name).read_text(encoding='utf-8')

def test_challenge_count_and_ids():
    rows=list(csv.DictReader((ROOT/'challenge_bank.csv').open(encoding='utf-8')))
    assert len(rows)==48
    ids=[r['challenge_id'] for r in rows]
    assert len(ids)==len(set(ids))
    assert ids[0]=='IQ001' and ids[-1]=='IQ048'

def test_all_categories_present():
    rows=list(csv.DictReader((ROOT/'challenge_bank.csv').open(encoding='utf-8')))
    categories={r['category'] for r in rows}
    required={'Mixed-grain joins','Grouped reports','Subqueries and CTEs','Window functions','Gaps and islands','Data diagnosis','Pagination and APIs','Query testing','Timed case'}
    assert required <= categories

def test_schema_integrity_contracts():
    s=read('schema.sql').lower()
    for token in ['primary key','references ','check (','create index','stored_total_paise','unit_price_paise']:
        assert token in s
    assert '$' not in s

def test_null_safe_antijoin():
    s=read('solutions.sql').lower()
    block=s[s.index('-- iq021'):s.index('-- iq022')]
    assert 'not exists' in block
    assert 'not in' not in block

def test_deterministic_latest_and_pagination():
    s=read('solutions.sql').lower()
    assert 'order by ordered_at desc, order_id desc' in s
    assert '(ordered_at,order_id) <' in s

def test_window_and_island_patterns():
    s=read('solutions.sql').lower()
    for token in ['row_number() over','dense_rank() over','lag(','rows between','recursive','island_key']:
        assert token in s

def test_mixed_grain_defense():
    s=read('solutions.sql').lower()
    assert 'item_facts' in s and 'payment_facts' in s
    assert 'independent item/payment aggregates' in s

def test_integer_money():
    schema=read('schema.sql').lower()
    assert '_paise bigint' in schema
    assert 'money' not in schema

def test_companion_docs():
    for name in ['README.md','timed_sets.md','answer_rubric.md']:
        assert (ROOT/name).stat().st_size>500

def run():
    tests=[v for k,v in sorted(globals().items()) if k.startswith('test_') and callable(v)]
    for t in tests: t()
    print(f'PASS: {len(tests)} Part 117 companion contract tests')
if __name__=='__main__': run()
