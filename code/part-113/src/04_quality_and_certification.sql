BEGIN;
WITH b AS (SELECT max(batch_id) batch_id FROM control.etl_batch)
INSERT INTO control.data_quality_result(batch_id,check_name,status,observed_value,threshold_text,evidence)
SELECT b.batch_id,'source_to_fact_count',
       CASE WHEN (SELECT count(*) FROM landing.order_line_event WHERE ingest_batch_id=b.batch_id)
                   =(SELECT count(*) FROM dw.fact_order_line WHERE load_batch_id=b.batch_id)
            THEN 'PASS' ELSE 'FAIL' END,
       (SELECT count(*) FROM dw.fact_order_line WHERE load_batch_id=b.batch_id),
       'published rows must equal accepted landing rows',
       jsonb_build_object('landing_rows',(SELECT count(*) FROM landing.order_line_event WHERE ingest_batch_id=b.batch_id))
FROM b
ON CONFLICT(batch_id,check_name) DO UPDATE SET status=excluded.status, observed_value=excluded.observed_value, evidence=excluded.evidence;

WITH b AS (SELECT max(batch_id) batch_id FROM control.etl_batch)
INSERT INTO control.data_quality_result(batch_id,check_name,status,observed_value,threshold_text)
SELECT b.batch_id,'line_arithmetic',
       CASE WHEN COALESCE(SUM(gross_paise-discount_paise+tax_paise-net_paise),0)=0 THEN 'PASS' ELSE 'FAIL' END,
       COALESCE(SUM(gross_paise-discount_paise+tax_paise-net_paise),0), 'difference must be zero'
FROM b JOIN dw.fact_order_line f ON f.load_batch_id=b.batch_id
GROUP BY b.batch_id
ON CONFLICT(batch_id,check_name) DO UPDATE SET status=excluded.status, observed_value=excluded.observed_value;

WITH b AS (SELECT max(batch_id) batch_id FROM control.etl_batch),
checks AS (SELECT bool_and(status='PASS') ok FROM control.data_quality_result q JOIN b USING(batch_id))
UPDATE control.etl_batch SET state=CASE WHEN checks.ok THEN 'VALIDATED' ELSE 'FAILED' END,
 completed_at=clock_timestamp()
FROM checks WHERE batch_id=(SELECT batch_id FROM b);

INSERT INTO control.certified_snapshot(dataset_name,metric_version,batch_id,certified_through,quality_state,certified_by)
SELECT 'commerce_executive','v1',batch_id,to_watermark,'PASS',current_user
FROM control.etl_batch
WHERE batch_id=(SELECT max(batch_id) FROM control.etl_batch) AND state='VALIDATED'
ON CONFLICT(dataset_name,metric_version) DO UPDATE
SET batch_id=excluded.batch_id,certified_through=excluded.certified_through,quality_state=excluded.quality_state,certified_at=clock_timestamp(),certified_by=excluded.certified_by;

UPDATE control.etl_batch SET state='PUBLISHED'
WHERE batch_id=(SELECT batch_id FROM control.certified_snapshot WHERE dataset_name='commerce_executive' AND metric_version='v1');
COMMIT;
