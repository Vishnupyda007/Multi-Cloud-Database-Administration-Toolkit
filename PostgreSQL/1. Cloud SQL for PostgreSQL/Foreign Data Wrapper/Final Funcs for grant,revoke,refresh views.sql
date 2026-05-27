CREATE EXTENSION IF NOT EXISTS postgres_fdw;


create SERVER evnEDS_db_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host '10.75.156.3', dbname 'ent_data_store', port '5432');


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
  
-- 4. Local schema to hold foreign tables
CREATE SCHEMA IF NOT EXISTS ent_data_store_fdw;
--5
CREATE TABLE if not exists "DBAdmin".fdw_edsview_registry_tbl (
  view_name       TEXT PRIMARY KEY,
  source_schema   TEXT NOT NULL DEFAULT 'public',
  local_schema    TEXT NOT NULL DEFAULT 'ent_data_store_fdw',
  status          TEXT NOT NULL DEFAULT 'active'
                  CHECK (status IN ('active', 'inactive')),
  granted_by      TEXT,
  granted_at      TIMESTAMPTZ DEFAULT now(),
  last_synced_at  TIMESTAMPTZ
);


--select "DBAdmin".refresh_fdw_edsviews_func()
CREATE OR REPLACE  FUNCTION  "DBAdmin".refresh_fdw_edsviews_func()
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

--DROP FUNCTION "DBAdmin".grant_edsview_access_func(text,text,text)
CREATE OR REPLACE FUNCTION "DBAdmin".grant_edsview_access_func(
  p_view_name   TEXT,
  p_granted_by  TEXT,
  p_local_schema TEXT DEFAULT 'ent_data_store_fdw'  -- where foreign table lives locally
)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_source_schema  TEXT;   -- schema on ent_data_store (source)
  v_view_name      TEXT;   -- just the view name, no schema prefix
  v_parts          TEXT[];
BEGIN
  -- ------------------------------------------------
  -- Parse input into source schema + view name
  -- 'public.vw_foo'  → source_schema=public,  view=vw_foo
  -- 'vw_foo'         → source_schema=public,  view=vw_foo (default)
  -- ------------------------------------------------
  v_parts := string_to_array(trim(p_view_name), '.');

  IF array_length(v_parts, 1) = 2 THEN
    v_source_schema := trim(v_parts[1]);
    v_view_name     := trim(v_parts[2]);
  ELSIF array_length(v_parts, 1) = 1 THEN
    v_source_schema := 'public';           -- default source schema
    v_view_name     := trim(v_parts[1]);
  ELSE
    RAISE EXCEPTION 'Invalid format: %. Use viewname or sourceschema.viewname', p_view_name;
  END IF;

  RAISE NOTICE 'source_schema=%, view_name=%, local_schema=%',
    v_source_schema, v_view_name, p_local_schema;

  -- ------------------------------------------------
  -- Already active in registry?
  -- ------------------------------------------------
  IF EXISTS (
    SELECT 1 FROM "DBAdmin".fdw_edsview_registry_tbl
    WHERE view_name   = v_view_name
      AND status      = 'active'
  ) THEN
    RAISE NOTICE 'View % is already active — nothing to do', v_view_name;
    RETURN;
  END IF;

  -- ------------------------------------------------
  -- Check foreign table does not already exist locally
  -- (can happen if registry is out of sync)
  -- ------------------------------------------------
  IF EXISTS (
    SELECT 1 FROM information_schema.foreign_tables
    WHERE foreign_table_schema = p_local_schema
      AND foreign_table_name   = v_view_name
  ) THEN
    RAISE NOTICE 'Foreign table %.% already exists locally, dropping before reimport',
      p_local_schema, v_view_name;
    EXECUTE format('DROP FOREIGN TABLE IF EXISTS %I.%I', p_local_schema, v_view_name);
  END IF;

  -- ------------------------------------------------
  -- Upsert into registry
  -- ------------------------------------------------
  INSERT INTO "DBAdmin".fdw_edsview_registry_tbl
    (view_name, source_schema, local_schema, granted_by, status, granted_at)
  VALUES
    (v_view_name, v_source_schema, p_local_schema, p_granted_by, 'active', now())
  ON CONFLICT (view_name) DO UPDATE
    SET status        = 'active',
        source_schema = EXCLUDED.source_schema,
        local_schema  = EXCLUDED.local_schema,
        granted_by    = EXCLUDED.granted_by,
        granted_at    = now();

  -- ------------------------------------------------
  -- Import foreign table from source into local schema
  -- source schema (public on ent_data_store) → local schema (ent_data_store_fdw)
  -- ------------------------------------------------
  EXECUTE format(
    'IMPORT FOREIGN SCHEMA %I LIMIT TO (%I) FROM SERVER evnEDS_db_server INTO %I',
    v_source_schema,   -- 'public'               — schema on ent_data_store
    v_view_name,       -- 'vw_centralrepository_designation'
    p_local_schema     -- 'ent_data_store_fdw'   — local schema on this DB
  );

  RAISE NOTICE 'SUCCESS — imported %.% into local schema %',
    v_source_schema, v_view_name, p_local_schema;

EXCEPTION WHEN OTHERS THEN
  -- Rollback registry entry if import failed
  UPDATE "DBAdmin".fdw_edsview_registry_tbl
  SET status = 'inactive'
  WHERE view_name = v_view_name;

  RAISE EXCEPTION 'Grant failed for % — rolled back registry. Error: %',
    v_view_name, SQLERRM;
END;
$$;


----------------------------

CREATE OR REPLACE FUNCTION "DBAdmin".revoke_edsview_access_func(
  p_view_name  TEXT,
  p_revoked_by TEXT
)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_view_name     TEXT;
  v_local_schema  TEXT;
  v_parts         TEXT[];
  v_reg           RECORD;
BEGIN
  -- ------------------------------------------------
  -- Parse input — strip source schema prefix if given
  -- We only need the view name to look up registry
  -- local schema comes FROM the registry, not from input
  -- ------------------------------------------------
  v_parts := string_to_array(trim(p_view_name), '.');

  IF array_length(v_parts, 1) = 2 THEN
    v_view_name := trim(v_parts[2]);   -- discard schema prefix from input
  ELSE
    v_view_name := trim(v_parts[1]);
  END IF;

  -- ------------------------------------------------
  -- Fetch registry entry — get local_schema from here
  -- NOT from input — this is the fix for wrong schema drop
  -- ------------------------------------------------
  SELECT * INTO v_reg
  FROM "DBAdmin".fdw_edsview_registry_tbl
  WHERE view_name = v_view_name
    AND status    = 'active';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'View % is not currently active in registry', v_view_name;
  END IF;

  -- Use local_schema from registry (e.g. 'ent_data_store_fdw')
  -- Never use the schema from input for DROP — that is the source schema
  v_local_schema := COALESCE(v_reg.local_schema, 'ent_data_store_fdw');

  RAISE NOTICE 'Revoking: view=%, local_schema=%', v_view_name, v_local_schema;

  -- ------------------------------------------------
  -- Update registry first
  -- ------------------------------------------------
  UPDATE "DBAdmin".fdw_edsview_registry_tbl
  SET status     = 'inactive',
      granted_by = p_revoked_by,
      granted_at = now()
  WHERE view_name = v_view_name
    AND status    = 'active';

  -- ------------------------------------------------
  -- Drop foreign table using LOCAL schema from registry
  -- NOT the source schema from input
  -- ------------------------------------------------
  EXECUTE format(
    'DROP FOREIGN TABLE IF EXISTS %I.%I',
    v_local_schema,   -- 'ent_data_store_fdw'  ← from registry
    v_view_name       -- 'vw_centralrepository_designation'
  );

  -- Verify it is actually gone
  IF EXISTS (
    SELECT 1 FROM information_schema.foreign_tables
    WHERE foreign_table_schema = v_local_schema
      AND foreign_table_name   = v_view_name
  ) THEN
    RAISE WARNING 'Foreign table %.% still exists after drop — manual check needed',
      v_local_schema, v_view_name;
  ELSE
    RAISE NOTICE 'SUCCESS — revoked and dropped %.%', v_local_schema, v_view_name;
  END IF;

EXCEPTION WHEN OTHERS THEN
  -- Re-activate registry if drop failed
  UPDATE "DBAdmin".fdw_edsview_registry_tbl
  SET status = 'active'
  WHERE view_name = v_view_name;

  RAISE EXCEPTION 'Revoke failed for % — registry restored to active. Error: %',
    v_view_name, SQLERRM;
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

SELECT "DBAdmin".grant_edsview_access_func('public.vw_centralrepository_associate_details', '1CDBA_2275509');

-- STEP 1: Run on ENT_DATA_STORE (source)
GRANT SELECT ON public.myskills_ms_employee_master_view TO "OneC_4681";

-- STEP 2: Run on the APP DB (e.g. app1_db)
SELECT "DBAdmin".grant_edsview_access_func('vw_centralrepository_designation', '1CDBA_2275509');

select "DBAdmin".revoke_edsview_access_func('public.vw_centralrepository_designation', 'dba@company.com');


select * from "DBAdmin".fdw_edsview_registry_tbl

select * from ent_data_store_fdw.vw_centralrepository_associate_details limit 10