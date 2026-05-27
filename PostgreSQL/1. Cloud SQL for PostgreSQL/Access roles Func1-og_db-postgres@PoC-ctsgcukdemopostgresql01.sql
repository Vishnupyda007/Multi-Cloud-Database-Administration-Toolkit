
-- Helper: return TRUE if the schema should be ignored
CREATE OR REPLACE FUNCTION _is_excluded_schema(sname text)
RETURNS boolean
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
  -- If we cannot determine the schema, be conservative and skip
  IF sname IS NULL THEN
    RETURN true;
  END IF;

  -- Core system schemas
  IF sname = 'information_schema'
     OR sname = 'pg_catalog'
     OR sname = 'pg_toast'
     OR sname LIKE 'pg_temp_%'         -- session temp schemas
     OR sname LIKE 'pg_toast_temp_%'
  THEN
    RETURN true;
  END IF;

  -- Common extension/admin schemas to ignore (add/adjust as needed)
  IF sname = ANY (ARRAY[
      'anon',                   -- pganonymizer or similar
      'cron',                   -- pg_cron
      'google_vacuum_mgmt',     -- your vacuum mgmt schema
      'pgagent',                -- pgAgent jobs
      'timescaledb_internal',   -- TimescaleDB internals
      '_timescaledb_internal',  -- TimescaleDB internals in newer versions
      'topology',               -- PostGIS topology
      'tiger'                   -- PostGIS TIGER geocoder
    ]) THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;



CREATE OR REPLACE FUNCTION public._ddl_grants_dispatch()
RETURNS EVENT_TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog       -- safe path; we'll fully-qualify helper calls
AS $func$
DECLARE
  ev RECORD;
  sname         TEXT;
  owner_regrole TEXT;
BEGIN
  FOR ev IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP

    -- -------- CREATE SCHEMA ----------
    IF ev.command_tag = 'CREATE SCHEMA' AND ev.schema_name IS NOT NULL THEN
      sname := ev.schema_name;

      -- *** Qualify helper call ***
      IF public._is_excluded_schema(sname) THEN
        CONTINUE;
      END IF;

      -- Ownership, grants, defaults (your existing logic)
      EXECUTE format('GRANT USAGE ON SCHEMA %I TO db_datareader, db_datawriter;', sname);
      EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);
      EXECUTE format('GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO db_datawriter;', sname);

      FOR ev IN SELECT matviewname FROM pg_matviews WHERE schemaname = sname LOOP
        EXECUTE format('GRANT SELECT ON %I.%I TO db_datareader, db_datawriter;', sname, ev.matviewname);
      END LOOP;

      SELECT n.nspowner::regrole::text INTO owner_regrole
      FROM   pg_namespace n
      WHERE  n.nspname = sname;

      IF owner_regrole IS NOT NULL THEN
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO db_datareader, db_datawriter;',
          owner_regrole, sname);

        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT INSERT, UPDATE, DELETE ON TABLES TO db_datawriter;',
          owner_regrole, sname);
      END IF;

    -- -------- CREATE TABLE / CREATE VIEW ----------
    ELSIF ev.command_tag IN ('CREATE TABLE','CREATE VIEW')
          AND ev.object_identity IS NOT NULL THEN

      IF NOT public._is_excluded_schema(ev.schema_name) THEN
        EXECUTE format('GRANT SELECT ON %s TO db_datareader, db_datawriter;', ev.object_identity);
        IF ev.command_tag = 'CREATE TABLE' THEN
          EXECUTE format('GRANT INSERT, UPDATE, DELETE ON %s TO db_datawriter;', ev.object_identity);
        END IF;
      END IF;

    -- -------- CREATE MATERIALIZED VIEW ----------
    ELSIF ev.command_tag = 'CREATE MATERIALIZED VIEW'
          AND ev.object_identity IS NOT NULL THEN

      IF NOT public._is_excluded_schema(ev.schema_name) THEN
        EXECUTE format('GRANT SELECT ON %s TO db_datareader, db_datawriter;', ev.object_identity);
      END IF;

       END IF;

  END LOOP;
END;





-- Create/replace the event trigger AFTER the function exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_event_trigger WHERE evtname = 'et_on_all_create_alter') THEN
    CREATE EVENT TRIGGER et_on_all_create_alter
      ON ddl_command_end
      WHEN TAG IN ('CREATE SCHEMA','ALTER SCHEMA','CREATE TABLE','CREATE VIEW','CREATE MATERIALIZED VIEW')
      EXECUTE FUNCTION      EXECUTE FUNCTION _ddl_grants_dispatch();
  END IF;
END
$$





DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_event_trigger
    WHERE evtname = 'et_on_all_create_alter'
  ) THEN
    CREATE EVENT TRIGGER et_on_all_create_alter
      ON ddl_command_end
      WHEN TAG IN ('CREATE SCHEMA','ALTER SCHEMA','CREATE TABLE','CREATE VIEW','CREATE MATERIALIZED VIEW')
      EXECUTE FUNCTION _ddl_grants_dispatch();
  END IF;
END
$$;


create schema testApp



SELECT grantee, privilege_type, table_schema, table_name
FROM information_schema.role_table_grants
WHERE table_schema = 'testapp'
  AND grantee IN ('db_datareader','db_datawriter')
ORDER BY table_name, grantee;


SELECT n.nspname, pg_get_userbyid(n.nspowner) FROM pg_namespace n


  
WITH user_schemas AS (
  SELECT nspname
  FROM pg_namespace
  WHERE nspname !~ '^pg_' AND nspname <> 'information_schema'
)
SELECT
  s.nspname AS schema,
  'db_datareader' AS role,
  has_schema_privilege('db_datareader', s.nspname, 'USAGE')  AS usage,
  has_schema_privilege('db_datareader', s.nspname, 'CREATE') AS create
FROM user_schemas s
UNION ALL
SELECT
  s.nspname AS schema,
  'db_datawriter' AS role,
  has_schema_privilege('db_datawriter', s.nspname, 'USAGE')  AS usage,
  has_schema_privilege('db_datawriter', s.nspname, 'CREATE') AS create
FROM user_schemas s
ORDER BY schema, role;


