-- Inventory availability, planning, and reporting queries
SET search_path = inventory, public;

-- Available-to-promise by product and warehouse.
SELECT b.warehouse_id,sb.product_id,
       SUM(sb.on_hand_qty) AS on_hand_qty,
       SUM(sb.reserved_qty) AS reserved_qty,
       SUM(sb.on_hand_qty-sb.reserved_qty) AS available_qty
FROM stock_balances sb JOIN bins b ON b.bin_id=sb.bin_id
WHERE b.active AND b.kind NOT IN ('QUARANTINE','ADJUSTMENT')
GROUP BY b.warehouse_id,sb.product_id;

-- Net inventory position and reorder suggestion.
WITH stock AS (
  SELECT b.warehouse_id,sb.product_id,
         SUM(sb.on_hand_qty-sb.reserved_qty) AS available_qty
  FROM stock_balances sb JOIN bins b ON b.bin_id=sb.bin_id
  WHERE b.active AND b.kind<>'QUARANTINE'
  GROUP BY b.warehouse_id,sb.product_id
), incoming AS (
  SELECT po.warehouse_id,pol.product_id,
         SUM(pol.ordered_qty-pol.received_qty-pol.cancelled_qty) AS open_po_qty
  FROM purchase_orders po JOIN purchase_order_lines pol USING(purchase_order_id)
  WHERE po.state IN ('APPROVED','SENT','PARTIALLY_RECEIVED')
  GROUP BY po.warehouse_id,pol.product_id
), demand AS (
  SELECT warehouse_id,product_id,SUM(forecast_qty) AS lead_time_demand
  FROM demand_forecasts f JOIN reorder_policies rp USING(warehouse_id,product_id)
  WHERE f.forecast_date>CURRENT_DATE
    AND f.forecast_date<=CURRENT_DATE+rp.lead_time_days
  GROUP BY warehouse_id,product_id
)
SELECT rp.warehouse_id,rp.product_id,
       COALESCE(s.available_qty,0) AS available_qty,
       COALESCE(i.open_po_qty,0) AS open_po_qty,
       COALESCE(d.lead_time_demand,0) AS lead_time_demand,
       GREATEST(0,rp.target_stock_qty-
         (COALESCE(s.available_qty,0)+COALESCE(i.open_po_qty,0)-COALESCE(d.lead_time_demand,0))) AS suggested_qty,
       rp.policy_version
FROM reorder_policies rp
LEFT JOIN stock s USING(warehouse_id,product_id)
LEFT JOIN incoming i USING(warehouse_id,product_id)
LEFT JOIN demand d USING(warehouse_id,product_id)
WHERE rp.active
  AND COALESCE(s.available_qty,0)+COALESCE(i.open_po_qty,0)-COALESCE(d.lead_time_demand,0)
      <=rp.reorder_point_qty
ORDER BY rp.warehouse_id,rp.product_id;

-- FEFO pick candidates. Do not use OFFSET for operational picking.
SELECT sb.product_id,sb.bin_id,sb.lot_id,l.expires_on,
       sb.on_hand_qty-sb.reserved_qty AS available_qty
FROM stock_balances sb JOIN bins b ON b.bin_id=sb.bin_id
LEFT JOIN inventory_lots l ON l.lot_id=sb.lot_id
WHERE sb.product_id=:product_id AND b.warehouse_id=:warehouse_id
  AND b.is_pickable AND sb.on_hand_qty>sb.reserved_qty
  AND (l.lot_id IS NULL OR (l.quality_state='RELEASED' AND l.expires_on>CURRENT_DATE))
  AND (COALESCE(l.expires_on,DATE '9999-12-31'),b.bin_code,COALESCE(sb.lot_id,0))
      > (:cursor_expiry,:cursor_bin,:cursor_lot)
ORDER BY l.expires_on NULLS LAST,b.bin_code,sb.lot_id NULLS FIRST
LIMIT :page_size;

-- Inventory aging and expiry risk.
SELECT p.sku,w.warehouse_code,l.supplier_lot_code,l.expires_on,
       SUM(sb.on_hand_qty) AS on_hand_qty,
       l.expires_on-CURRENT_DATE AS days_to_expiry
FROM stock_balances sb
JOIN products p USING(product_id)
JOIN bins b USING(bin_id)
JOIN warehouses w USING(warehouse_id)
JOIN inventory_lots l USING(lot_id)
WHERE sb.on_hand_qty>0
GROUP BY p.sku,w.warehouse_code,l.lot_id,l.supplier_lot_code,l.expires_on
ORDER BY l.expires_on,p.sku;

-- Supplier OTIF evidence.
SELECT s.supplier_code,
       COUNT(*) FILTER (WHERE r.received_at::date<=po.expected_on) AS on_time_receipts,
       COUNT(*) AS total_receipts,
       SUM(pol.received_qty) AS received_qty,
       SUM(pol.ordered_qty) AS ordered_qty
FROM suppliers s
JOIN purchase_orders po USING(supplier_id)
JOIN purchase_order_lines pol USING(purchase_order_id)
LEFT JOIN receipts r USING(purchase_order_id)
WHERE po.ordered_at>=:from_time AND po.ordered_at<:to_time
GROUP BY s.supplier_code ORDER BY s.supplier_code;
