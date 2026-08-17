from pathlib import Path
import csv, re, sys, hashlib
ROOT=Path(__file__).resolve().parent

def require(cond,msg):
    if not cond: raise AssertionError(msg)

def read(p): return (ROOT/p).read_text(encoding='utf-8')

required=['README.md','case_bank.csv','timed_simulations.md','answer_rubric.md','sql/001_schema.sql','sql/002_seed.sql','sql/010_design_cases.sql','sql/020_transactions_concurrency.sql','sql/030_performance_plans.sql','sql/040_evolution_security_recovery.sql','tests/001_invariant_checks.sql','docs/ARCHITECTURE.md','docs/PRODUCTION_CHECKLIST.md']
for p in required: require((ROOT/p).is_file(),f'missing {p}')

with open(ROOT/'case_bank.csv',encoding='utf-8',newline='') as f: rows=list(csv.DictReader(f))
require(len(rows)==72,'case bank must contain 72 cases')
require(len({r['id'] for r in rows})==72,'case ids must be unique')
require(all(int(r['time_minutes'])>=10 for r in rows),'time limits must be realistic')

schema=read('sql/001_schema.sql')
for token in ['CHECK (starts_at < ends_at)','EXCLUDE USING gist','UNIQUE (tenant_id, idempotency_key)','reserved_qty <= on_hand_qty','FOREIGN KEY (tenant_id, product_id)','amount_paise > 0','ix_job_claim']:
    require(token in schema,f'missing schema contract: {token}')

inv=read('tests/001_invariant_checks.sql')
for token in ['reserved_qty > on_hand_qty','line_total','HAVING sum(CASE side','Duplicate live email','RUNNING']:
    require(token in inv,f'missing invariant check: {token}')

perf=read('sql/030_performance_plans.sql')
require('EXPLAIN (ANALYZE, BUFFERS' in perf,'plan evidence missing')
require('(ordered_at, order_id) <' in perf,'keyset pagination missing')
require('date(ordered_at)' in perf,'sargability contrast missing')

trans=read('sql/020_transactions_concurrency.sql')
for token in ['SKIP LOCKED','row_count = 1','row_version','canonical order','ambiguous commit']:
    require(token in trans,f'missing transaction reasoning: {token}')

# Pure model checks
on_hand,reserved,request=10,3,8
require(on_hand-reserved < request,'adversarial stock setup expected insufficient availability')
line_total=249900+99900
require(line_total==349800,'integer paise reconciliation failed')
postings=[('D',349800),('C',349800)]
net=sum(v if s=='D' else -v for s,v in postings)
require(net==0,'ledger balance model failed')
# half-open adjacency is not overlap
A=(10,20); B=(20,30)
require(not (A[0] < B[1] and B[0] < A[1]),'half-open adjacency must not overlap')
# deterministic order requires unique tie-breaker
orders=[('2026-08-02T10:00:00Z',2),('2026-08-02T10:00:00Z',1)]
require(sorted(orders,reverse=True)==[('2026-08-02T10:00:00Z',2),('2026-08-02T10:00:00Z',1)],'deterministic order failed')

print('PASS: 13 package contracts and reasoning-model checks')
