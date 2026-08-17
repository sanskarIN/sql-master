BEGIN;
DROP TABLE IF EXISTS stage.order_line_ready;
CREATE TABLE stage.order_line_ready AS
SELECT e.source_event_id,
       (e.payload->>'source_order_line_id')::bigint AS source_order_line_id,
       (e.payload->>'source_updated_at')::timestamptz AS source_updated_at,
       e.occurred_at,
       e.payload->>'order_number' AS order_number,
       e.payload->>'customer_bk' AS customer_bk,
       e.payload->>'customer_name' AS customer_name,
       e.payload->>'segment_code' AS segment_code,
       e.payload->>'country_code' AS country_code,
       e.payload->>'product_bk' AS product_bk,
       e.payload->>'product_name' AS product_name,
       e.payload->>'category_name' AS category_name,
       (e.payload->>'standard_cost_paise')::bigint AS standard_cost_paise,
       e.payload->>'channel_code' AS channel_code,
       e.payload->>'entity_code' AS entity_code,
       (e.payload->>'quantity')::int AS quantity,
       (e.payload->>'gross_paise')::bigint AS gross_paise,
       (e.payload->>'discount_paise')::bigint AS discount_paise,
       (e.payload->>'tax_paise')::bigint AS tax_paise,
       (e.payload->>'net_paise')::bigint AS net_paise,
       e.payload->>'currency_code' AS currency_code,
       e.ingest_batch_id AS batch_id
FROM landing.order_line_event e;

-- SCD2 customer changes at source event time.
WITH changed AS (
  SELECT DISTINCT ON (customer_bk) s.*
  FROM stage.order_line_ready s
  LEFT JOIN dw.dim_customer c ON c.customer_bk=s.customer_bk AND c.is_current
  WHERE c.customer_key IS NULL OR c.source_hash <> md5(s.customer_name||'|'||s.segment_code||'|'||s.country_code)
  ORDER BY customer_bk, source_updated_at
), closed AS (
  UPDATE dw.dim_customer c
  SET valid_to=ch.source_updated_at, is_current=false
  FROM changed ch
  WHERE c.customer_bk=ch.customer_bk AND c.is_current
  RETURNING c.customer_bk
)
INSERT INTO dw.dim_customer(customer_bk,customer_name,segment_code,country_code,valid_from,valid_to,is_current,source_hash,load_batch_id)
SELECT customer_bk,customer_name,segment_code,country_code,source_updated_at,'9999-12-31 00:00+00',true,
       md5(customer_name||'|'||segment_code||'|'||country_code),batch_id
FROM changed
ON CONFLICT DO NOTHING;

WITH changed AS (
  SELECT DISTINCT ON (product_bk) s.*
  FROM stage.order_line_ready s
  LEFT JOIN dw.dim_product p ON p.product_bk=s.product_bk AND p.is_current
  WHERE p.product_key IS NULL OR p.source_hash <> md5(s.product_name||'|'||s.category_name||'|'||s.standard_cost_paise)
  ORDER BY product_bk, source_updated_at
), closed AS (
  UPDATE dw.dim_product p
  SET valid_to=ch.source_updated_at, is_current=false
  FROM changed ch
  WHERE p.product_bk=ch.product_bk AND p.is_current
  RETURNING p.product_bk
)
INSERT INTO dw.dim_product(product_bk,product_name,category_name,standard_cost_paise,valid_from,valid_to,is_current,source_hash,load_batch_id)
SELECT product_bk,product_name,category_name,standard_cost_paise,source_updated_at,'9999-12-31 00:00+00',true,
       md5(product_name||'|'||category_name||'|'||standard_cost_paise),batch_id
FROM changed
ON CONFLICT DO NOTHING;

INSERT INTO dw.fact_order_line(source_order_line_id,source_updated_at,order_date_key,customer_key,product_key,channel_key,entity_key,order_number,quantity,gross_paise,discount_paise,tax_paise,net_paise,cost_paise,currency_code,load_batch_id)
SELECT s.source_order_line_id,s.source_updated_at,to_char(s.occurred_at::date,'YYYYMMDD')::int,
       c.customer_key,p.product_key,ch.channel_key,en.entity_key,s.order_number,s.quantity,
       s.gross_paise,s.discount_paise,s.tax_paise,s.net_paise,p.standard_cost_paise*s.quantity,
       s.currency_code,s.batch_id
FROM stage.order_line_ready s
JOIN dw.dim_customer c ON c.customer_bk=s.customer_bk AND s.occurred_at>=c.valid_from AND s.occurred_at<c.valid_to
JOIN dw.dim_product p ON p.product_bk=s.product_bk AND s.occurred_at>=p.valid_from AND s.occurred_at<p.valid_to
JOIN dw.dim_channel ch ON ch.channel_code=s.channel_code
JOIN dw.dim_entity en ON en.entity_code=s.entity_code
ON CONFLICT(source_order_line_id,source_updated_at) DO NOTHING;

UPDATE control.etl_batch b
SET state='TRANSFORMED', published_rows=(SELECT count(*) FROM dw.fact_order_line f WHERE f.load_batch_id=b.batch_id)
WHERE b.batch_id=(SELECT max(batch_id) FROM control.etl_batch);
COMMIT;
