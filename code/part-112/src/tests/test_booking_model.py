from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo
import hashlib
import unittest

@dataclass
class Allocation:
    booking_id: int
    resource_id: int
    starts_at: datetime
    ends_at: datetime
    state: str = 'HELD'
    expires_at: datetime | None = None

class BookingModel:
    def __init__(self, resources):
        self.resources = sorted(resources)
        self.allocations = []
        self.commands = {}
        self.next_id = 1
        self.waitlist = []

    @staticmethod
    def overlaps(a_start, a_end, b_start, b_end):
        return a_start < b_end and b_start < a_end

    def release_expired(self, now):
        for a in self.allocations:
            if a.state == 'HELD' and a.expires_at is not None and a.expires_at <= now:
                a.state = 'EXPIRED'

    def hold(self, key, payload, starts_at, ends_at, now, minutes=10):
        if ends_at <= starts_at:
            raise ValueError('invalid interval')
        request_hash = hashlib.sha256(payload.encode()).hexdigest()
        if key in self.commands:
            old_hash, result = self.commands[key]
            if old_hash != request_hash:
                raise ValueError('idempotency conflict')
            return result
        self.release_expired(now)
        for resource_id in self.resources:
            conflict = any(
                a.resource_id == resource_id and a.state in {'HELD','CONFIRMED'} and
                self.overlaps(starts_at, ends_at, a.starts_at, a.ends_at)
                for a in self.allocations
            )
            if not conflict:
                booking_id = self.next_id; self.next_id += 1
                a = Allocation(booking_id, resource_id, starts_at, ends_at, 'HELD', now + timedelta(minutes=minutes))
                self.allocations.append(a)
                result = {'booking_id': booking_id, 'resource_id': resource_id}
                self.commands[key] = (request_hash, result)
                return result
        raise RuntimeError('no availability')

    def confirm(self, booking_id, now):
        a = next(x for x in self.allocations if x.booking_id == booking_id)
        if a.state != 'HELD' or a.expires_at <= now:
            raise ValueError('hold not confirmable')
        a.state = 'CONFIRMED'; a.expires_at = None

    def cancel(self, booking_id):
        a = next(x for x in self.allocations if x.booking_id == booking_id)
        if a.state not in {'HELD','CONFIRMED'}:
            raise ValueError('not cancellable')
        a.state = 'CANCELLED'

    def add_waitlist(self, customer_id, starts_at, ends_at, priority=0):
        self.waitlist.append((priority, len(self.waitlist), customer_id, starts_at, ends_at))

    def promote(self, now):
        for item in sorted(self.waitlist, key=lambda x: (-x[0], x[1])):
            _, _, customer_id, starts_at, ends_at = item
            try:
                return customer_id, self.hold(f'wait-{customer_id}', f'{customer_id}:{starts_at}:{ends_at}', starts_at, ends_at, now)
            except RuntimeError:
                continue
        return None

class BookingModelTests(unittest.TestCase):
    def setUp(self):
        self.now = datetime(2026, 8, 6, 9, 0, tzinfo=timezone.utc)
        self.start = self.now + timedelta(days=1)
        self.end = self.start + timedelta(minutes=30)

    def test_half_open_adjacent_slots_do_not_overlap(self):
        self.assertFalse(BookingModel.overlaps(self.start, self.end, self.end, self.end + timedelta(minutes=30)))

    def test_two_resources_allow_two_simultaneous_holds(self):
        m = BookingModel([1,2])
        a = m.hold('a','A',self.start,self.end,self.now)
        b = m.hold('b','B',self.start,self.end,self.now)
        self.assertNotEqual(a['resource_id'], b['resource_id'])

    def test_third_simultaneous_hold_fails(self):
        m = BookingModel([1,2])
        m.hold('a','A',self.start,self.end,self.now)
        m.hold('b','B',self.start,self.end,self.now)
        with self.assertRaises(RuntimeError): m.hold('c','C',self.start,self.end,self.now)

    def test_expired_hold_releases_capacity(self):
        m = BookingModel([1])
        first = m.hold('a','A',self.start,self.end,self.now,minutes=5)
        later = self.now + timedelta(minutes=6)
        second = m.hold('b','B',self.start,self.end,later)
        self.assertEqual(first['resource_id'], second['resource_id'])

    def test_same_idempotency_key_replays_result(self):
        m = BookingModel([1])
        first = m.hold('same','payload',self.start,self.end,self.now)
        second = m.hold('same','payload',self.start,self.end,self.now)
        self.assertEqual(first, second)
        self.assertEqual(1, len(m.allocations))

    def test_conflicting_retry_is_rejected(self):
        m = BookingModel([1])
        m.hold('same','payload-A',self.start,self.end,self.now)
        with self.assertRaises(ValueError): m.hold('same','payload-B',self.start,self.end,self.now)

    def test_confirmed_booking_survives_expiry_worker(self):
        m = BookingModel([1])
        result = m.hold('a','A',self.start,self.end,self.now,minutes=5)
        m.confirm(result['booking_id'], self.now + timedelta(minutes=1))
        m.release_expired(self.now + timedelta(hours=1))
        self.assertEqual('CONFIRMED', m.allocations[0].state)

    def test_cancel_releases_capacity(self):
        m = BookingModel([1])
        result = m.hold('a','A',self.start,self.end,self.now)
        m.cancel(result['booking_id'])
        second = m.hold('b','B',self.start,self.end,self.now)
        self.assertEqual(1, second['resource_id'])

    def test_waitlist_priority(self):
        m = BookingModel([1])
        m.add_waitlist(10,self.start,self.end,priority=1)
        m.add_waitlist(20,self.start,self.end,priority=5)
        promoted = m.promote(self.now)
        self.assertEqual(20, promoted[0])

    def test_dst_local_time_maps_to_explicit_instant(self):
        zone = ZoneInfo('Asia/Kolkata')
        local = datetime(2026, 8, 7, 10, 0, tzinfo=zone)
        self.assertEqual(datetime(2026, 8, 7, 4, 30, tzinfo=timezone.utc), local.astimezone(timezone.utc))

if __name__ == '__main__':
    unittest.main()
