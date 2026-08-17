-- AtlasOps Production Database Capstone
-- PostgreSQL 16 reference schema
-- Author: Ram Sandesh

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS catalog;
CREATE SCHEMA IF NOT EXISTS inventory;
CREATE SCHEMA IF NOT EXISTS booking;
CREATE SCHEMA IF NOT EXISTS commerce;
CREATE SCHEMA IF NOT EXISTS ledger;
CREATE SCHEMA IF NOT EXISTS integration;
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TYPE core.lifecycle_state AS ENUM ('ACTIVE','SUSPENDED','CLOSED');
CREATE TYPE booking.reservation_state AS ENUM ('HELD','CONFIRMED','CANCELLED','EXPIRED');
CREATE TYPE commerce.order_state AS ENUM ('PENDING','CONFIRMED','CANCELLED','FULFILLED');
CREATE TYPE ledger.entry_state AS ENUM ('DRAFT','POSTED','REVERSED');
CREATE TYPE ledger.posting_side AS ENUM ('DEBIT','CREDIT');

CREATE TABLE core.tenant (
    tenant_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_code text NOT NULL UNIQUE CHECK (tenant_code ~ '^[a-z0-9][a-z0-9-]{2,39}$'),
    tenant_name text NOT NULL,
    lifecycle_state core.lifecycle_state NOT NULL DEFAULT 'ACTIVE',
    created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE core.app_user (
    user_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text NOT NULL,
    display_name text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (lower(email))
);

CREATE TABLE core.membership (
    tenant_id uuid NOT NULL REFERENCES core.tenant(tenant_id),
    user_id uuid NOT NULL REFERENCES core.app_user(user_id),
    role_code text NOT NULL CHECK (role_code IN ('ADMIN','OPERATOR','FINANCE','VIEWER')),
    active boolean NOT NULL DEFAULT true,
    granted_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY (tenant_id, user_id)
);

CREATE TABLE core.command_deduplication (
    tenant_id uuid NOT NULL REFERENCES core.tenant(tenant_id),
    command_type text NOT NULL,
    idempotency_key text NOT NULL,
    request_hash text NOT NULL,
    status text NOT NULL CHECK (status IN ('STARTED','SUCCEEDED','FAILED')),
    result jsonb,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    completed_at timestamptz,
    PRIMARY KEY (tenant_id, command_type, idempotency_key)
);

CREATE TABLE catalog.product (
    tenant_id uuid NOT NULL REFERENCES core.tenant(tenant_id),
    product_id uuid NOT NULL DEFAULT gen_random_uuid(),
    sku text NOT NULL,
    product_name text NOT NULL,
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY (tenant_id, product_id),
    UNIQUE (tenant_id, sku)
);

CREATE TABLE catalog.product_price (
    tenant_id uuid NOT NULL,
    product_id uuid NOT NULL,
    valid_from timestamptz NOT NULL,
    valid_to timestamptz,
    unit_price_paise bigint NOT NULL CHECK (unit_price_paise >= 0),
    currency_code char(3) NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
    PRIMARY KEY (tenant_id, product_id, valid_from),
    FOREIGN KEY (tenant_id, product_id) REFERENCES catalog.product(tenant_id, product_id),
    CHECK (valid_to IS NULL OR valid_to > valid_from)
);

CREATE TABLE inventory.warehouse (
    tenant_id uuid NOT NULL REFERENCES core.tenant(tenant_id),
    warehouse_id uuid NOT NULL DEFAULT gen_random_uuid(),
    warehouse_code text NOT NULL,
    warehouse_name text NOT NULL,
    PRIMARY KEY (tenant_id, warehouse_id),
    UNIQUE (tenant_id, warehouse_code)
);

CREATE TABLE inventory.stock_balance (
    tenant_id uuid NOT NULL,
    product_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    on_hand_qty bigint NOT NULL DEFAULT 0 CHECK (on_hand_qty >= 0),
    reserved_qty bigint NOT NULL DEFAULT 0 CHECK (reserved_qty >= 0),
    row_version bigint NOT NULL DEFAULT 0,
    PRIMARY KEY (tenant_id, product_id, warehouse_id),
    FOREIGN KEY (tenant_id, product_id) REFERENCES catalog.product(tenant_id, product_id),
    FOREIGN KEY (tenant_id, warehouse_id) REFERENCES inventory.warehouse(tenant_id, warehouse_id),
    CHECK (reserved_qty <= on_hand_qty)
);

CREATE TABLE inventory.stock_movement (
    tenant_id uuid NOT NULL,
    movement_id uuid NOT NULL DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL,
    warehouse_id uuid NOT NULL,
    movement_type text NOT NULL CHECK (movement_type IN ('RECEIPT','RESERVE','RELEASE','SHIP','ADJUSTMENT','TRANSFER_IN','TRANSFER_OUT')),
    quantity_delta bigint NOT NULL CHECK (quantity_delta <> 0),
    command_key text NOT NULL,
    occurred_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    reference_type text,
    reference_id uuid,
    PRIMARY KEY (tenant_id, movement_id),
    UNIQUE (tenant_id, command_key),
    FOREIGN KEY (tenant_id, product_id, warehouse_id) REFERENCES inventory.stock_balance(tenant_id, product_id, warehouse_id)
);

CREATE TABLE booking.resource (
    tenant_id uuid NOT NULL REFERENCES core.tenant(tenant_id),
    resource_id uuid NOT NULL DEFAULT gen_random_uuid(),
    resource_code text NOT NULL,
    resource_name text NOT NULL,
    time_zone text NOT NULL DEFAULT 'UTC',
    active boolean NOT NULL DEFAULT true,
    PRIMARY KEY (tenant_id, resource_id),
    UNIQUE (tenant_id, resource_code)
);

CREATE TABLE booking.reservation (
    tenant_id uuid NOT NULL,
    reservation_id uuid NOT NULL DEFAULT gen_random_uuid(),
    resource_id uuid NOT NULL,
    customer_ref text NOT NULL,
    starts_at timestamptz NOT NULL,
    ends_at timestamptz NOT NULL,
    status booking.reservation_state NOT NULL,
    hold_expires_at timestamptz,
    idempotency_key text NOT NULL,
    request_hash text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY (tenant_id, reservation_id),
    UNIQUE (tenant_id, idempotency_key),
    FOREIGN KEY (tenant_id, resource_id) REFERENCES booking.resource(tenant_id, resource_id),
    CHECK (ends_at > starts_at),
    CHECK ((status = 'HELD' AND hold_expires_at IS NOT NULL) OR status <> 'HELD'),
    EXCLUDE USING gist (
      tenant_id WITH =,
      resource_id WITH =,
      tstzrange(starts_at, ends_at, '[)') WITH &&
    ) WHERE (status IN ('HELD','CONFIRMED'))
);

CREATE TABLE commerce.sales_order (
    tenant_id uuid NOT NULL REFERENCES core.tenant(tenant_id),
    order_id uuid NOT NULL DEFAULT gen_random_uuid(),
    customer_ref text NOT NULL,
    status commerce.order_state NOT NULL DEFAULT 'PENDING',
    currency_code char(3) NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
    subtotal_paise bigint NOT NULL CHECK (subtotal_paise >= 0),
    tax_paise bigint NOT NULL CHECK (tax_paise >= 0),
    total_paise bigint GENERATED ALWAYS AS (subtotal_paise + tax_paise) STORED,
    idempotency_key text NOT NULL,
    request_hash text NOT NULL,
    row_version bigint NOT NULL DEFAULT 0,
    ordered_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY (tenant_id, order_id),
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE commerce.sales_order_line (
    tenant_id uuid NOT NULL,
    order_id uuid NOT NULL,
    line_no integer NOT NULL CHECK (line_no > 0),
    product_id uuid NOT NULL,
    sku_snapshot text NOT NULL,
    product_name_snapshot text NOT NULL,
    quantity bigint NOT NULL CHECK (quantity > 0),
    unit_price_paise bigint NOT NULL CHECK (unit_price_paise >= 0),
    line_total_paise bigint GENERATED ALWAYS AS (quantity * unit_price_paise) STORED,
    PRIMARY KEY (tenant_id, order_id, line_no),
    FOREIGN KEY (tenant_id, order_id) REFERENCES commerce.sales_order(tenant_id, order_id) ON DELETE RESTRICT,
    FOREIGN KEY (tenant_id, product_id) REFERENCES catalog.product(tenant_id, product_id)
);

CREATE TABLE ledger.account (
    tenant_id uuid NOT NULL REFERENCES core.tenant(tenant_id),
    account_id uuid NOT NULL DEFAULT gen_random_uuid(),
    account_code text NOT NULL,
    account_name text NOT NULL,
    currency_code char(3) NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
    PRIMARY KEY (tenant_id, account_id),
    UNIQUE (tenant_id, account_code)
);

CREATE TABLE ledger.journal_entry (
    tenant_id uuid NOT NULL REFERENCES core.tenant(tenant_id),
    entry_id uuid NOT NULL DEFAULT gen_random_uuid(),
    entry_state ledger.entry_state NOT NULL DEFAULT 'DRAFT',
    effective_at timestamptz NOT NULL,
    description text NOT NULL,
    idempotency_key text NOT NULL,
    request_hash text NOT NULL,
    reversal_of_entry_id uuid,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    posted_at timestamptz,
    PRIMARY KEY (tenant_id, entry_id),
    UNIQUE (tenant_id, idempotency_key),
    UNIQUE (tenant_id, reversal_of_entry_id),
    FOREIGN KEY (tenant_id, reversal_of_entry_id) REFERENCES ledger.journal_entry(tenant_id, entry_id)
);

CREATE TABLE ledger.posting (
    tenant_id uuid NOT NULL,
    entry_id uuid NOT NULL,
    posting_no integer NOT NULL CHECK (posting_no > 0),
    account_id uuid NOT NULL,
    side ledger.posting_side NOT NULL,
    amount_paise bigint NOT NULL CHECK (amount_paise > 0),
    currency_code char(3) NOT NULL CHECK (currency_code ~ '^[A-Z]{3}$'),
    PRIMARY KEY (tenant_id, entry_id, posting_no),
    FOREIGN KEY (tenant_id, entry_id) REFERENCES ledger.journal_entry(tenant_id, entry_id),
    FOREIGN KEY (tenant_id, account_id) REFERENCES ledger.account(tenant_id, account_id)
);

CREATE TABLE integration.outbox_event (
    tenant_id uuid NOT NULL REFERENCES core.tenant(tenant_id),
    event_id uuid NOT NULL DEFAULT gen_random_uuid(),
    aggregate_type text NOT NULL,
    aggregate_id uuid NOT NULL,
    event_type text NOT NULL,
    event_version integer NOT NULL CHECK (event_version > 0),
    payload jsonb NOT NULL,
    occurred_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    published_at timestamptz,
    attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    PRIMARY KEY (tenant_id, event_id),
    UNIQUE (tenant_id, aggregate_type, aggregate_id, event_version)
);

CREATE TABLE audit.audit_event (
    audit_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id uuid,
    actor_user_id uuid,
    action_code text NOT NULL,
    object_type text NOT NULL,
    object_id text NOT NULL,
    occurred_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    request_id text,
    details jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX ix_order_customer_keyset ON commerce.sales_order
(tenant_id, customer_ref, ordered_at DESC, order_id DESC)
INCLUDE (status, total_paise);

CREATE INDEX ix_outbox_pending ON integration.outbox_event
(occurred_at, event_id) WHERE published_at IS NULL;

CREATE INDEX ix_posting_statement ON ledger.posting
(tenant_id, account_id, entry_id, posting_no) INCLUDE (side, amount_paise, currency_code);

COMMIT;
