-- Demonstration plans, features, tenants, users, and memberships.
INSERT INTO saas.feature(feature_code, unit_code, enforcement_mode) VALUES
 ('PROJECTS','COUNT','HARD_QUOTA'),
 ('STORAGE_MIB','MIB','HARD_QUOTA'),
 ('AUDIT_EXPORT','BOOLEAN','BOOLEAN'),
 ('API_CALLS','COUNT','SOFT_QUOTA')
ON CONFLICT DO NOTHING;

INSERT INTO saas.plan(plan_code, display_name, billing_period, price_paise, plan_version, active_from) VALUES
 ('STARTER_V1','Starter','MONTH',99900,1,'2026-08-01T00:00:00Z'),
 ('GROWTH_V1','Growth','MONTH',299900,1,'2026-08-01T00:00:00Z')
ON CONFLICT DO NOTHING;

INSERT INTO saas.plan_entitlement(plan_code, feature_code, enabled, limit_value) VALUES
 ('STARTER_V1','PROJECTS',true,5),
 ('STARTER_V1','STORAGE_MIB',true,2048),
 ('STARTER_V1','AUDIT_EXPORT',false,NULL),
 ('STARTER_V1','API_CALLS',true,100000),
 ('GROWTH_V1','PROJECTS',true,100),
 ('GROWTH_V1','STORAGE_MIB',true,51200),
 ('GROWTH_V1','AUDIT_EXPORT',true,NULL),
 ('GROWTH_V1','API_CALLS',true,2000000)
ON CONFLICT DO NOTHING;

INSERT INTO saas.tenant(tenant_id, tenant_slug, display_name, state, storage_class, home_region, data_residency_code, activated_at)
VALUES
 ('00000000-0000-0000-0000-000000000101','blue-orbit','Blue Orbit','ACTIVE','SHARED','ap-south-1','IN',clock_timestamp()),
 ('00000000-0000-0000-0000-000000000102','cedar-labs','Cedar Labs','ACTIVE','SHARED','ap-south-1','IN',clock_timestamp())
ON CONFLICT DO NOTHING;

INSERT INTO saas.app_user(user_id, login_subject) VALUES
 ('00000000-0000-0000-0000-000000000201','oidc|owner-blue'),
 ('00000000-0000-0000-0000-000000000202','oidc|owner-cedar')
ON CONFLICT DO NOTHING;

INSERT INTO saas.membership(tenant_id,user_id,role_code,state,joined_at) VALUES
 ('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000201','OWNER','ACTIVE',clock_timestamp()),
 ('00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000202','OWNER','ACTIVE',clock_timestamp())
ON CONFLICT DO NOTHING;
