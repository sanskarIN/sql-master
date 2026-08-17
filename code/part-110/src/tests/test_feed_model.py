import unittest
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

@dataclass(frozen=True)
class Post:
    id:int; author:int; at:datetime; visibility:str='PUBLIC'; state:str='PUBLISHED'

class SocialModel:
    def __init__(self):
        self.private=set(); self.follows=set(); self.blocks=set(); self.posts=[]; self.command={}
    def follow(self,a,b,accepted=True):
        if a==b: raise ValueError('self')
        if (a,b) in self.blocks or (b,a) in self.blocks: raise ValueError('blocked')
        if accepted: self.follows.add((a,b))
    def block(self,a,b):
        if a==b: raise ValueError('self')
        self.blocks.add((a,b)); self.follows.discard((a,b)); self.follows.discard((b,a))
    def visible(self,viewer,p):
        if p.state!='PUBLISHED': return False
        if (viewer,p.author) in self.blocks or (p.author,viewer) in self.blocks: return False
        return p.author==viewer or p.visibility=='PUBLIC' or (p.visibility=='FOLLOWERS' and (viewer,p.author) in self.follows)
    def publish(self,key,request_hash,post):
        if key in self.command:
            old_hash,old_id=self.command[key]
            if old_hash!=request_hash: raise ValueError('idempotency conflict')
            return old_id
        self.command[key]=(request_hash,post.id); self.posts.append(post); return post.id
    def page(self,viewer,limit,cursor=None):
        rows=[p for p in self.posts if self.visible(viewer,p)]
        rows.sort(key=lambda p:(p.at,p.id),reverse=True)
        if cursor: rows=[p for p in rows if (p.at,p.id)<cursor]
        result=rows[:limit]
        next_cursor=(result[-1].at,result[-1].id) if result else None
        return [p.id for p in result],next_cursor

class FeedTests(unittest.TestCase):
    def setUp(self):
        self.m=SocialModel(); self.m.follow(1,2); self.m.follow(1,3)
        t=datetime(2026,8,6,10,tzinfo=timezone.utc)
        self.posts=[Post(i,2 if i%2 else 3,t+timedelta(minutes=i),'FOLLOWERS') for i in range(1,8)]
        for p in self.posts: self.m.publish(f'k{p.id}',f'h{p.id}',p)
    def test_keyset_pages_are_stable_and_disjoint(self):
        a,c=self.m.page(1,3); b,_=self.m.page(1,3,c)
        self.assertEqual(a,[7,6,5]); self.assertEqual(b,[4,3,2]); self.assertFalse(set(a)&set(b))
    def test_block_removes_visibility_both_directions(self):
        self.m.block(1,2)
        ids,_=self.m.page(1,20)
        self.assertTrue(all(next(p.author for p in self.posts if p.id==i)!=2 for i in ids))
        self.assertNotIn((1,2),self.m.follows)
    def test_private_follower_visibility(self):
        p=Post(100,9,datetime.now(timezone.utc),'FOLLOWERS'); self.m.posts.append(p)
        self.assertFalse(self.m.visible(1,p)); self.m.follow(1,9); self.assertTrue(self.m.visible(1,p))
    def test_idempotent_publish(self):
        p=Post(200,2,datetime.now(timezone.utc))
        self.assertEqual(self.m.publish('same','hash',p),200)
        self.assertEqual(self.m.publish('same','hash',p),200)
        self.assertEqual(sum(x.id==200 for x in self.m.posts),1)
    def test_conflicting_retry_rejected(self):
        p=Post(201,2,datetime.now(timezone.utc)); self.m.publish('x','a',p)
        with self.assertRaises(ValueError): self.m.publish('x','b',p)
if __name__=='__main__': unittest.main()
