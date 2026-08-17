from dataclasses import dataclass, field
from hashlib import sha256
import unittest

@dataclass
class Tenant:
    tenant_id: str
    state: str = "PROVISIONING"
    route_version: int = 1
    storage_class: str = "SHARED"
    plan: str = "STARTER"
    memberships: set[str] = field(default_factory=set)
    usage: dict[str, int] = field(default_factory=dict)
    items: list[tuple[str, str]] = field(default_factory=list)

class SaaSModel:
    def __init__(self):
        self.tenants = {}
        self.commands = {}
        self.outbox = []
        self.plan_limits = {
            "STARTER": {"PROJECTS": 5, "STORAGE_MIB": 2048, "AUDIT_EXPORT": 0},
            "GROWTH": {"PROJECTS": 100, "STORAGE_MIB": 51200, "AUDIT_EXPORT": 1},
        }

    @staticmethod
    def request_hash(payload: str) -> str:
        return sha256(payload.encode()).hexdigest()

    def provision(self, tenant_id, owner_id, key, payload="{}"):
        command = (tenant_id, "PROVISION", key)
        h = self.request_hash(payload)
        if command in self.commands:
            old_h, result = self.commands[command]
            if old_h != h:
                raise ValueError("idempotency conflict")
            return result
        if tenant_id in self.tenants:
            raise ValueError("tenant already exists")
        tenant = Tenant(tenant_id=tenant_id, state="ACTIVE")
        tenant.memberships.add(owner_id)
        self.tenants[tenant_id] = tenant
        result = {"tenant_id": tenant_id, "state": "ACTIVE"}
        self.commands[command] = (h, result)
        self.outbox.append((tenant_id, "TENANT_ACTIVATED"))
        return result

    def visible_items(self, tenant_id):
        return [name for row_tenant, name in self.tenants[tenant_id].items if row_tenant == tenant_id]

    def create_item(self, tenant_id, name):
        t = self.tenants[tenant_id]
        if t.state != "ACTIVE":
            raise ValueError("tenant not active")
        limit = self.plan_limits[t.plan]["PROJECTS"]
        used = t.usage.get("PROJECTS", 0)
        if used + 1 > limit:
            raise ValueError("quota exceeded")
        t.usage["PROJECTS"] = used + 1
        t.items.append((tenant_id, name))

    def claim(self, tenant_id, feature, delta):
        t = self.tenants[tenant_id]
        limit = self.plan_limits[t.plan][feature]
        next_value = t.usage.get(feature, 0) + delta
        if next_value < 0 or next_value > limit:
            return False
        t.usage[feature] = next_value
        return True

    def upgrade(self, tenant_id, plan):
        if plan not in self.plan_limits:
            raise ValueError("unknown plan")
        self.tenants[tenant_id].plan = plan

    def move(self, tenant_id, destination, expected_route_version):
        t = self.tenants[tenant_id]
        if t.route_version != expected_route_version:
            raise ValueError("stale route")
        t.storage_class = destination
        t.route_version += 1
        return t.route_version

    def close(self, tenant_id):
        t = self.tenants[tenant_id]
        if any(v > 0 for v in t.usage.values()):
            raise ValueError("usage or data remains")
        if t.items:
            raise ValueError("data remains")
        t.state = "DELETED"

class TestSaaSModel(unittest.TestCase):
    def setUp(self):
        self.m = SaaSModel()
        self.m.provision("A", "owner-a", "k1")
        self.m.provision("B", "owner-b", "k2")

    def test_provisioning_is_atomic(self):
        self.assertEqual(self.m.tenants["A"].state, "ACTIVE")
        self.assertIn("owner-a", self.m.tenants["A"].memberships)
        self.assertIn(("A", "TENANT_ACTIVATED"), self.m.outbox)

    def test_idempotent_provisioning_returns_same_result(self):
        first = self.m.commands[("A", "PROVISION", "k1")][1]
        replay = self.m.provision("A", "owner-a", "k1")
        self.assertEqual(first, replay)
        self.assertEqual(1, self.m.outbox.count(("A", "TENANT_ACTIVATED")))

    def test_conflicting_idempotency_payload_is_rejected(self):
        with self.assertRaises(ValueError):
            self.m.provision("A", "owner-a", "k1", '{"different":true}')

    def test_tenant_rows_do_not_cross(self):
        self.m.create_item("A", "alpha")
        self.m.create_item("B", "beta")
        self.assertEqual(["alpha"], self.m.visible_items("A"))
        self.assertEqual(["beta"], self.m.visible_items("B"))

    def test_hard_quota_allows_exact_limit(self):
        for i in range(5): self.m.create_item("A", f"p{i}")
        self.assertEqual(5, self.m.tenants["A"].usage["PROJECTS"])

    def test_hard_quota_rejects_over_limit_without_increment(self):
        for i in range(5): self.m.create_item("A", f"p{i}")
        with self.assertRaises(ValueError): self.m.create_item("A", "overflow")
        self.assertEqual(5, self.m.tenants["A"].usage["PROJECTS"])

    def test_atomic_claim_rejects_overage(self):
        self.assertTrue(self.m.claim("A", "STORAGE_MIB", 2048))
        self.assertFalse(self.m.claim("A", "STORAGE_MIB", 1))
        self.assertEqual(2048, self.m.tenants["A"].usage["STORAGE_MIB"])

    def test_upgrade_changes_future_entitlement(self):
        self.m.upgrade("A", "GROWTH")
        self.assertTrue(self.m.claim("A", "STORAGE_MIB", 50000))

    def test_boolean_entitlement_differs_by_plan(self):
        self.assertEqual(0, self.m.plan_limits["STARTER"]["AUDIT_EXPORT"])
        self.m.upgrade("A", "GROWTH")
        self.assertEqual(1, self.m.plan_limits["GROWTH"]["AUDIT_EXPORT"])

    def test_suspended_tenant_cannot_write(self):
        self.m.tenants["A"].state = "SUSPENDED"
        with self.assertRaises(ValueError): self.m.create_item("A", "blocked")

    def test_route_move_requires_expected_version(self):
        self.assertEqual(2, self.m.move("A", "DEDICATED_DATABASE", 1))
        with self.assertRaises(ValueError): self.m.move("A", "SHARED", 1)

    def test_route_move_preserves_tenant_identity(self):
        self.m.move("A", "DEDICATED_SCHEMA", 1)
        self.assertIn("A", self.m.tenants)
        self.assertEqual("DEDICATED_SCHEMA", self.m.tenants["A"].storage_class)

    def test_close_rejects_remaining_data(self):
        self.m.create_item("A", "keep")
        with self.assertRaises(ValueError): self.m.close("A")

    def test_close_requires_zero_usage_and_empty_data(self):
        self.m.tenants["A"].usage = {}
        self.m.tenants["A"].items = []
        self.m.close("A")
        self.assertEqual("DELETED", self.m.tenants["A"].state)

    def test_outbox_is_tenant_scoped(self):
        self.assertEqual({"A", "B"}, {t for t, _ in self.m.outbox})

    def test_membership_is_tenant_scoped(self):
        self.assertNotIn("owner-b", self.m.tenants["A"].memberships)
        self.assertNotIn("owner-a", self.m.tenants["B"].memberships)

if __name__ == '__main__':
    unittest.main(verbosity=2)
