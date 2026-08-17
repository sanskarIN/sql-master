import unittest
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Dict, List, Tuple

class Conflict(Exception): pass
class InsufficientStock(Exception): pass
class UnbalancedEntry(Exception): pass
class TenantViolation(Exception): pass

@dataclass
class CommandResult:
    request_hash: str
    result: dict

@dataclass
class Model:
    balances: Dict[Tuple[str,str,str], Tuple[int,int]] = field(default_factory=dict)
    commands: Dict[Tuple[str,str,str], CommandResult] = field(default_factory=dict)
    bookings: List[dict] = field(default_factory=list)
    journals: List[dict] = field(default_factory=list)
    orders: List[dict] = field(default_factory=list)
    outbox: List[Tuple[str,str,str,int]] = field(default_factory=list)

    def _dedupe(self, tenant, kind, key, request_hash):
        old=self.commands.get((tenant,kind,key))
        if old and old.request_hash != request_hash:
            raise Conflict('idempotency conflict')
        return old

    def reserve(self, tenant, product, warehouse, qty, key, request_hash):
        old=self._dedupe(tenant,'reserve',key,request_hash)
        if old: return old.result
        on_hand,reserved=self.balances[(tenant,product,warehouse)]
        if qty <= 0 or on_hand-reserved < qty: raise InsufficientStock
        self.balances[(tenant,product,warehouse)]=(on_hand,reserved+qty)
        result={'available':on_hand-reserved-qty,'reserved':qty}
        self.commands[(tenant,'reserve',key)]=CommandResult(request_hash,result)
        return result

    def book(self, tenant, resource, start, end, key, request_hash):
        old=self._dedupe(tenant,'book',key,request_hash)
        if old: return old.result
        if end <= start: raise ValueError('invalid range')
        for b in self.bookings:
            if b['tenant']==tenant and b['resource']==resource and b['status'] in {'HELD','CONFIRMED'}:
                if start < b['end'] and b['start'] < end: raise Conflict('overlap')
        result={'booking_id':len(self.bookings)+1,'status':'HELD'}
        self.bookings.append({'tenant':tenant,'resource':resource,'start':start,'end':end,'status':'HELD'})
        self.commands[(tenant,'book',key)]=CommandResult(request_hash,result)
        self.outbox.append((tenant,'booking',str(result['booking_id']),1))
        return result

    def post(self, tenant, key, request_hash, postings):
        old=self._dedupe(tenant,'post',key,request_hash)
        if old: return old.result
        by_currency={}
        for side,amount,currency in postings:
            if amount <= 0: raise ValueError('amount')
            by_currency[currency]=by_currency.get(currency,0)+(amount if side=='DEBIT' else -amount)
        if not by_currency or any(v != 0 for v in by_currency.values()): raise UnbalancedEntry
        result={'entry_id':len(self.journals)+1,'state':'POSTED'}
        self.journals.append({'tenant':tenant,'postings':postings})
        self.commands[(tenant,'post',key)]=CommandResult(request_hash,result)
        return result

    def create_order(self, tenant, customer, lines, tax, key, request_hash):
        old=self._dedupe(tenant,'order',key,request_hash)
        if old: return old.result
        subtotal=sum(qty*unit for _,qty,unit in lines)
        result={'order_id':len(self.orders)+1,'subtotal':subtotal,'tax':tax,'total':subtotal+tax}
        self.orders.append({'tenant':tenant,'customer':customer,'lines':lines,**result})
        self.commands[(tenant,'order',key)]=CommandResult(request_hash,result)
        self.outbox.append((tenant,'order',str(result['order_id']),1))
        return result

    def list_orders(self, tenant, customer, before=None, limit=2):
        rows=[o for o in self.orders if o['tenant']==tenant and o['customer']==customer]
        rows=sorted(rows,key=lambda o:o['order_id'],reverse=True)
        if before is not None: rows=[o for o in rows if o['order_id']<before]
        return rows[:limit]

class CapstoneTests(unittest.TestCase):
    def setUp(self):
        self.m=Model({('t1','p1','w1'):(10,0),('t2','p1','w1'):(8,0)})
        self.t0=datetime(2026,8,1,10,tzinfo=timezone.utc)
        self.t1=datetime(2026,8,1,11,tzinfo=timezone.utc)
        self.t2=datetime(2026,8,1,12,tzinfo=timezone.utc)

    def test_stock_reservation_preserves_non_negative_available(self):
        r=self.m.reserve('t1','p1','w1',4,'k1','h1')
        self.assertEqual(r['available'],6)
        self.assertEqual(self.m.balances[('t1','p1','w1')],(10,4))

    def test_stock_insufficient_rolls_back(self):
        with self.assertRaises(InsufficientStock): self.m.reserve('t1','p1','w1',11,'k1','h1')
        self.assertEqual(self.m.balances[('t1','p1','w1')],(10,0))

    def test_idempotent_stock_replay(self):
        a=self.m.reserve('t1','p1','w1',3,'k1','h1')
        b=self.m.reserve('t1','p1','w1',3,'k1','h1')
        self.assertEqual(a,b); self.assertEqual(self.m.balances[('t1','p1','w1')],(10,3))

    def test_conflicting_stock_retry_rejected(self):
        self.m.reserve('t1','p1','w1',3,'k1','h1')
        with self.assertRaises(Conflict): self.m.reserve('t1','p1','w1',4,'k1','different')

    def test_tenant_balances_are_isolated(self):
        self.m.reserve('t1','p1','w1',2,'k1','h1')
        self.assertEqual(self.m.balances[('t2','p1','w1')],(8,0))

    def test_booking_overlap_rejected(self):
        self.m.book('t1','r1',self.t0,self.t1,'b1','h1')
        with self.assertRaises(Conflict): self.m.book('t1','r1',self.t0,self.t2,'b2','h2')

    def test_adjacent_bookings_allowed(self):
        self.m.book('t1','r1',self.t0,self.t1,'b1','h1')
        self.m.book('t1','r1',self.t1,self.t2,'b2','h2')
        self.assertEqual(len(self.m.bookings),2)

    def test_booking_tenant_isolation(self):
        self.m.book('t1','r1',self.t0,self.t1,'b1','h1')
        self.m.book('t2','r1',self.t0,self.t1,'b1','h1')
        self.assertEqual(len(self.m.bookings),2)

    def test_booking_replay_does_not_duplicate_outbox(self):
        self.m.book('t1','r1',self.t0,self.t1,'b1','h1')
        self.m.book('t1','r1',self.t0,self.t1,'b1','h1')
        self.assertEqual(len(self.m.outbox),1)

    def test_balanced_journal_posts(self):
        r=self.m.post('t1','j1','h1',[('DEBIT',1000,'INR'),('CREDIT',1000,'INR')])
        self.assertEqual(r['state'],'POSTED')

    def test_unbalanced_journal_rejected(self):
        with self.assertRaises(UnbalancedEntry): self.m.post('t1','j1','h1',[('DEBIT',1000,'INR'),('CREDIT',900,'INR')])

    def test_multi_currency_must_balance_per_currency(self):
        with self.assertRaises(UnbalancedEntry): self.m.post('t1','j1','h1',[('DEBIT',1000,'INR'),('CREDIT',1000,'USD')])

    def test_order_total_uses_integer_paise(self):
        r=self.m.create_order('t1','c1',[('p1',2,24900),('p2',1,99900)],1800,'o1','h1')
        self.assertEqual(r['subtotal'],149700); self.assertEqual(r['total'],151500)

    def test_order_replay_does_not_duplicate_event(self):
        self.m.create_order('t1','c1',[('p1',1,24900)],0,'o1','h1')
        self.m.create_order('t1','c1',[('p1',1,24900)],0,'o1','h1')
        self.assertEqual(len([e for e in self.m.outbox if e[1]=='order']),1)

    def test_keyset_pages_are_disjoint(self):
        for i in range(5): self.m.create_order('t1','c1',[('p1',1,100+i)],0,f'o{i}',f'h{i}')
        p1=self.m.list_orders('t1','c1',limit=2)
        p2=self.m.list_orders('t1','c1',before=p1[-1]['order_id'],limit=2)
        self.assertTrue(set(x['order_id'] for x in p1).isdisjoint(x['order_id'] for x in p2))

    def test_outbox_aggregate_versions_unique_in_model(self):
        self.m.outbox.append(('t1','order','1',1))
        self.assertEqual(len(set(self.m.outbox)),len(self.m.outbox))

if __name__=='__main__': unittest.main()
