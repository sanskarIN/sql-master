-- SQL Full Mastery - Part 114
-- Multi-Tenant SaaS Database - PostgreSQL reference schema
-- Author: Ram Sandesh

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS saas;

CREATE TYPE saas.tenant_state AS ENUM ('PROVISIONING','ACTIVE','SUSPENDED','CLOSING','DELETED');
CREATE TYPE saas.subscription_state AS ENUM ('TRIAL','ACTIVE','PAST_DUE','PAUSED','CANCELLED');
CREATE TYPE saas.command_state AS ENUM ('STARTED','SUCCEEDED','FAILED');

CREATE TABLE saas.tenant (
  tenant_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_slug text NOT NULL UNIQUE,
  display_name text NOT NULL,
  state saas.tenant_state NOT NULL DEFAULT 'PROVISIONING',
  storage_class text NOT NULL DEFAULT 'SHARED' CHECK (storage_class IN ('SHARED','DEDICATED_SCHEMA','DEDICATED_DATABASE')),
  home_region text NOT NULL,
  data_residency_code text NOT NULL,
  lifecycle_version bigint NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  activated_at timestamptz,
  closed_at timestamptz
);

CREATE TABLE saas.app_user (
  user_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  login_subject text NOT NULL UNIQUE,
  email_ciphertext bytea,
  state text NOT NULL DEFAULT 'ACTIVE' CHECK (state IN ('ACTIVE','DISABLED','DELETED')),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE saas.membership (
  tenant_id uuid NOT NULL REFERENCES saas.tenant(tenant_id),
  user_id uuid NOT NULL REFERENCES saas.app_user(user_id),
  role_code text NOT NULL CHECK (role_code IN ('OWNER','ADMIN','BILLING','MEMBER','READ_ONLY')),
  state text NOT NULL DEFAULT 'ACTIVE' CHECK (state IN ('INVITED','ACTIVE','SUSPENDED','REMOVED')),
  membership_version bigint NOT NULL DEFAULT 1,
  joined_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, user_id)
);

CREATE TABLE saas.plan (
  plan_code text PRIMARY KEY,
  display_name text NOT NULL,
  billing_period text NOT NULL CHECK (billing_period IN ('MONTH','YEAR')),
  price_paise bigint NOT NULL CHECK (price_paise >= 0),
  plan_version bigint NOT NULL,
  active_from timestamptz NOT NULL,
  active_to timestamptz
);

CREATE TABLE saas.feature (
  feature_code text PRIMARY KEY,
  unit_code text NOT NULL,
  enforcement_mode text NOT NULL CHECK (enforcement_mode IN ('BOOLEAN','HARD_QUOTA','SOFT_QUOTA','METER_ONLY'))
);

CREATE TABLE saas.plan_entitlement (
  plan_code text NOT NULL REFERENCES saas.plan(plan_code),
  feature_code text NOT NULL REFERENCES saas.feature(feature_code),
  enabled boolean NOT NULL,
  limit_value bigint,
  PRIMARY KEY (plan_code, feature_code),
  CHECK ((enabled AND limit_value IS NULL) OR enabled OR limit_value IS NULL)
);

CREATE TABLE saas.subscription (
  subscription_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES saas.tenant(tenant_id),
  plan_code text NOT NULL REFERENCES saas.plan(plan_code),
  state saas.subscription_state NOT NULL,
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  subscription_version bigint NOT NULL DEFAULT 1,
  UNIQUE (tenant_id, period_start),
  CHECK (period_end > period_start)
);

CREATE TABLE saas.usage_counter (
  tenant_id uuid NOT NULL REFERENCES saas.tenant(tenant_id),
  feature_code text NOT NULL REFERENCES saas.feature(feature_code),
  period_start date NOT NULL,
  used_value bigint NOT NULL DEFAULT 0 CHECK (used_value >= 0),
  counter_version bigint NOT NULL DEFAULT 1,
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, feature_code, period_start)
);

CREATE TABLE saas.workspace_item (
  tenant_id uuid NOT NULL REFERENCES saas.tenant(tenant_id),
  item_id uuid NOT NULL DEFAULT gen_random_uuid(),
  item_name text NOT NULL,
  item_state text NOT NULL DEFAULT 'ACTIVE' CHECK (item_state IN ('ACTIVE','ARCHIVED','DELETED')),
  created_by uuid NOT NULL REFERENCES saas.app_user(user_id),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  row_version bigint NOT NULL DEFAULT 1,
  PRIMARY KEY (tenant_id, item_id)
);
CREATE INDEX ix_workspace_item_tenant_created ON saas.workspace_item(tenant_id, created_at DESC, item_id DESC);

CREATE TABLE saas.idempotency_command (
  tenant_id uuid NOT NULL REFERENCES saas.tenant(tenant_id),
  command_name text NOT NULL,
  idempotency_key text NOT NULL,
  request_hash text NOT NULL,
  state saas.command_state NOT NULL,
  response_json jsonb,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  completed_at timestamptz,
  PRIMARY KEY (tenant_id, command_name, idempotency_key)
);

CREATE TABLE saas.invoice (
  tenant_id uuid NOT NULL REFERENCES saas.tenant(tenant_id),
  invoice_id uuid NOT NULL DEFAULT gen_random_uuid(),
  subscription_id uuid NOT NULL REFERENCES saas.subscription(subscription_id),
  currency_code char(3) NOT NULL,
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  subtotal_paise bigint NOT NULL CHECK (subtotal_paise >= 0),
  tax_paise bigint NOT NULL CHECK (tax_paise >= 0),
  total_paise bigint GENERATED ALWAYS AS (subtotal_paise + tax_paise) STORED,
  state text NOT NULL CHECK (state IN ('DRAFT','ISSUED','PAID','VOID')),
  PRIMARY KEY (tenant_id, invoice_id),
  CHECK (period_end > period_start)
);

CREATE TABLE saas.outbox_event (
  tenant_id uuid NOT NULL REFERENCES saas.tenant(tenant_id),
  event_id uuid NOT NULL DEFAULT gen_random_uuid(),
  aggregate_type text NOT NULL,
  aggregate_id text NOT NULL,
  event_type text NOT NULL,
  payload jsonb NOT NULL,
  occurred_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  published_at timestamptz,
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  PRIMARY KEY (tenant_id, event_id)
);
CREATE INDEX ix_outbox_unpublished ON saas.outbox_event(occurred_at, event_id) WHERE published_at IS NULL;

CREATE TABLE saas.audit_event (
  tenant_id uuid NOT NULL REFERENCES saas.tenant(tenant_id),
  audit_id bigint GENERATED ALWAYS AS IDENTITY,
  actor_user_id uuid,
  action_code text NOT NULL,
  object_type text NOT NULL,
  object_id text NOT NULL,
  decision text NOT NULL,
  request_id text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  occurred_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY (tenant_id, audit_id)
);

-- Shared-table isolation. The application must SET LOCAL app.tenant_id inside each transaction.
ALTER TABLE saas.workspace_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas.usage_counter ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas.invoice ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas.outbox_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE saas.audit_event ENABLE ROW LEVEL SECURITY;

CREATE POLICY workspace_item_tenant_policy ON saas.workspace_item
  USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
  WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY usage_counter_tenant_policy ON saas.usage_counter
  USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
  WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY invoice_tenant_policy ON saas.invoice
  USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
  WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY outbox_tenant_policy ON saas.outbox_event
  USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
  WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY audit_tenant_policy ON saas.audit_event
  USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
  WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
