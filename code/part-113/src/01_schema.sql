BEGIN;
CREATE SCHEMA IF NOT EXISTS control;
CREATE SCHEMA IF NOT EXISTS landing;
CREATE SCHEMA IF NOT EXISTS stage;
CREATE SCHEMA IF NOT EXISTS dw;
CREATE SCHEMA IF NOT EXISTS semantic;
CREATE SCHEMA IF NOT EXISTS dashboard;

CREATE TABLE control.etl_batch (
  batch_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pipeline_name TEXT NOT NULL,
  from_watermark TIMESTAMPTZ,
  to_watermark TIMESTAMPTZ NOT NULL,
  code_revision TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('STARTED','EXTRACTED','TRANSFORMED','VALIDATED','PUBLISHED','FAILED','SUPERSEDED')),
  source_rows BIGINT NOT NULL DEFAULT 0,
  published_rows BIGINT NOT NULL DEFAULT 0,
  rejected_rows BIGINT NOT NULL DEFAULT 0,
  started_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  completed_at TIMESTAMPTZ,
  error_class TEXT,
  superseded_by BIGINT REFERENCES control.etl_batch(batch_id)
);

CREATE TABLE control.data_quality_result (
  quality_result_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  batch_id BIGINT NOT NULL REFERENCES control.etl_batch(batch_id),
  check_name TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('PASS','WARN','FAIL')),
  observed_value NUMERIC,
  threshold_text TEXT,
  evidence JSONB NOT NULL DEFAULT '{}'::jsonb,
  checked_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  UNIQUE(batch_id, check_name)
);

CREATE TABLE landing.order_line_event (
  source_event_id TEXT PRIMARY KEY,
  source_position TEXT NOT NULL,
  source_schema_version INTEGER NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL,
  received_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  payload JSONB NOT NULL,
  payload_sha256 TEXT NOT NULL,
  ingest_batch_id BIGINT NOT NULL REFERENCES control.etl_batch(batch_id)
);

CREATE TABLE dw.dim_date (
  date_key INTEGER PRIMARY KEY,
  calendar_date DATE NOT NULL UNIQUE,
  calendar_year INTEGER NOT NULL,
  calendar_month INTEGER NOT NULL,
  month_name TEXT NOT NULL,
  fiscal_year INTEGER NOT NULL,
  fiscal_quarter INTEGER NOT NULL,
  is_weekend BOOLEAN NOT NULL
);

CREATE TABLE dw.dim_channel (
  channel_key SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  channel_code TEXT NOT NULL UNIQUE,
  channel_name TEXT NOT NULL
);

CREATE TABLE dw.dim_entity (
  entity_key SMALLINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  entity_code TEXT NOT NULL UNIQUE,
  entity_name TEXT NOT NULL,
  reporting_currency CHAR(3) NOT NULL
);

CREATE TABLE dw.dim_customer (
  customer_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_bk TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  segment_code TEXT NOT NULL,
  country_code CHAR(2) NOT NULL,
  valid_from TIMESTAMPTZ NOT NULL,
  valid_to TIMESTAMPTZ NOT NULL,
  is_current BOOLEAN NOT NULL,
  source_hash TEXT NOT NULL,
  load_batch_id BIGINT NOT NULL REFERENCES control.etl_batch(batch_id),
  CHECK (valid_from < valid_to)
);
CREATE UNIQUE INDEX ux_dim_customer_current ON dw.dim_customer(customer_bk) WHERE is_current;
CREATE INDEX ix_dim_customer_asof ON dw.dim_customer(customer_bk, valid_from, valid_to);

CREATE TABLE dw.dim_product (
  product_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  product_bk TEXT NOT NULL,
  product_name TEXT NOT NULL,
  category_name TEXT NOT NULL,
  standard_cost_paise BIGINT NOT NULL CHECK (standard_cost_paise >= 0),
  valid_from TIMESTAMPTZ NOT NULL,
  valid_to TIMESTAMPTZ NOT NULL,
  is_current BOOLEAN NOT NULL,
  source_hash TEXT NOT NULL,
  load_batch_id BIGINT NOT NULL REFERENCES control.etl_batch(batch_id),
  CHECK (valid_from < valid_to)
);
CREATE UNIQUE INDEX ux_dim_product_current ON dw.dim_product(product_bk) WHERE is_current;
CREATE INDEX ix_dim_product_asof ON dw.dim_product(product_bk, valid_from, valid_to);

CREATE TABLE dw.fact_order_line (
  order_line_fact_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  source_order_line_id BIGINT NOT NULL,
  source_updated_at TIMESTAMPTZ NOT NULL,
  order_date_key INTEGER NOT NULL REFERENCES dw.dim_date(date_key),
  customer_key BIGINT NOT NULL REFERENCES dw.dim_customer(customer_key),
  product_key BIGINT NOT NULL REFERENCES dw.dim_product(product_key),
  channel_key SMALLINT NOT NULL REFERENCES dw.dim_channel(channel_key),
  entity_key SMALLINT NOT NULL REFERENCES dw.dim_entity(entity_key),
  order_number TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  gross_paise BIGINT NOT NULL CHECK (gross_paise >= 0),
  discount_paise BIGINT NOT NULL CHECK (discount_paise >= 0),
  tax_paise BIGINT NOT NULL CHECK (tax_paise >= 0),
  net_paise BIGINT NOT NULL CHECK (net_paise >= 0),
  cost_paise BIGINT NOT NULL CHECK (cost_paise >= 0),
  currency_code CHAR(3) NOT NULL,
  load_batch_id BIGINT NOT NULL REFERENCES control.etl_batch(batch_id),
  UNIQUE(source_order_line_id, source_updated_at),
  CHECK (net_paise = gross_paise - discount_paise + tax_paise)
);
CREATE INDEX ix_fact_order_line_date_entity ON dw.fact_order_line(order_date_key, entity_key);
CREATE INDEX ix_fact_order_line_customer_date ON dw.fact_order_line(customer_key, order_date_key);

CREATE TABLE control.certified_snapshot (
  dataset_name TEXT NOT NULL,
  metric_version TEXT NOT NULL,
  batch_id BIGINT NOT NULL REFERENCES control.etl_batch(batch_id),
  certified_through TIMESTAMPTZ NOT NULL,
  quality_state TEXT NOT NULL CHECK (quality_state = 'PASS'),
  certified_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
  certified_by TEXT NOT NULL,
  PRIMARY KEY(dataset_name, metric_version)
);
COMMIT;
