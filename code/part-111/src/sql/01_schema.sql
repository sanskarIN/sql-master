-- SQL Full Mastery - Part 111
-- Inventory, Warehousing, and Purchase Planning
-- Primary target: PostgreSQL 15+
-- Author: Ram Sandesh

BEGIN;
CREATE SCHEMA IF NOT EXISTS inventory;
SET search_path = inventory, public;

CREATE TYPE product_state AS ENUM ('DRAFT','ACTIVE','DISCONTINUED');
CREATE TYPE warehouse_state AS ENUM ('ACTIVE','CLOSED');
CREATE TYPE bin_kind AS ENUM ('RECEIVING','STORAGE','PICK','QUARANTINE','SHIPPING','ADJUSTMENT');
CREATE TYPE movement_kind AS ENUM ('RECEIPT','ISSUE','TRANSFER_OUT','TRANSFER_IN','ADJUSTMENT','RETURN_IN','RETURN_OUT');
CREATE TYPE reservation_state AS ENUM ('ACTIVE','PARTIALLY_FULFILLED','FULFILLED','RELEASED','EXPIRED','CANCELLED');
CREATE TYPE transfer_state AS ENUM ('DRAFT','DISPATCHED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED');
CREATE TYPE po_state AS ENUM ('DRAFT','APPROVED','SENT','PARTIALLY_RECEIVED','RECEIVED','CANCELLED','CLOSED');
CREATE TYPE receipt_state AS ENUM ('OPEN','POSTED','VOIDED');
CREATE TYPE count_state AS ENUM ('PLANNED','COUNTING','REVIEW','POSTED','CANCELLED');

CREATE TABLE products (
    product_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku              VARCHAR(64) NOT NULL,
    normalized_sku   VARCHAR(64) NOT NULL,
    product_name     VARCHAR(200) NOT NULL,
    base_uom         VARCHAR(16) NOT NULL,
    tracking_mode    VARCHAR(12) NOT NULL DEFAULT 'NONE'
                     CHECK (tracking_mode IN ('NONE','LOT','SERIAL')),
    shelf_life_days  INTEGER CHECK (shelf_life_days IS NULL OR shelf_life_days > 0),
    state            product_state NOT NULL DEFAULT 'DRAFT',
    version_no       INTEGER NOT NULL DEFAULT 1 CHECK (version_no > 0),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (normalized_sku = lower(normalized_sku)),
    UNIQUE (normalized_sku)
);

CREATE TABLE warehouses (
    warehouse_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_code   VARCHAR(30) NOT NULL UNIQUE,
    warehouse_name   VARCHAR(160) NOT NULL,
    timezone_name    VARCHAR(80) NOT NULL,
    state            warehouse_state NOT NULL DEFAULT 'ACTIVE',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bins (
    bin_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_id     BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    bin_code         VARCHAR(50) NOT NULL,
    kind             bin_kind NOT NULL,
    is_pickable      BOOLEAN NOT NULL DEFAULT FALSE,
    is_countable     BOOLEAN NOT NULL DEFAULT TRUE,
    capacity_units   NUMERIC(20,6) CHECK (capacity_units IS NULL OR capacity_units >= 0),
    active           BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (warehouse_id, bin_code)
);

CREATE TABLE inventory_lots (
    lot_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id       BIGINT NOT NULL REFERENCES products(product_id),
    supplier_lot_code VARCHAR(100),
    manufactured_on  DATE,
    expires_on       DATE,
    quality_state    VARCHAR(16) NOT NULL DEFAULT 'RELEASED'
                     CHECK (quality_state IN ('PENDING','RELEASED','QUARANTINED','REJECTED')),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (expires_on IS NULL OR manufactured_on IS NULL OR expires_on >= manufactured_on),
    UNIQUE (product_id, supplier_lot_code)
);

CREATE TABLE stock_movements (
    movement_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    command_id       UUID NOT NULL,
    occurred_at      TIMESTAMPTZ NOT NULL,
    posted_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    product_id       BIGINT NOT NULL REFERENCES products(product_id),
    warehouse_id     BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    bin_id           BIGINT NOT NULL REFERENCES bins(bin_id),
    lot_id           BIGINT REFERENCES inventory_lots(lot_id),
    movement_kind    movement_kind NOT NULL,
    quantity_delta   NUMERIC(20,6) NOT NULL CHECK (quantity_delta <> 0),
    reference_type   VARCHAR(40) NOT NULL,
    reference_id     BIGINT NOT NULL,
    reason_code      VARCHAR(50),
    actor_id         BIGINT,
    reversal_of_movement_id BIGINT UNIQUE REFERENCES stock_movements(movement_id),
    metadata_json    JSONB NOT NULL DEFAULT '{}'::jsonb,
    UNIQUE (command_id, product_id, bin_id, COALESCE(lot_id, 0), movement_kind)
);

CREATE TABLE stock_balances (
    product_id       BIGINT NOT NULL REFERENCES products(product_id),
    bin_id           BIGINT NOT NULL REFERENCES bins(bin_id),
    lot_id           BIGINT REFERENCES inventory_lots(lot_id),
    on_hand_qty      NUMERIC(20,6) NOT NULL DEFAULT 0,
    reserved_qty     NUMERIC(20,6) NOT NULL DEFAULT 0 CHECK (reserved_qty >= 0),
    version_no       BIGINT NOT NULL DEFAULT 1 CHECK (version_no > 0),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (product_id, bin_id, lot_id),
    CHECK (on_hand_qty >= 0),
    CHECK (reserved_qty <= on_hand_qty)
);

CREATE TABLE reservation_headers (
    reservation_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    request_key      VARCHAR(160) NOT NULL UNIQUE,
    request_hash     CHAR(64) NOT NULL,
    owner_type       VARCHAR(30) NOT NULL,
    owner_id         BIGINT NOT NULL,
    warehouse_id     BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    state            reservation_state NOT NULL DEFAULT 'ACTIVE',
    expires_at       TIMESTAMPTZ NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at     TIMESTAMPTZ
);

CREATE TABLE reservation_lines (
    reservation_line_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    reservation_id   BIGINT NOT NULL REFERENCES reservation_headers(reservation_id) ON DELETE CASCADE,
    product_id       BIGINT NOT NULL REFERENCES products(product_id),
    bin_id           BIGINT NOT NULL REFERENCES bins(bin_id),
    lot_id           BIGINT REFERENCES inventory_lots(lot_id),
    reserved_qty     NUMERIC(20,6) NOT NULL CHECK (reserved_qty > 0),
    fulfilled_qty    NUMERIC(20,6) NOT NULL DEFAULT 0 CHECK (fulfilled_qty >= 0),
    released_qty     NUMERIC(20,6) NOT NULL DEFAULT 0 CHECK (released_qty >= 0),
    CHECK (fulfilled_qty + released_qty <= reserved_qty),
    UNIQUE (reservation_id, product_id, bin_id, lot_id)
);

CREATE TABLE transfers (
    transfer_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transfer_number  VARCHAR(50) NOT NULL UNIQUE,
    from_warehouse_id BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    to_warehouse_id  BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    state            transfer_state NOT NULL DEFAULT 'DRAFT',
    requested_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dispatched_at    TIMESTAMPTZ,
    received_at      TIMESTAMPTZ,
    version_no       INTEGER NOT NULL DEFAULT 1,
    CHECK (from_warehouse_id <> to_warehouse_id)
);

CREATE TABLE transfer_lines (
    transfer_line_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transfer_id      BIGINT NOT NULL REFERENCES transfers(transfer_id) ON DELETE CASCADE,
    product_id       BIGINT NOT NULL REFERENCES products(product_id),
    lot_id           BIGINT REFERENCES inventory_lots(lot_id),
    requested_qty    NUMERIC(20,6) NOT NULL CHECK (requested_qty > 0),
    dispatched_qty   NUMERIC(20,6) NOT NULL DEFAULT 0 CHECK (dispatched_qty >= 0),
    received_qty     NUMERIC(20,6) NOT NULL DEFAULT 0 CHECK (received_qty >= 0),
    CHECK (dispatched_qty <= requested_qty),
    CHECK (received_qty <= dispatched_qty)
);

CREATE TABLE suppliers (
    supplier_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_code    VARCHAR(40) NOT NULL UNIQUE,
    supplier_name    VARCHAR(200) NOT NULL,
    active           BOOLEAN NOT NULL DEFAULT TRUE,
    default_currency CHAR(3) NOT NULL,
    lead_time_days   INTEGER NOT NULL DEFAULT 0 CHECK (lead_time_days >= 0),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_suppliers (
    product_id       BIGINT NOT NULL REFERENCES products(product_id),
    supplier_id      BIGINT NOT NULL REFERENCES suppliers(supplier_id),
    supplier_sku     VARCHAR(80),
    min_order_qty    NUMERIC(20,6) NOT NULL DEFAULT 1 CHECK (min_order_qty > 0),
    order_multiple   NUMERIC(20,6) NOT NULL DEFAULT 1 CHECK (order_multiple > 0),
    unit_cost_minor  BIGINT NOT NULL CHECK (unit_cost_minor >= 0),
    preferred_rank   SMALLINT NOT NULL DEFAULT 1 CHECK (preferred_rank > 0),
    active           BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (product_id, supplier_id)
);

CREATE TABLE purchase_orders (
    purchase_order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    po_number         VARCHAR(50) NOT NULL UNIQUE,
    supplier_id       BIGINT NOT NULL REFERENCES suppliers(supplier_id),
    warehouse_id      BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    state             po_state NOT NULL DEFAULT 'DRAFT',
    currency_code     CHAR(3) NOT NULL,
    ordered_at        TIMESTAMPTZ,
    expected_on       DATE,
    approved_by       BIGINT,
    version_no        INTEGER NOT NULL DEFAULT 1,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE purchase_order_lines (
    purchase_order_line_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    purchase_order_id BIGINT NOT NULL REFERENCES purchase_orders(purchase_order_id) ON DELETE CASCADE,
    line_no          INTEGER NOT NULL CHECK (line_no > 0),
    product_id       BIGINT NOT NULL REFERENCES products(product_id),
    ordered_qty      NUMERIC(20,6) NOT NULL CHECK (ordered_qty > 0),
    received_qty     NUMERIC(20,6) NOT NULL DEFAULT 0 CHECK (received_qty >= 0),
    cancelled_qty    NUMERIC(20,6) NOT NULL DEFAULT 0 CHECK (cancelled_qty >= 0),
    unit_cost_minor  BIGINT NOT NULL CHECK (unit_cost_minor >= 0),
    tax_minor        BIGINT NOT NULL DEFAULT 0 CHECK (tax_minor >= 0),
    CHECK (received_qty + cancelled_qty <= ordered_qty),
    UNIQUE (purchase_order_id, line_no)
);

CREATE TABLE receipts (
    receipt_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    receipt_number   VARCHAR(50) NOT NULL UNIQUE,
    purchase_order_id BIGINT REFERENCES purchase_orders(purchase_order_id),
    warehouse_id     BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    state            receipt_state NOT NULL DEFAULT 'OPEN',
    supplier_document VARCHAR(100),
    received_at      TIMESTAMPTZ NOT NULL,
    posted_at        TIMESTAMPTZ,
    received_by      BIGINT
);

CREATE TABLE receipt_lines (
    receipt_line_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    receipt_id       BIGINT NOT NULL REFERENCES receipts(receipt_id) ON DELETE CASCADE,
    purchase_order_line_id BIGINT REFERENCES purchase_order_lines(purchase_order_line_id),
    product_id       BIGINT NOT NULL REFERENCES products(product_id),
    lot_id           BIGINT REFERENCES inventory_lots(lot_id),
    destination_bin_id BIGINT NOT NULL REFERENCES bins(bin_id),
    accepted_qty     NUMERIC(20,6) NOT NULL DEFAULT 0 CHECK (accepted_qty >= 0),
    rejected_qty     NUMERIC(20,6) NOT NULL DEFAULT 0 CHECK (rejected_qty >= 0),
    unit_cost_minor  BIGINT NOT NULL CHECK (unit_cost_minor >= 0),
    CHECK (accepted_qty + rejected_qty > 0)
);

CREATE TABLE cycle_counts (
    count_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    warehouse_id     BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    count_number     VARCHAR(50) NOT NULL UNIQUE,
    state            count_state NOT NULL DEFAULT 'PLANNED',
    planned_at       TIMESTAMPTZ NOT NULL,
    started_at       TIMESTAMPTZ,
    posted_at        TIMESTAMPTZ,
    assigned_to      BIGINT,
    policy_version   VARCHAR(40) NOT NULL
);

CREATE TABLE cycle_count_lines (
    count_line_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    count_id         BIGINT NOT NULL REFERENCES cycle_counts(count_id) ON DELETE CASCADE,
    product_id       BIGINT NOT NULL REFERENCES products(product_id),
    bin_id           BIGINT NOT NULL REFERENCES bins(bin_id),
    lot_id           BIGINT REFERENCES inventory_lots(lot_id),
    system_qty_snapshot NUMERIC(20,6) NOT NULL,
    counted_qty      NUMERIC(20,6),
    variance_qty     NUMERIC(20,6) GENERATED ALWAYS AS
        (counted_qty - system_qty_snapshot) STORED,
    counted_at       TIMESTAMPTZ,
    counted_by       BIGINT,
    UNIQUE (count_id, product_id, bin_id, lot_id)
);

CREATE TABLE reorder_policies (
    warehouse_id     BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    product_id       BIGINT NOT NULL REFERENCES products(product_id),
    reorder_point_qty NUMERIC(20,6) NOT NULL CHECK (reorder_point_qty >= 0),
    target_stock_qty NUMERIC(20,6) NOT NULL CHECK (target_stock_qty >= reorder_point_qty),
    safety_stock_qty NUMERIC(20,6) NOT NULL DEFAULT 0 CHECK (safety_stock_qty >= 0),
    lead_time_days   INTEGER NOT NULL CHECK (lead_time_days >= 0),
    review_period_days INTEGER NOT NULL DEFAULT 1 CHECK (review_period_days > 0),
    policy_version   VARCHAR(40) NOT NULL,
    active           BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (warehouse_id, product_id)
);

CREATE TABLE demand_forecasts (
    warehouse_id     BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
    product_id       BIGINT NOT NULL REFERENCES products(product_id),
    forecast_date    DATE NOT NULL,
    forecast_qty     NUMERIC(20,6) NOT NULL CHECK (forecast_qty >= 0),
    model_version    VARCHAR(80) NOT NULL,
    generated_at     TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (warehouse_id, product_id, forecast_date, model_version)
);

CREATE TABLE command_requests (
    command_id       UUID PRIMARY KEY,
    command_type     VARCHAR(50) NOT NULL,
    idempotency_key  VARCHAR(160) NOT NULL,
    request_hash     CHAR(64) NOT NULL,
    status           VARCHAR(16) NOT NULL DEFAULT 'STARTED'
                     CHECK (status IN ('STARTED','SUCCEEDED','FAILED')),
    result_type      VARCHAR(40),
    result_id        BIGINT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at     TIMESTAMPTZ,
    UNIQUE (command_type, idempotency_key)
);

CREATE TABLE outbox_events (
    event_id         UUID PRIMARY KEY,
    aggregate_type   VARCHAR(40) NOT NULL,
    aggregate_id     BIGINT NOT NULL,
    event_type       VARCHAR(80) NOT NULL,
    payload_json     JSONB NOT NULL,
    occurred_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    published_at     TIMESTAMPTZ,
    attempt_count    INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    next_attempt_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_events (
    audit_id         BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor_id         BIGINT,
    action_code      VARCHAR(80) NOT NULL,
    object_type      VARCHAR(40) NOT NULL,
    object_id        BIGINT,
    request_id       UUID,
    occurred_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    details_json     JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX ix_stock_movements_product_time
    ON stock_movements (product_id, occurred_at DESC, movement_id DESC);
CREATE INDEX ix_stock_movements_reference
    ON stock_movements (reference_type, reference_id, movement_id);
CREATE INDEX ix_stock_balance_pick
    ON stock_balances (product_id, bin_id, lot_id)
    WHERE on_hand_qty > reserved_qty;
CREATE INDEX ix_lots_fefo
    ON inventory_lots (product_id, expires_on, lot_id)
    WHERE quality_state = 'RELEASED';
CREATE INDEX ix_reservations_expiry
    ON reservation_headers (expires_at, reservation_id)
    WHERE state IN ('ACTIVE','PARTIALLY_FULFILLED');
CREATE INDEX ix_po_open_lines
    ON purchase_order_lines (product_id, purchase_order_id)
    WHERE received_qty + cancelled_qty < ordered_qty;
CREATE INDEX ix_outbox_pending
    ON outbox_events (next_attempt_at, occurred_at, event_id)
    WHERE published_at IS NULL;

COMMIT;
