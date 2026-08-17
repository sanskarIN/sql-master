import unittest, hashlib
from dataclasses import dataclass
from datetime import date, timedelta

@dataclass
class Lot:
    lot_id:int; expires:date|None; on_hand:int; reserved:int=0; released:bool=True
    @property
    def available(self): return self.on_hand-self.reserved

class InventoryModel:
    def __init__(self): self.lots={}; self.movements=[]; self.commands={}
    def add_lot(self,lot): self.lots[lot.lot_id]=lot
    def move(self,key,request_hash,lot_id,delta,kind):
        if key in self.commands:
            old_hash,result=self.commands[key]
            if old_hash!=request_hash: raise ValueError('idempotency conflict')
            return result
        lot=self.lots[lot_id]
        if lot.on_hand+delta<lot.reserved: raise ValueError('insufficient unreserved stock')
        lot.on_hand+=delta
        mid=len(self.movements)+1; self.movements.append((mid,lot_id,delta,kind))
        self.commands[key]=(request_hash,mid); return mid
    def reserve_fefo(self,qty,today):
        candidates=sorted((x for x in self.lots.values() if x.released and x.available>0 and
                           (x.expires is None or x.expires>today)),
                          key=lambda x:(x.expires or date.max,x.lot_id))
        plan=[]; remaining=qty
        for lot in candidates:
            take=min(remaining,lot.available)
            if take: lot.reserved+=take; plan.append((lot.lot_id,take)); remaining-=take
            if remaining==0: break
        if remaining: 
            for lid,take in plan: self.lots[lid].reserved-=take
            raise ValueError('insufficient available stock')
        return plan
    def release(self,plan):
        for lid,qty in plan: self.lots[lid].reserved-=qty
    def transfer(self,qty,source,dest):
        self.move(f't-out-{len(self.movements)}','same',source,-qty,'TRANSFER_OUT')
        self.move(f't-in-{len(self.movements)}','same',dest,qty,'TRANSFER_IN')
    def reorder(self,available,open_po,lead_demand,reorder_point,target):
        position=available+open_po-lead_demand
        return max(0,target-position) if position<=reorder_point else 0

class InventoryTests(unittest.TestCase):
    def setUp(self):
        self.m=InventoryModel(); today=date(2026,8,6)
        self.m.add_lot(Lot(1,today+timedelta(days=20),5))
        self.m.add_lot(Lot(2,today+timedelta(days=5),4))
        self.m.add_lot(Lot(3,None,10))
        self.today=today
    def test_fefo_uses_earliest_expiry(self):
        self.assertEqual(self.m.reserve_fefo(6,self.today),[(2,4),(1,2)])
    def test_reservation_never_exceeds_on_hand(self):
        self.m.reserve_fefo(19,self.today)
        self.assertTrue(all(x.reserved<=x.on_hand for x in self.m.lots.values()))
    def test_failed_reservation_rolls_back(self):
        before=[x.reserved for x in self.m.lots.values()]
        with self.assertRaises(ValueError): self.m.reserve_fefo(20,self.today)
        self.assertEqual(before,[x.reserved for x in self.m.lots.values()])
    def test_idempotent_movement(self):
        a=self.m.move('k','h',1,2,'RECEIPT'); b=self.m.move('k','h',1,2,'RECEIPT')
        self.assertEqual(a,b); self.assertEqual(len(self.m.movements),1)
    def test_conflicting_retry_rejected(self):
        self.m.move('k','a',1,1,'RECEIPT')
        with self.assertRaises(ValueError): self.m.move('k','b',1,1,'RECEIPT')
    def test_cannot_issue_reserved_stock(self):
        self.m.reserve_fefo(5,self.today)
        with self.assertRaises(ValueError): self.m.move('issue','x',2,-1,'ISSUE')
    def test_release_restores_availability(self):
        plan=self.m.reserve_fefo(6,self.today); before=sum(x.available for x in self.m.lots.values())
        self.m.release(plan); self.assertEqual(sum(x.available for x in self.m.lots.values()),before+6)
    def test_transfer_preserves_total(self):
        total=sum(x.on_hand for x in self.m.lots.values()); self.m.transfer(2,3,1)
        self.assertEqual(sum(x.on_hand for x in self.m.lots.values()),total)
    def test_reorder_suggestion(self):
        self.assertEqual(self.m.reorder(12,5,20,10,40),43)
        self.assertEqual(self.m.reorder(50,10,5,10,40),0)
if __name__=='__main__': unittest.main()
