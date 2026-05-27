CREATE EXTENSION IF NOT EXISTS postgres_fdw;


CREATE SERVER evnEDS_db_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host '10.75.151.3', dbname 'ent_data_store', port '5432');


ALTER SERVER evneds_db_server
    OPTIONS (SET host '10.75.154.10', dbname 'ent_data_store', port '5432');

CREATE USER MAPPING FOR "OneC_5013"
  SERVER evnEDS_db_server
  OPTIONS (user 'OneC_5013', password 'Evnonec#2025');

CREATE USER MAPPING FOR postgres
  SERVER evnEDS_db_server
  OPTIONS (user 'OneC_5013', password 'Evnonec#2025');

  CREATE USER MAPPING FOR "evn-5013-np-sa@cb0104074a-citnonprod-gc.iam"
  SERVER evnEDS_db_server
  OPTIONS (user 'OneC_5013', password 'Evnonec#2025');
  

  ALTER USER MAPPING FOR "evn-5013-np-sa@cb0104074a-citnonprod-gc.iam"
  SERVER evnEDS_db_server
  OPTIONS (user 'OneC_5013', password 'Evnonec#2025');


IMPORT FOREIGN SCHEMA public
  FROM SERVER atsedsuat_db_server
  INTO ent_data_store_fdw;  --local_schema


-- 4. Local schema to hold foreign tables
CREATE SCHEMA IF NOT EXISTS ent_data_store_fdw;
--5
CREATE TABLE "DBAdmin".fdw_edsview_registry_tbl (
  view_name       TEXT PRIMARY KEY,
  source_schema   TEXT NOT NULL DEFAULT 'public',
  local_schema    TEXT NOT NULL DEFAULT 'ent_data_store_fdw',
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'inactive')),
  granted_by      TEXT,
  granted_at      TIMESTAMPTZ DEFAULT now(),
  last_synced_at  TIMESTAMPTZ
);



CREATE OR REPLACE FUNCTION "DBAdmin".refresh_fdw_edsviews_func()
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_schema      TEXT;
  active_views  TEXT[];
  views_csv     TEXT;
  vname         TEXT;
BEGIN
  FOR v_schema IN
    SELECT DISTINCT source_schema FROM "DBAdmin".fdw_edsview_registry_tbl WHERE status = 'active'
  LOOP
    SELECT array_agg(view_name) INTO active_views
    FROM "DBAdmin".fdw_edsview_registry_tbl
    WHERE status = 'active' AND source_schema = v_schema;

    IF active_views IS NULL THEN CONTINUE; END IF;

    -- Drop and re-import to pick up source schema changes
    FOREACH vname IN ARRAY active_views LOOP
      EXECUTE format('DROP FOREIGN TABLE IF EXISTS ent_data_store_fdw.%I', vname);
    END LOOP;

    SELECT string_agg(quote_ident(v), ', ')
    INTO views_csv
    FROM unnest(active_views) AS v;

    EXECUTE format(
      'IMPORT FOREIGN SCHEMA %I LIMIT TO (%s) FROM SERVER evnEDS_db_server INTO ent_data_store_fdw',
      v_schema, views_csv
    );
  END LOOP;

  UPDATE "DBAdmin".fdw_edsview_registry_tbl SET last_synced_at = now() WHERE status = 'active';
  RAISE NOTICE 'FDW refresh complete at %', now();
END;
$$;

-- 7. Grant/revoke functions
CREATE OR REPLACE FUNCTION "DBAdmin".grant_edsview_access_func(
  p_view_name  TEXT,
  p_granted_by TEXT,
  p_schema     TEXT DEFAULT 'public'
)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM "DBAdmin".fdw_edsview_registry_tbl
    WHERE view_name = p_view_name AND status = 'active'
  ) THEN
    RAISE NOTICE 'View % already active, nothing to do', p_view_name;
    RETURN;
  END IF;

  -- Add to registry
  INSERT INTO "DBAdmin".fdw_edsview_registry_tbl (view_name, source_schema, granted_by)
  VALUES (p_view_name, p_schema, p_granted_by)
  ON CONFLICT (view_name) DO UPDATE
    SET status     = 'active',
        granted_by = p_granted_by,
        granted_at = now();

  -- Import immediately, don't wait for cron
  EXECUTE format(
    'IMPORT FOREIGN SCHEMA %I LIMIT TO (%I) FROM SERVER evnEDS_db_server INTO ent_data_store_fdw',
    p_schema, p_view_name
  );

  RAISE NOTICE 'Granted and imported: %', p_view_name;
END;
$$;


CREATE OR REPLACE FUNCTION "DBAdmin".revoke_edsview_access_func(
  p_view_name  TEXT,
  p_revoked_by TEXT
)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE fdw_edsview_registry_tbl
  SET status     = 'inactive',
      granted_by = p_revoked_by,
      granted_at = now()
  WHERE view_name = p_view_name AND status = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'View % is not currently active', p_view_name;
  END IF;

  EXECUTE format('DROP FOREIGN TABLE IF EXISTS ent_data_store_fdw.%I', p_view_name);
  RAISE NOTICE 'Revoked and dropped: %', p_view_name;
END;
$$;


-- Connect to POSTGRES database (where pg_cron is enabled)
-- Schedule the refresh job to run IN app1_db
SELECT cron.schedule_in_database(
  'refresh_fdw_views_app1',   -- unique job name
  '*/10 * * * *',             -- every 10 minutes
  'SELECT refresh_fdw_views()',-- function that exists in app1_db
  'app1_db'                   -- target database
);

-- Same for app2_db
SELECT cron.schedule_in_database(
  'refresh_fdw_views_app2',
  '*/10 * * * *',
  'SELECT refresh_fdw_views()',
  'app2_db'
);

-- Same for app3_db
SELECT cron.schedule_in_database(
  'refresh_fdw_views_app3',
  '*/10 * * * *',
  'SELECT refresh_fdw_views()',
  'app3_db'
);


---tuning FDW Schema----
create extension if not exists pg_trgm;

-- These go on ALTER SERVER — affect all queries through this server
ALTER SERVER evnEDS_db_server OPTIONS (
  ADD fetch_size         '2000',    -- fetch 2000 rows per network round trip
  ADD connect_timeout    '10',      -- give up connecting after 10 seconds
   --ADD extensions         'pg_trgm', pushdown trigram operators to source
  ADD fdw_startup_cost   '150',     -- slightly higher than default for Cloud SQL network
  ADD fdw_tuple_cost     '0.05',    -- source is fast, rows are cheap to fetch
  ADD use_remote_estimate 'true'    -- ask source for real row counts before planning
);

-- Apply statement and lock timeouts via options string
ALTER SERVER evnEDS_db_server OPTIONS (
  ADD options '-c statement_timeout=15000 -c lock_timeout=5000'
);

UPDATE cron.job
	SET active=false
	WHERE jobid=8;
	
select * from cron.job

SELECT cron.schedule_in_database(
  'refresh_fdw_EDS_views_OneC_5013_PT',
  '*/10 * * * *',
  'select "DBAdmin".refresh_fdw_edsviews_func()',
  'OneC_5013'
);


---
SELECT "DBAdmin".grant_edsview_access_func('viewname', '1CDBA_empid');
SELECT "DBAdmin".grant_edsview_access_func('public.viewname', '1CDBA_empid');
----
SELECT grant_edsview_access_func('myskills_ms_employee_master_view', '1CDBA_2275509');

SELECT "DBAdmin".grant_edsview_access_func('vw_centralrepository_designation', '1CDBA_2275509');

-- STEP 1: Run on ENT_DATA_STORE (source)
GRANT SELECT ON public.myskills_ms_employee_master_view TO "OneC_4681";

-- STEP 2: Run on the APP DB (e.g. app1_db)
SELECT grant_edsview_access_func('myskills_ms_employee_master_view', 'dba@company.com');

select * from ent_data_store_fdw.vw_centralrepository_associate_details limit 10