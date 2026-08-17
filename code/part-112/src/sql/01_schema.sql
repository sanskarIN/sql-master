-- SQL Full Mastery - Part 112
-- Booking System with Concurrency Control
-- Primary target: PostgreSQL 15+
-- Author: Ram Sandesh

BEGIN;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE SCHEMA IF NOT EXISTS booking;
SET search_path = booking, public;

CREATE TYPE resource_state AS ENUM ('ACTIVE','MAINTENANCE','RETIRED');
CREATE TYPE booking_state AS ENUM ('HELD','CONFIRMED','CANCELLED','COMPLETED','NO_SHOW','EXPIRED');
CREATE TYPE allocation_state AS ENUM ('HELD','CONFIRMED','RELEASED','CANCELLED','EXPIRED');
CREATE TYPE waitlist_state AS ENUM ('WAITING','OFFERED','BOOKED','EXPIRED','CANCELLED');
CREATE TYPE payment_state AS ENUM ('REQUIRES_PAYMENT','AUTHORIZED','CAPTURED','FAILED','REFUNDED','VOIDED');
CREATE TYPE event_kind AS ENUM ('HELD','CONFIRMED','CANCELLED','EXPIRED','RESCHEDULED','COMPLETED','NO_SHOW','PAYMENT_UPDATED');

CREATE TABLE tenants (
    tenant_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_code      VARCHAR(40) NOT NULL UNIQUE,
    tenant_name      VARCHAR(160) NOT NULL,
    default_timezone VARCHAR(80) NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
    customer_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    external_key     VARCHAR(100) NOT NULL,
    display_name     VARCHAR(160) NOT NULL,
    email_normalized VARCHAR(254),
    active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, external_key),
    UNIQUE NULLS NOT DISTINCT (tenant_id, email_normalized)
);

CREATE TABLE resource_pools (
    resource_pool_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    pool_code        VARCHAR(50) NOT NULL,
    pool_name        VARCHAR(160) NOT NULL,
    timezone_name    VARCHAR(80) NOT NULL,
    default_duration_minutes INTEGER NOT NULL CHECK (default_duration_minutes > 0),
    hold_minutes     INTEGER NOT NULL DEFAULT 10 CHECK (hold_minutes BETWEEN 1 AND 120),
    overbook_units   INTEGER NOT NULL DEFAULT 0 CHECK (overbook_units >= 0),
    active           BOOLEAN NOT NULL DEFAULT TRUE,
    version_no       INTEGER NOT NULL DEFAULT 1 CHECK (version_no > 0),
    UNIQUE (tenant_id, pool_code)
);

CREATE TABLE resources (
    resource_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    resource_pool_id BIGINT NOT NULL REFERENCES resource_pools(resource_pool_id),
    resource_code    VARCHAR(60) NOT NULL,
    resource_name    VARCHAR(160) NOT NULL,
    state            resource_state NOT NULL DEFAULT 'ACTIVE',
    attributes_json  JSONB NOT NULL DEFAULT '{}'::jsonb,
    version_no       INTEGER NOT NULL DEFAULT 1 CHECK (version_no > 0),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, resource_code),
    UNIQUE (tenant_id, resource_id)
);

CREATE TABLE weekly_availability (
    availability_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    resource_id      BIGINT NOT NULL REFERENCES resources(resource_id),
    iso_weekday      SMALLINT NOT NULL CHECK (iso_weekday BETWEEN 1 AND 7),
    local_start      TIME NOT NULL,
    local_end        TIME NOT NULL,
    valid_from       DATE NOT NULL,
    valid_until      DATE,
    active           BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (local_end > local_start),
    CHECK (valid_until IS NULL OR valid_until >= valid_from)
);

CREATE TABLE blackout_periods (
    blackout_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    resource_id      BIGINT NOT NULL REFERENCES resources(resource_id),
    blocked_slot     TSTZRANGE NOT NULL,
    reason_code      VARCHAR(50) NOT NULL,
    created_by       BIGINT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (NOT isempty(blocked_slot))
);
ALTER TABLE blackout_periods ADD CONSTRAINT blackout_no_overlap
    EXCLUDE USING gist (tenant_id WITH =, resource_id WITH =, blocked_slot WITH &&);

CREATE TABLE booking_commands (
    booking_command_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    idempotency_key  VARCHAR(160) NOT NULL,
    command_type     VARCHAR(40) NOT NULL,
    request_hash     CHAR(64) NOT NULL,
    status_code      INTEGER,
    result_json      JSONB,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at     TIMESTAMPTZ,
    UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE bookings (
    booking_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    booking_reference VARCHAR(50) NOT NULL,
    customer_id      BIGINT NOT NULL REFERENCES customers(customer_id),
    resource_pool_id BIGINT NOT NULL REFERENCES resource_pools(resource_pool_id),
    state            booking_state NOT NULL,
    starts_at        TIMESTAMPTZ NOT NULL,
    ends_at          TIMESTAMPTZ NOT NULL,
    display_timezone VARCHAR(80) NOT NULL,
    hold_expires_at  TIMESTAMPTZ,
    party_size       INTEGER NOT NULL DEFAULT 1 CHECK (party_size > 0),
    price_minor      BIGINT NOT NULL DEFAULT 0 CHECK (price_minor >= 0),
    currency_code    CHAR(3) NOT NULL,
    policy_version   INTEGER NOT NULL,
    booking_command_id BIGINT NOT NULL UNIQUE REFERENCES booking_commands(booking_command_id),
    version_no       INTEGER NOT NULL DEFAULT 1 CHECK (version_no > 0),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmed_at     TIMESTAMPTZ,
    cancelled_at     TIMESTAMPTZ,
    CHECK (ends_at > starts_at),
    CHECK ((state = 'HELD' AND hold_expires_at IS NOT NULL) OR state <> 'HELD'),
    UNIQUE (tenant_id, booking_reference)
);

CREATE TABLE booking_allocations (
    booking_allocation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    booking_id       BIGINT NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
    resource_id      BIGINT NOT NULL REFERENCES resources(resource_id),
    occupied_slot    TSTZRANGE NOT NULL,
    state            allocation_state NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    released_at      TIMESTAMPTZ,
    CHECK (NOT isempty(occupied_slot)),
    UNIQUE (booking_id, resource_id)
);
ALTER TABLE booking_allocations ADD CONSTRAINT active_allocation_no_overlap
    EXCLUDE USING gist (
        tenant_id WITH =,
        resource_id WITH =,
        occupied_slot WITH &&
    ) WHERE (state IN ('HELD','CONFIRMED'));

CREATE TABLE payment_attempts (
    payment_attempt_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    booking_id       BIGINT NOT NULL REFERENCES bookings(booking_id),
    provider_code    VARCHAR(40) NOT NULL,
    provider_reference VARCHAR(160) NOT NULL,
    state            payment_state NOT NULL,
    amount_minor     BIGINT NOT NULL CHECK (amount_minor >= 0),
    currency_code    CHAR(3) NOT NULL,
    request_key      VARCHAR(160) NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, provider_code, provider_reference),
    UNIQUE (tenant_id, request_key)
);

CREATE TABLE cancellation_policies (
    cancellation_policy_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    resource_pool_id BIGINT NOT NULL REFERENCES resource_pools(resource_pool_id),
    policy_version   INTEGER NOT NULL,
    free_until_minutes INTEGER NOT NULL CHECK (free_until_minutes >= 0),
    fee_percent      NUMERIC(5,2) NOT NULL CHECK (fee_percent BETWEEN 0 AND 100),
    effective_from   TIMESTAMPTZ NOT NULL,
    effective_until  TIMESTAMPTZ,
    UNIQUE (tenant_id, resource_pool_id, policy_version),
    CHECK (effective_until IS NULL OR effective_until > effective_from)
);

CREATE TABLE booking_cancellations (
    booking_cancellation_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    booking_id       BIGINT NOT NULL UNIQUE REFERENCES bookings(booking_id),
    reason_code      VARCHAR(50) NOT NULL,
    fee_minor        BIGINT NOT NULL CHECK (fee_minor >= 0),
    refund_minor     BIGINT NOT NULL CHECK (refund_minor >= 0),
    cancelled_by     BIGINT,
    cancelled_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE waitlist_entries (
    waitlist_entry_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    customer_id      BIGINT NOT NULL REFERENCES customers(customer_id),
    resource_pool_id BIGINT NOT NULL REFERENCES resource_pools(resource_pool_id),
    desired_slot     TSTZRANGE NOT NULL,
    party_size       INTEGER NOT NULL DEFAULT 1 CHECK (party_size > 0),
    priority_score   INTEGER NOT NULL DEFAULT 0,
    state            waitlist_state NOT NULL DEFAULT 'WAITING',
    offered_booking_id BIGINT REFERENCES bookings(booking_id),
    offer_expires_at TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (NOT isempty(desired_slot))
);

CREATE TABLE booking_events (
    booking_event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    booking_id       BIGINT NOT NULL REFERENCES bookings(booking_id),
    event_kind       event_kind NOT NULL,
    occurred_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actor_id         BIGINT,
    event_data       JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE outbox_events (
    outbox_event_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tenant_id        BIGINT NOT NULL REFERENCES tenants(tenant_id),
    aggregate_type   VARCHAR(40) NOT NULL,
    aggregate_id     BIGINT NOT NULL,
    event_type       VARCHAR(80) NOT NULL,
    payload_json     JSONB NOT NULL,
    occurred_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at     TIMESTAMPTZ,
    attempt_count    INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    next_attempt_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, aggregate_type, aggregate_id, event_type, occurred_at)
);

CREATE INDEX ix_resources_pool_active
    ON resources (tenant_id, resource_pool_id, resource_id)
    WHERE state = 'ACTIVE';
CREATE INDEX ix_allocations_booking ON booking_allocations (tenant_id, booking_id);
CREATE INDEX ix_allocations_resource_slot ON booking_allocations USING gist (resource_id, occupied_slot);
CREATE INDEX ix_bookings_customer_history
    ON bookings (tenant_id, customer_id, starts_at DESC, booking_id DESC);
CREATE INDEX ix_holds_expiry
    ON bookings (tenant_id, hold_expires_at, booking_id)
    WHERE state = 'HELD';
CREATE INDEX ix_waitlist_claim
    ON waitlist_entries (tenant_id, resource_pool_id, priority_score DESC, created_at, waitlist_entry_id)
    WHERE state = 'WAITING';
CREATE INDEX ix_outbox_claim
    ON outbox_events (next_attempt_at, outbox_event_id)
    WHERE published_at IS NULL;

COMMIT;
