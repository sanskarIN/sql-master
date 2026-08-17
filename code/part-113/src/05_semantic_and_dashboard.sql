CREATE OR REPLACE VIEW semantic.fact_order_line_certified AS
SELECT f.*
FROM dw.fact_order_line f
JOIN control.certified_snapshot c ON c.dataset_name='commerce_executive' AND c.metric_version='v1'
WHERE f.load_batch_id <= c.batch_id;

CREATE OR REPLACE VIEW semantic.daily_revenue_v1 AS
SELECT f.entity_key,f.order_date_key,
       SUM(f.net_paise) AS net_revenue_paise,
       SUM(f.net_paise-f.tax_paise-f.cost_paise) AS gross_margin_paise,
       SUM(f.quantity) AS units,
       COUNT(DISTINCT f.customer_key) AS purchasing_customers
FROM semantic.fact_order_line_certified f
GROUP BY f.entity_key,f.order_date_key;

CREATE OR REPLACE VIEW dashboard.executive_daily AS
SELECT d.calendar_date,e.entity_code,e.entity_name,e.reporting_currency,
       r.net_revenue_paise/100.0 AS net_revenue_rupees,
       r.gross_margin_paise/100.0 AS gross_margin_rupees,
       CASE WHEN r.net_revenue_paise=0 THEN NULL
            ELSE r.gross_margin_paise::numeric/r.net_revenue_paise END AS gross_margin_rate,
       r.units,r.purchasing_customers,
       c.certified_through,c.certified_at,c.quality_state,c.metric_version
FROM semantic.daily_revenue_v1 r
JOIN dw.dim_date d USING(order_date_key)
JOIN dw.dim_entity e USING(entity_key)
CROSS JOIN control.certified_snapshot c
WHERE c.dataset_name='commerce_executive' AND c.metric_version='v1';

-- Example dashboard query
SELECT * FROM dashboard.executive_daily
WHERE calendar_date >= DATE '2026-08-01' AND calendar_date < DATE '2026-09-01'
ORDER BY calendar_date,entity_code;
