from __future__ import annotations
from datetime import datetime, timedelta, timezone
from pathlib import Path
import csv, hashlib, json, re

ROOT=Path(__file__).resolve().parents[1]

def test_files():
    required=[
      'README.md','answer_rubric.md','timed_sets.md','challenge_bank.csv',
      'sql/001_schema.sql','sql/002_seed.sql','sql/003_window_interviews.sql',
      'sql/004_session_funnel_retention.sql','sql/005_temporal_recursive.sql',
      'sql/006_plan_concurrency.sql','tests/001_invariant_queries.sql',
      'docs/production-checklist.md']
    missing=[p for p in required if not (ROOT/p).is_file()]
    assert not missing,missing

def test_challenge_bank():
    rows=list(csv.DictReader((ROOT/'challenge_bank.csv').open(encoding='utf-8')))
    assert len(rows)==60
    assert len({r['id'] for r in rows})==60
    assert {'Frames','Sessionization','Funnels','Cohorts','Temporal','Recursive','Plans','Concurrency'} <= {r['skill'] for r in rows}

def running_rows(values):
    out=[];s=0
    for v in values:s+=v;out.append(s)
    return out

def running_range(keys,values):
    return [sum(v for k,v in zip(keys,values) if k<=key) for key in keys]

def test_peer_frames():
    keys=[1,1,2]; vals=[10,20,5]
    assert running_rows(vals)==[10,30,35]
    assert running_range(keys,vals)==[30,30,35]

def sessionize(times,threshold):
    out=[];session=0;prev=None
    for t in times:
        if prev is None or t-prev>=threshold:session+=1
        out.append(session);prev=t
    return out

def test_session_boundary():
    t=datetime(2026,1,1,tzinfo=timezone.utc)
    times=[t,t+timedelta(minutes=29),t+timedelta(minutes=59),t+timedelta(minutes=90)]
    assert sessionize(times,timedelta(minutes=30))==[1,1,2,3]

def strict_funnel(events,steps,deadline):
    cursor=None
    for step in steps:
        found=next((t for name,t in events if name==step and (cursor is None or t>=cursor) and t<deadline),None)
        if found is None:return False
        cursor=found
    return True

def test_ordered_funnel():
    t=datetime(2026,1,1,tzinfo=timezone.utc)
    good=[('signup',t),('view',t+timedelta(minutes=1)),('cart',t+timedelta(minutes=2)),('purchase',t+timedelta(minutes=3))]
    bad=[('signup',t),('purchase',t+timedelta(minutes=1)),('view',t+timedelta(minutes=2)),('cart',t+timedelta(minutes=3))]
    assert strict_funnel(good,['signup','view','cart','purchase'],t+timedelta(days=7))
    assert not strict_funnel(bad,['signup','view','cart','purchase'],t+timedelta(days=7))

def test_cohort_denominator():
    cohort={'u1','u2','u3'}; active={'u1','u3','outside'}
    assert len(cohort&active)/len(cohort)==2/3

def asof(rows,t):
    valid=[r for r in rows if r[0]<=t and (r[1] is None or t<r[1])]
    return max(valid,key=lambda r:r[0])[2] if valid else None

def test_half_open_temporal():
    t=datetime(2026,2,1,tzinfo=timezone.utc)
    rows=[(datetime(2026,1,1,tzinfo=timezone.utc),t,199),(t,None,249)]
    assert asof(rows,t)==249

def walk(graph,start,max_depth=20):
    stack=[(start,[start])];seen_paths=[]
    while stack:
        node,path=stack.pop();seen_paths.append(path)
        if len(path)-1>=max_depth:continue
        for nxt in graph.get(node,[]):
            if nxt not in path:stack.append((nxt,path+[nxt]))
    return seen_paths

def test_cycle_safe_recursion():
    paths=walk({'A':['B'],'B':['C'],'C':['A']},'A')
    assert max(map(len,paths))==3

def keyset(rows,cursor,limit):
    ordered=sorted(rows,key=lambda r:(r[0],r[1]),reverse=True)
    if cursor is not None: ordered=[r for r in ordered if (r[0],r[1])<cursor]
    return ordered[:limit]

def test_keyset_disjoint():
    rows=[(3,3),(3,2),(2,5),(1,9)]
    p1=keyset(rows,None,2);p2=keyset(rows,p1[-1],2)
    assert p1==[(3,3),(3,2)] and p2==[(2,5),(1,9)] and not set(p1)&set(p2)

def claim(store,key,request):
    h=hashlib.sha256(json.dumps(request,sort_keys=True).encode()).hexdigest()
    if key in store:
        if store[key]!=h: raise ValueError('conflicting retry')
        return 'replay'
    store[key]=h;return 'new'

def test_idempotency_hash():
    s={}; assert claim(s,'k',{'amount':100})=='new';assert claim(s,'k',{'amount':100})=='replay'
    try:claim(s,'k',{'amount':101})
    except ValueError:pass
    else:raise AssertionError('conflict accepted')

def test_sql_contracts():
    text='\n'.join(p.read_text(encoding='utf-8') for p in (ROOT/'sql').glob('*.sql'))
    for token in ['ROWS BETWEEN','DENSE_RANK','LAG(','WITH RECURSIVE','tstzrange','EXPLAIN (ANALYZE,BUFFERS','SERIALIZABLE','idempotency_key']:
        assert token in text,token

if __name__=='__main__':
    tests=[v for k,v in sorted(globals().items()) if k.startswith('test_') and callable(v)]
    for fn in tests:
        fn();print('PASS',fn.__name__)
    print(f'PASS {len(tests)} tests')
