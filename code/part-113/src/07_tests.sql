DO $$
DECLARE n bigint;
BEGIN
  SELECT count(*) INTO n FROM dw.fact_order_line;
  IF n <> 4 THEN RAISE EXCEPTION 'expected 4 facts, got %',n; END IF;
  IF EXISTS (SELECT 1 FROM dw.fact_order_line WHERE net_paise<>gross_paise-discount_paise+tax_paise) THEN
    RAISE EXCEPTION 'line arithmetic invariant failed';
  END IF;
  IF EXISTS (SELECT customer_bk FROM dw.dim_customer WHERE is_current GROUP BY customer_bk HAVING count(*)<>1) THEN
    RAISE EXCEPTION 'customer current-row invariant failed';
  END IF;
  IF EXISTS (SELECT product_bk FROM dw.dim_product WHERE is_current GROUP BY product_bk HAVING count(*)<>1) THEN
    RAISE EXCEPTION 'product current-row invariant failed';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM control.etl_batch WHERE state='PUBLISHED') THEN
    RAISE EXCEPTION 'no published batch';
  END IF;
  IF EXISTS (SELECT 1 FROM control.data_quality_result WHERE status<>'PASS') THEN
    RAISE EXCEPTION 'quality checks not all passing';
  END IF;
END $$;

-- Replay proof: running 03_incremental_load.sql again must not change fact count.
SELECT 'PASS' AS result, count(*) AS certified_daily_rows FROM dashboard.executive_daily;
