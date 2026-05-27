
CREATE OR REPLACE FUNCTION public._is_excluded_schema(sname text)
RETURNS boolean
LANGUAGE plpgsql IMMUTABLE
AS $$
BEGIN
  -- If we cannot determine the schema, do NOT exclude by default
  IF sname IS NULL THEN
    RETURN false;
  END IF;

  -- System schemas
  IF sname IN ('pg_catalog','information_schema','pg_toast')
     OR sname LIKE 'pg_temp_%'
     OR sname LIKE 'pg_toast_temp_%'
	 OR sname LIKE 'pg_%' THEN
    RETURN true;
  END IF;

  -- Extension/admin schemas (adjust as needed)
  IF sname = ANY (ARRAY[
      'anon',
      'cron',
      'google_vacuum_mgmt',
      'pgagent',
      'timescaledb_internal','_timescaledb_internal',
      'topology','tiger'
  ]) THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;



-- SECURITY DEFINER helper to set ADP for postgres (unchanged from earlier)
CREATE OR REPLACE FUNCTION public._set_adp_for_postgres(target_schema text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
  IF target_schema IS NULL OR public._is_excluded_schema(target_schema) THEN
    RETURN;
  END IF;

  EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO db_datareader, db_datawriter;',
    'postgres', target_schema);

  EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT INSERT, UPDATE, DELETE ON TABLES TO db_datawriter;',
    'postgres', target_schema);

  EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT USAGE ON SCHEMAS TO db_datareader, db_datawriter;';
END;
$$;



-- Main dispatcher: resolve schema name from objid, then grant + transfer owner
CREATE OR REPLACE FUNCTION public._ddl_transfer_owner_and_grant()
RETURNS EVENT_TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER 
SET search_path = pg_catalog, public
AS $func$
DECLARE
  ev RECORD;
  sname text;
  owner_regrole TEXT;
  ident text;
  v_actor text := current_user;
BEGIN
  FOR ev IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP
    IF ev.command_tag = 'CREATE SCHEMA' THEN
      ident := ev.object_identity;

      -- Resolve schema name reliably:
      -- 1) via objid from the event (preferred)
      BEGIN
        SELECT n.nspname INTO sname
        FROM pg_namespace n
        WHERE n.oid = ev.objid;
      EXCEPTION WHEN OTHERS THEN
        sname := NULL;
      END;

	  

      -- 2) fallback to ev.schema_name
      IF sname IS NULL THEN
        sname := ev.schema_name;
      END IF;

      -- 3) final fallback to object identity text, which may be a quoted identifier
      IF sname IS NULL AND ident IS NOT NULL THEN
        -- Strip surrounding quotes if present, else keep as-is
        sname := regexp_replace(ident, '^"|"$', '', 'g');
      END IF;

      INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
      VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'resolve', 'ok',
              CASE WHEN sname IS NULL THEN 'schema_name unresolved' ELSE 'schema_name resolved' END);

      -- If still unknown, we skip but log clearly
      IF sname IS NULL THEN
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'exclude', 'skipped',
                'cannot resolve schema_name; skipping');
        CONTINUE;
      END IF;

      -- Exclusion check
      IF public._is_excluded_schema(sname) THEN
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'exclude', 'skipped', 'excluded schema');
        CONTINUE;
      END IF;

      -- 1) GRANT USAGE (owner-only; invoker is owner at ddl_command_end)
      BEGIN
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO db_datareader, db_datawriter;', sname);
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_usage', 'ok', NULL);
      EXCEPTION WHEN OTHERS THEN
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_usage', 'fail', SQLERRM);
      END;

      -- 2) Immediate object coverage (optional)
      BEGIN
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);
        EXECUTE format('GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO db_datawriter;', sname);
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_tables_views', 'ok', NULL);
      EXCEPTION WHEN OTHERS THEN
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_tables_views', 'fail', SQLERRM);
      END;

		

      -- 3) Transfer ownership to postgres (owner-only)

	  SELECT n.nspowner::regrole::text INTO owner_regrole
      FROM   pg_namespace n
      WHERE  n.nspname = sname;
	  
      BEGIN
	    execute format('grant create on schema %I to %I;',sname,owner_regrole);
		execute format('grant usage on schema %I to %I;',sname,owner_regrole);
	    execute format('grant %I to postgres with inherit true;',owner_regrole);
        EXECUTE format('ALTER SCHEMA %I OWNER TO postgres;', sname);
		INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'alter_owner', 'ok', NULL);
      EXCEPTION WHEN OTHERS THEN
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'alter_owner', 'fail', SQLERRM);
		execute format('grant create on schema %I to %I;',sname,owner_regrole);
		execute format('grant usage on schema %I to %I;',sname,owner_regrole);
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant Create and usage', 'fail', SQLERRM);
      END;
       
      -- 4) Set ADP for postgres (SECURITY DEFINER helper)
      BEGIN
        PERFORM public._set_adp_for_postgres(sname);
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'set_adp', 'ok', NULL);
      EXCEPTION WHEN OTHERS THEN
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'set_adp', 'fail', SQLERRM);
      END;

    END IF;
  END LOOP;
END;
$func$;






CREATE EVENT TRIGGER et_schema_create_transfer_owner
  ON ddl_command_end
  WHEN TAG IN ('CREATE SCHEMA')
  EXECUTE FUNCTION public._ddl_transfer_owner_and_grant();
``


DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_event_trigger WHERE evtname = 'et_on_all_create_alter') THEN
    CREATE EVENT TRIGGER et_on_all_create_alter
      ON ddl_command_end
      WHEN TAG IN ('ALTER SCHEMA','CREATE TABLE','CREATE VIEW','CREATE MATERIALIZED VIEW')
      EXECUTE FUNCTION public._ddl_transfer_owner_and_grant();
  END IF;
END
$$


CREATE TABLE IF NOT EXISTS public.ddl_event_log (
  log_time     timestamptz  DEFAULT now(),
  event_type   text,         -- TG_EVENT
  command_tag  text,         -- TG_TAG
  schema_name  text,
  object_ident text,
  actor        text,         -- current_user seen by the trigger
  step         text,         -- which step we attempted
  status       text,         -- ok | fail | skipped
  message      text          -- error message or info
);


select * from public.ddl_event_log


grant select on table app_probe4.table1 to masked_analyst


alter schema app_ledger2 owner to postgres




SELECT defaclrole::regrole AS role,
       defaclnamespace::regnamespace AS schema,
       defaclobjtype,
       defaclacl
FROM pg_default_acl
WHERE defaclnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'app_ledger1')
ORDER BY role, defaclobjtype;




SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'your_schema'



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

