DO $$ BEGIN
  CREATE ROLE analytics_ingest NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE ROLE analytics_transform NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE ROLE analytics_dashboard NOLOGIN;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

REVOKE ALL ON SCHEMA landing,stage,dw,semantic,dashboard FROM PUBLIC;
GRANT USAGE ON SCHEMA landing,control TO analytics_ingest;
GRANT INSERT,SELECT ON landing.order_line_event TO analytics_ingest;
GRANT SELECT,UPDATE,INSERT ON control.etl_batch TO analytics_ingest;

GRANT USAGE ON SCHEMA landing,stage,dw,control TO analytics_transform;
GRANT SELECT ON ALL TABLES IN SCHEMA landing TO analytics_transform;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA stage,dw,control TO analytics_transform;

GRANT USAGE ON SCHEMA dashboard TO analytics_dashboard;
GRANT SELECT ON ALL TABLES IN SCHEMA dashboard TO analytics_dashboard;
-- Do not grant direct access to landing payloads or sensitive dimensions.
