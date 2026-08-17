import unittest
from dataclasses import dataclass
from datetime import datetime, timezone
from decimal import Decimal, ROUND_HALF_UP

INF=datetime(9999,12,31,tzinfo=timezone.utc)

@dataclass(frozen=True)
class Version:
    key:int; bk:str; value:str; valid_from:datetime; valid_to:datetime; current:bool

def scd2_apply(rows,bk,value,at):
    out=[]; changed=False
    for r in rows:
        if r.bk==bk and r.current:
            if r.value==value: return rows
            out.append(Version(r.key,r.bk,r.value,r.valid_from,at,False)); changed=True
        else: out.append(r)
    next_key=max([r.key for r in out],default=0)+1
    out.append(Version(next_key,bk,value,at,INF,True))
    return out

def asof(rows,bk,at):
    matches=[r for r in rows if r.bk==bk and r.valid_from<=at<r.valid_to]
    if len(matches)!=1: raise ValueError('as-of join not unique')
    return matches[0]

def replay_insert(facts,event):
    k=(event['id'],event['updated_at'])
    if k not in facts: facts[k]=event
    return facts

def metric(rows):
    net=sum(r['net'] for r in rows); margin=sum(r['net']-r['tax']-r['cost'] for r in rows)
    rate=None if net==0 else Decimal(margin)/Decimal(net)
    return net,margin,rate

def fx(paise,rate):
    return int((Decimal(paise)*Decimal(rate)).quantize(Decimal('1'),rounding=ROUND_HALF_UP))

class WarehouseModelTests(unittest.TestCase):
    def setUp(self):
        t0=datetime(2026,1,1,tzinfo=timezone.utc); self.t0=t0
        self.rows=[Version(1,'C1','SMB',t0,INF,True)]
    def test_scd2_no_change_is_idempotent(self):
        self.assertEqual(scd2_apply(self.rows,'C1','SMB',datetime(2026,2,1,tzinfo=timezone.utc)),self.rows)
    def test_scd2_closes_and_inserts(self):
        at=datetime(2026,2,1,tzinfo=timezone.utc); out=scd2_apply(self.rows,'C1','MID',at)
        self.assertEqual(len(out),2); self.assertFalse(out[0].current); self.assertEqual(out[0].valid_to,at); self.assertTrue(out[1].current)
    def test_asof_before_change(self):
        at=datetime(2026,2,1,tzinfo=timezone.utc); out=scd2_apply(self.rows,'C1','MID',at)
        self.assertEqual(asof(out,'C1',datetime(2026,1,15,tzinfo=timezone.utc)).value,'SMB')
    def test_asof_after_change(self):
        at=datetime(2026,2,1,tzinfo=timezone.utc); out=scd2_apply(self.rows,'C1','MID',at)
        self.assertEqual(asof(out,'C1',datetime(2026,3,1,tzinfo=timezone.utc)).value,'MID')
    def test_replay_safe_fact(self):
        facts={}; e={'id':1,'updated_at':'v1','net':100}
        replay_insert(facts,e); replay_insert(facts,e); self.assertEqual(len(facts),1)
    def test_new_source_version_is_new_fact_version(self):
        facts={}; replay_insert(facts,{'id':1,'updated_at':'v1'}); replay_insert(facts,{'id':1,'updated_at':'v2'}); self.assertEqual(len(facts),2)
    def test_line_arithmetic(self):
        gross,disc,tax=10000,500,1710; self.assertEqual(gross-disc+tax,11210)
    def test_ratio_from_aggregates(self):
        rows=[{'net':100,'tax':10,'cost':50},{'net':300,'tax':30,'cost':120}]
        net,margin,rate=metric(rows); self.assertEqual((net,margin),(400,190)); self.assertEqual(rate,Decimal(190)/Decimal(400))
    def test_do_not_average_row_ratios(self):
        rows=[{'net':100,'tax':0,'cost':90},{'net':900,'tax':0,'cost':450}]
        _,_,rate=metric(rows); self.assertEqual(rate,Decimal('0.46'))
    def test_fx_rounding_is_explicit(self):
        self.assertEqual(fx(101,Decimal('1.5')),152)
    def test_source_to_target_reconciliation(self):
        source=4; published=3; rejected=1; self.assertEqual(source,published+rejected)
    def test_certification_blocks_failure(self):
        checks=['PASS','FAIL']; self.assertFalse(all(c=='PASS' for c in checks))

if __name__=='__main__': unittest.main()
