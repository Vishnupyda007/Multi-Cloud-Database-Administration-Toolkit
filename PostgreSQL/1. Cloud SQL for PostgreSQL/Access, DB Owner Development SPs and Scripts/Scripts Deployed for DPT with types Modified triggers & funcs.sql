-- FUNCTION: DBAdmin._is_excluded_schema(text)
create schema if not exists "DBAdmin";
DROP FUNCTION IF EXISTS public._is_excluded_schema(text) cascade;

CREATE OR REPLACE FUNCTION "DBAdmin"._is_excluded_schema(
	sname text)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
AS $BODY$
BEGIN
  -- If we cannot determine the schema, do NOT exclude by default
  IF sname IS NULL THEN
    RETURN false;
  END IF;

  -- System schemas
  IF sname IN ('pg_catalog','information_schema','pg_toast','cron','anon','DBAdmin')
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
$BODY$;



-- FUNCTION: DBAdmin._set_adp_for_postgres(text)

DROP FUNCTION IF EXISTS public._set_adp_for_postgres(text) cascade;

CREATE OR REPLACE FUNCTION "DBAdmin"._set_adp_for_postgres(
	target_schema text)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=pg_catalog
AS $BODY$
BEGIN
  IF target_schema IS NULL OR "DBAdmin"._is_excluded_schema(target_schema) THEN
    RETURN;
  END IF;

  EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO db_datareader, db_datawriter;',
    'postgres', target_schema);

  EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT INSERT, UPDATE, DELETE ON TABLES TO db_datawriter;',
    'postgres', target_schema);

  EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO "DBReaderTool" with grant option;','postgres', target_schema)	;
	EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT maintain ON TABLES TO "DBMaintenanceUser";','postgres', target_schema)	;
	EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT all ON sequences TO db_datawriter;','postgres', target_schema)	;
		EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT select,usage ON sequences TO db_datareader;','postgres', target_schema)	;
		EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT all ON tables TO db_owner;','postgres', target_schema)	;
	EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT all ON sequences TO db_owner;','postgres', target_schema)	;
	EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT all ON functions TO db_owner;','postgres', target_schema)	;
		EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT all ON types TO db_owner,db_datareader;','postgres', target_schema)	;

  EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT USAGE ON SCHEMAS TO db_datareader, db_datawriter;';
  EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT USAGE ON SCHEMAS TO "DBReaderTool" with grant option;';
  EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT CREATE ON SCHEMAS TO "DBReaderTool";';
  EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT all ON SCHEMAS TO db_owner;';
END;
$BODY$;




-- FUNCTION: DBAdmin._ddl_transfer_owner_and_grant()

DROP FUNCTION IF EXISTS public._ddl_transfer_owner_and_grant() cascade;

CREATE OR REPLACE FUNCTION "DBAdmin"._ddl_transfer_owner_and_grant()
RETURNS event_trigger
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog
AS $BODY$
DECLARE
  ev RECORD;
  sname              text;
  owner_regrole      text;   -- schema previous owner role
  ident              text;   -- ev.object_identity (already schema-qualified & quoted if needed)
  v_actor            text := session_user;  -- real invoker
  v_sqlstate         text;
  v_sqlerrm          text;
  objtype            text;
  db_owner_role      text := 'db_owner';
BEGIN
  FOR ev IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP  -- provides object_identity etc. [1](https://www.postgresql.org/docs/current/functions-event-triggers.html)

    ---------------------------------------------------------------------------
    -- A) On CREATE SCHEMA: transfer schema owner to postgres + grants + ADP
    ---------------------------------------------------------------------------
    IF ev.command_tag = 'CREATE SCHEMA' THEN
      ident := ev.object_identity;

      -- Resolve schema name
      BEGIN
        SELECT n.nspname INTO sname
        FROM pg_namespace n
        WHERE n.oid = ev.objid;
      EXCEPTION WHEN OTHERS THEN
        sname := NULL;
      END;

      IF sname IS NULL THEN
        sname := ev.schema_name;
      END IF;

      IF sname IS NULL AND ident IS NOT NULL THEN
        sname := regexp_replace(ident, '^"|"$', '', 'g');
      END IF;

      INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
      VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'resolve', 'ok',
              CASE WHEN sname IS NULL THEN 'schema_name unresolved' ELSE 'schema_name resolved' END);

      IF sname IS NULL THEN
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'exclude', 'skipped',
                'cannot resolve schema_name; skipping');
        CONTINUE;
      END IF;

      IF "DBAdmin"._is_excluded_schema(sname) THEN
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'exclude', 'skipped', 'excluded schema');
        CONTINUE;
      END IF;

      -- 1) Base schema usage for data roles
      BEGIN
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO db_datareader, db_datawriter, "DBReaderTool";', sname);
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO "DBReaderTool" WITH GRANT OPTION;', sname);
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO "DBMaintenanceUser";', sname);

        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_usage', 'ok', NULL);
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_usage', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;

      -- 2) Immediate coverage for existing objects
      BEGIN
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO "DBReaderTool" WITH GRANT OPTION;', sname);
        EXECUTE format('GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO db_datawriter;', sname);
        EXECUTE format('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);
        EXECUTE format('GRANT MAINTAIN ON ALL TABLES IN SCHEMA %I TO "DBMaintenanceUser";', sname);
        EXECUTE format('GRANT ALL ON ALL SEQUENCES IN SCHEMA %I TO db_datawriter;', sname);

        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_existing_objects', 'ok', NULL);
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_existing_objects', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;

      -- 3a) Capture schema previous owner
SELECT n.nspowner::regrole::text INTO owner_regrole
FROM pg_namespace n
WHERE n.nspname = sname;

-- 3b) ALTER SCHEMA OWNER (standalone block)
BEGIN
  EXECUTE format('ALTER SCHEMA %I OWNER TO %I;', sname, 'postgres');

  INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
  VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'alter_schema_owner', 'ok', 'schema owner set to postgres');
EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;

  INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
  VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'alter_schema_owner', 'fail',
          format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
END;

-- 3c) Grant schema privileges to db_owner (standalone block + role existence check)
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = db_owner_role) THEN
    EXECUTE format('GRANT USAGE, CREATE ON SCHEMA %I TO %I;', sname, db_owner_role);

    INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
    VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_db_owner_schema', 'ok',
            format('granted USAGE,CREATE on schema to %s', db_owner_role));
  ELSE
    INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
    VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_db_owner_schema', 'skipped',
            format('role %s does not exist', db_owner_role));
  END IF;
EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;

  INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
  VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_db_owner_schema', 'fail',
          format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
END;

-- 3d) Preserve previous owner schema access (standalone block)
BEGIN
  IF owner_regrole IS NOT NULL AND owner_regrole <> 'postgres' THEN
    EXECUTE format('GRANT USAGE, CREATE ON SCHEMA %I TO %I;', sname, owner_regrole);
  END IF;

  INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
  VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'preserve_prev_owner_schema', 'ok',
          COALESCE('previous owner preserved: ' || owner_regrole, 'previous owner unknown'));
EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;

  INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
  VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'preserve_prev_owner_schema', 'fail',
          format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
END;

      -- 4) Default privileges (may fail depending on role membership rules). [3](https://www.postgresql.org/docs/current/sql-alterdefaultprivileges.html)[4](https://postgrespro.com/docs/postgresql/current/sql-alterdefaultprivileges.html)
      BEGIN
        -- Defaults for the invoker (session_user)
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT ALL ON TABLES TO %I;',
                       v_actor, sname, db_owner_role);
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT ALL ON SEQUENCES TO %I;',
                       v_actor, sname, db_owner_role);
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT ALL ON FUNCTIONS TO %I;',
                       v_actor, sname, db_owner_role);
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT ALL ON TYPES TO %I;',
                       v_actor, sname, db_owner_role);

        -- Defaults for postgres (new schema owner)
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT ALL ON TABLES TO %I;',
                       'postgres', sname, db_owner_role);
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT ALL ON SEQUENCES TO %I;',
                       'postgres', sname, db_owner_role);
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT ALL ON FUNCTIONS TO %I;',
                       'postgres', sname, db_owner_role);
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT USAGE ON TYPES TO %I;',
                       'postgres', sname, db_owner_role);

        -- Keep datareader/writer defaults
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO db_datareader, db_datawriter;',
                       v_actor, sname);
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO "DBReaderTool" WITH GRANT OPTION;',
                       v_actor, sname);
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT INSERT, UPDATE, DELETE ON TABLES TO db_datawriter;',
                       v_actor, sname);
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT USAGE, SELECT ON SEQUENCES TO db_datareader, db_datawriter;',
                       v_actor, sname);
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT ALL ON SEQUENCES TO db_datawriter;',
                       v_actor, sname);
        EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT MAINTAIN ON TABLES TO "DBMaintenanceUser";',
                       v_actor, sname);
	    EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT usage ON types TO db_datareader;',
                       v_actor, sname);

        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'set_default_privileges', 'ok',
                format('defaults set for roles: %s, postgres; db_owner=%s', v_actor, db_owner_role));
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'set_default_privileges', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;

      -- 5) Optional: keep your ADP helper
      BEGIN
        PERFORM "DBAdmin"._set_adp_for_postgres(sname);
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'set_adp', 'ok', NULL);
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'set_adp', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;


    ---------------------------------------------------------------------------
    -- B) On other CREATE/ALTER commands:
    --    ✅ DO NOT transfer owner (owner stays as creator)
    --    ✅ Apply GRANTs using object_identity as SQL text (%s). [1](https://www.postgresql.org/docs/current/functions-event-triggers.html)
    ---------------------------------------------------------------------------
    ELSIF ev.command_tag IN
      ('ALTER SCHEMA','CREATE TABLE','CREATE VIEW','CREATE MATERIALIZED VIEW',
       'CREATE SEQUENCE','CREATE FUNCTION','CREATE TYPE','CREATE DOMAIN')
    THEN
      sname   := ev.schema_name;
      ident   := ev.object_identity;  -- already schema-qualified & quoted if needed [1](https://www.postgresql.org/docs/current/functions-event-triggers.html)
      objtype := ev.object_type;

      INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
      VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'start', 'ok', format('Processing object type: %s', objtype));

      IF "DBAdmin"._is_excluded_schema(sname) THEN
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'exclude', 'skipped', 'excluded schema');
        CONTINUE;
      END IF;

      -- Apply permissions (no ALTER OWNER here)
      BEGIN
        CASE objtype
          WHEN 'table', 'view', 'materialized view' THEN
            EXECUTE format('GRANT SELECT ON %s TO db_datareader, db_datawriter;', ident);
            EXECUTE format('GRANT INSERT, UPDATE, DELETE ON %s TO db_datawriter;', ident);
            EXECUTE format('GRANT SELECT ON %s TO "DBReaderTool" WITH GRANT OPTION;', ident);
            EXECUTE format('GRANT MAINTAIN ON %s TO "DBMaintenanceUser";', ident);
            EXECUTE format('GRANT ALL ON %s TO %I;', ident, db_owner_role);

          WHEN 'sequence' THEN
            EXECUTE format('GRANT USAGE, SELECT ON %s TO db_datareader, db_datawriter;', ident);
            EXECUTE format('GRANT ALL ON %s TO db_datawriter;', ident);
            EXECUTE format('GRANT ALL ON %s TO %I;', ident, db_owner_role);

          WHEN 'function' THEN
            -- ident includes arguments; keep as %s
            EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO %I;', ident, db_owner_role);

          WHEN 'type', 'domain' THEN
            EXECUTE format('GRANT USAGE ON TYPE %s TO db_datareader;', ident);
            EXECUTE format('GRANT USAGE ON TYPE %s TO %I;', ident, db_owner_role);

          ELSE
            NULL;
        END CASE;

        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_permissions', 'ok',
                format('Grants applied for object type: %s', objtype));

      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_permissions', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;

    END IF;

  END LOOP;
END;
$BODY$;

ALTER FUNCTION "DBAdmin"._ddl_transfer_owner_and_grant()
OWNER TO postgres;

GRANT EXECUTE ON FUNCTION "DBAdmin"._ddl_transfer_owner_and_grant() TO postgres;

REVOKE ALL ON FUNCTION "DBAdmin"._ddl_transfer_owner_and_grant() FROM PUBLIC;



drop event trigger if exists et_on_all_create_alter;
CREATE EVENT TRIGGER et_on_all_create_alter ON DDL_COMMAND_END
    WHEN TAG IN ('ALTER SCHEMA', 'CREATE TABLE', 'CREATE VIEW', 'CREATE MATERIALIZED VIEW', 'CREATE SEQUENCE', 'CREATE FUNCTION', 'CREATE TYPE', 'CREATE DOMAIN')
    EXECUTE FUNCTION "DBAdmin"._ddl_transfer_owner_and_grant();



drop event trigger if exists et_schema_create_transfer_owner;
CREATE EVENT TRIGGER et_schema_create_transfer_owner ON DDL_COMMAND_END
    WHEN TAG IN ('CREATE SCHEMA')
    EXECUTE FUNCTION "DBAdmin"._ddl_transfer_owner_and_grant();




drop table if exists public.ddl_event_log cascade;
CREATE TABLE IF NOT EXISTS "DBAdmin".ddl_event_log
(
    log_time timestamp with time zone DEFAULT now(),
    event_type text COLLATE pg_catalog."default",
    command_tag text COLLATE pg_catalog."default",
    schema_name text COLLATE pg_catalog."default",
    object_ident text COLLATE pg_catalog."default",
    actor text COLLATE pg_catalog."default",
    step text COLLATE pg_catalog."default",
    status text COLLATE pg_catalog."default",
    message text COLLATE pg_catalog."default"
)

TABLESPACE pg_default;



-- This is the CORRECTED script with added exception handling for grant errors.
-- It will now skip grants that would cause a circular dependency (SQLSTATE '0LP01')
-- and continue execution, making it safe to run on complex environments.
ALTER SCHEMA public
    OWNER TO postgres;


GRANT USAGE ON SCHEMA public TO "DBReaderTool" WITH GRANT OPTION;

GRANT USAGE ON SCHEMA public TO db_datareader;

GRANT USAGE ON SCHEMA public TO db_datawriter;

GRANT ALL ON SCHEMA public TO db_owner;

GRANT USAGE ON SCHEMA public TO "DBMaintenanceUser";

DO $$
DECLARE
    sname         text;
    db_owner_role text := 'db_owner';
    type_record   record;
BEGIN
    RAISE NOTICE 'Starting permission backfill for existing schemas...';

    FOR sname IN
        SELECT nspname FROM pg_namespace
    LOOP
        IF "DBAdmin"._is_excluded_schema(sname) THEN
            RAISE NOTICE 'Skipping excluded schema: %', sname;
            CONTINUE;
        END IF;

        RAISE NOTICE 'Processing schema: %', sname;

        --------------------------------------------------------------------
        -- 1) Schema-level USAGE grants
        --------------------------------------------------------------------
        BEGIN
            EXECUTE format('GRANT USAGE ON SCHEMA %I TO db_datareader, db_datawriter, "DBReaderTool";', sname);

            -- Try grant option; if blocked by grant-chain rules, retry without GO
            BEGIN
                EXECUTE format('GRANT USAGE ON SCHEMA %I TO "DBReaderTool" WITH GRANT OPTION;', sname);
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '  - NOTICE: USAGE WITH GRANT OPTION failed on schema %, retrying without GO. Error: %', sname, SQLERRM;
                EXECUTE format('GRANT USAGE ON SCHEMA %I TO "DBReaderTool";', sname);
            END;

            EXECUTE format('GRANT USAGE ON SCHEMA %I TO "DBMaintenanceUser";', sname);

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - NOTICE: Could not apply some schema USAGE grants on %. Error: %', sname, SQLERRM;
        END;

        --------------------------------------------------------------------
        -- 2) Existing tables
        --------------------------------------------------------------------
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);

        -- This is the statement that failed for public: handle it safely
        BEGIN
            EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO "DBReaderTool" WITH GRANT OPTION;', sname);
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - NOTICE: SELECT WITH GRANT OPTION failed on tables in schema %, retrying without GO. Error: %', sname, SQLERRM;
            EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO "DBReaderTool";', sname);
        END;

        EXECUTE format('GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO db_datawriter;', sname);
        EXECUTE format('GRANT MAINTAIN ON ALL TABLES IN SCHEMA %I TO "DBMaintenanceUser";', sname);
        EXECUTE format('GRANT ALL ON ALL TABLES IN SCHEMA %I TO %I;', sname, db_owner_role);

        --------------------------------------------------------------------
        -- 3) Existing sequences
        --------------------------------------------------------------------
        EXECUTE format('GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);
        EXECUTE format('GRANT ALL ON ALL SEQUENCES IN SCHEMA %I TO db_datawriter;', sname);
        EXECUTE format('GRANT ALL ON ALL SEQUENCES IN SCHEMA %I TO %I;', sname, db_owner_role);

        --------------------------------------------------------------------
        -- 4) Existing functions
        --------------------------------------------------------------------
        BEGIN
            EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %I TO %I;', sname, db_owner_role);
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  - NOTICE: Grant EXECUTE on all functions failed in schema %. Error: %', sname, SQLERRM;
        END;

        --------------------------------------------------------------------
        -- 5) Existing types/domains/enums (grant USAGE individually)
        --------------------------------------------------------------------
        FOR type_record IN
            SELECT t.typname
            FROM pg_type t
            JOIN pg_namespace n ON t.typnamespace = n.oid
            WHERE n.nspname = sname
              AND t.typtype IN ('c', 'd', 'e') -- composite/domain/enum
              AND NOT EXISTS (
                  SELECT 1
                  FROM pg_depend d
                  WHERE d.objid = t.oid
                    AND d.deptype = 'e' -- extension-owned
              )
        LOOP
            BEGIN
                EXECUTE format('GRANT USAGE ON TYPE %I.%I TO %I;', sname, type_record.typname, db_owner_role);
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '  - NOTICE: Grant USAGE on type %.% failed. Error: %', sname, type_record.typname, SQLERRM;
            END;
        END LOOP;

        --------------------------------------------------------------------
        -- 6) Ensure db_owner has schema-level USAGE + CREATE
        --    (these are the schema privileges PostgreSQL supports) [2](https://www.pgtutorial.com/postgresql-tutorial/postgresql-event-triggers/)
        --------------------------------------------------------------------
        EXECUTE format('GRANT USAGE, CREATE ON SCHEMA %I TO %I;', sname, db_owner_role);

        --------------------------------------------------------------------
        -- 7) Default privileges for future objects created by postgres
        --    (applies only to future objects, not existing ones) [3](https://postgrespro.com/docs/postgresql/current/sql-grant)[4](https://www.geeksforgeeks.org/postgresql/postgresql-alter-schema/)
        --------------------------------------------------------------------
        PERFORM "DBAdmin"._set_adp_for_postgres(sname);

    END LOOP;

    RAISE NOTICE 'Finished processing all schemas.';
END;
$$;



-------------------------


ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT EXECUTE ON FUNCTIONS TO db_owner;

GRANT CREATE ON DATABASE template1 TO "DBReaderTool";
GRANT CONNECT ON DATABASE template1 TO "DBReaderTool" WITH GRANT OPTION;
GRANT CONNECT ON DATABASE template1 TO "DBMaintenanceUser";
GRANT CONNECT ON DATABASE template1 TO "ITESVMadmin";


ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT SELECT ON TABLES TO "DBReaderTool" WITH GRANT OPTION;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT SELECT ON TABLES TO db_datareader;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT DELETE, INSERT, SELECT, UPDATE ON TABLES TO db_datawriter;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT ALL ON TABLES TO db_owner;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT MAINTAIN ON TABLES TO "DBMaintenanceUser";

ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT SELECT, USAGE ON SEQUENCES TO db_datareader;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT ALL ON SEQUENCES TO db_datawriter;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT ALL ON SEQUENCES TO db_owner;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT USAGE ON TYPES TO db_owner,db_datareader;



GRANT CREATE ON SCHEMA public TO "DBReaderTool";
GRANT USAGE ON SCHEMA public TO "DBReaderTool" WITH GRANT OPTION;

GRANT USAGE ON SCHEMA public TO db_datareader;

GRANT USAGE ON SCHEMA public TO db_datawriter;

GRANT ALL ON SCHEMA public TO db_owner;

GRANT USAGE ON SCHEMA public TO "DBMaintenanceUser";

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT SELECT ON TABLES TO "DBReaderTool" WITH GRANT OPTION;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT SELECT ON TABLES TO db_datareader;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT DELETE, INSERT, SELECT, UPDATE ON TABLES TO db_datawriter;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT ALL ON TABLES TO db_owner;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT MAINTAIN ON TABLES TO "DBMaintenanceUser";

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT SELECT, USAGE ON SEQUENCES TO db_datareader;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT ALL ON SEQUENCES TO db_datawriter;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT ALL ON SEQUENCES TO db_owner;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT EXECUTE ON FUNCTIONS TO db_owner;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
GRANT USAGE ON TYPES TO db_owner,db_datareader;

GRANT ALL ON SCHEMA "DBAdmin" TO "DBMaintenanceUser";

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA "DBAdmin"
GRANT DELETE, INSERT, SELECT, TRUNCATE, UPDATE ON TABLES TO "DBMaintenanceUser";

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA "DBAdmin"
GRANT ALL ON SEQUENCES TO "DBMaintenanceUser";

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA "DBAdmin"
GRANT EXECUTE ON FUNCTIONS TO "DBMaintenanceUser";