--first create schema and Objects and then provide access in template1 db.

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
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT all ON types TO db_owner;','postgres', target_schema)	;

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
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF SECURITY DEFINER
    SET search_path=pg_catalog, public
AS $BODY$
DECLARE
  ev RECORD;
  sname              text;
  owner_regrole      text;   -- previous owner role name as text
  ident              text;
  v_actor            text := session_user;  -- use session_user (real invoker)
  v_sqlstate         text;
  v_sqlerrm          text;
  objname            text;   -- fully qualified identity (e.g., schema.table, schema.func(args))
  objtype            text;
  db_owner_role      text := 'db_owner';    -- <<< change here if you prefer a different role name
BEGIN
  FOR ev IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP

    ---------------------------------------------------------------------------
    -- A) On CREATE SCHEMA: grant db_owner abilities + preserve previous owner
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
		EXECUTE format('GRANT USAGE ON SCHEMA %I TO "DBReaderTool" with grant option;', sname);
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
        EXECUTE format('GRANT USAGE,select ON ALL SEQUENCES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);
		EXECUTE format('GRANT maintain ON ALL TABLES IN SCHEMA %I TO "DBMaintenanceUser";', sname);
		 EXECUTE format('GRANT all ON ALL SEQUENCES IN SCHEMA %I TO db_datawriter;', sname);
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_existing_objects', 'ok', NULL);
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_existing_objects', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;

      -- 3) Transfer ownership to postgres, preserve previous owner's access
      SELECT n.nspowner::regrole::text INTO owner_regrole
      FROM   pg_namespace n
      WHERE  n.nspname = sname;

      BEGIN
        IF owner_regrole IS NOT NULL AND owner_regrole <> 'postgres' THEN
          EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I;', sname, owner_regrole);
          EXECUTE format('GRANT CREATE ON SCHEMA %I TO %I;', sname, owner_regrole);
        END IF;

        EXECUTE format('ALTER SCHEMA %I OWNER TO %I;', sname, 'postgres');

        -- Ensure db_owner has schema-level capabilities
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I;', sname, db_owner_role);
        EXECUTE format('GRANT CREATE ON SCHEMA %I TO %I;', sname, db_owner_role);

        IF owner_regrole IS NOT NULL AND owner_regrole <> 'postgres' THEN
          EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I;', sname, owner_regrole);
          EXECUTE format('GRANT CREATE ON SCHEMA %I TO %I;', sname, owner_regrole);
        END IF;

        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'alter_owner', 'ok',
                CASE WHEN owner_regrole IS NULL
                     THEN 'previous owner unknown'
                     ELSE format('previous owner preserved: %s; db_owner granted', owner_regrole)
                END);
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO "DBAdmin".ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'alter_owner', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;

      -- 4) Alter Default Privileges: for session_user and postgres and db_owner
      BEGIN
        -- Defaults for the actual invoker (session_user)
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT all ON TABLES TO %I;',
          v_actor, sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT all ON SEQUENCES TO %I;',
          v_actor, sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT all ON FUNCTIONS TO %I;',
          v_actor, sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT all ON TYPES TO %I;',
          v_actor, sname, db_owner_role
        );

        -- Defaults for postgres (new schema owner)
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT all ON TABLES TO %I;',
          'postgres', sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT all ON SEQUENCES TO %I;',
          'postgres', sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT all ON FUNCTIONS TO %I;',
          'postgres', sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT usage ON TYPES TO %I;',
          'postgres', sname, db_owner_role
        );

        -- Keep datareader/writer defaults too
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT SELECT ON TABLES TO db_datareader, db_datawriter;',
          v_actor, sname
        );
		EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT SELECT ON TABLES TO "DBReaderTool" with grant option;',
          v_actor, sname
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT INSERT, UPDATE, DELETE ON TABLES TO db_datawriter;',
          v_actor, sname
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT USAGE,select ON SEQUENCES TO db_datareader, db_datawriter;',
          v_actor, sname
        );
		EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT all ON SEQUENCES TO db_datawriter;',
          v_actor, sname
        );
		EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT maintain ON tables TO "DBMaintenanceUser";',
          v_actor, sname
        );

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

    END IF; -- CREATE SCHEMA

    
  END LOOP;
END;
$BODY$;



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


------


ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT EXECUTE ON FUNCTIONS TO db_owner;

GRANT CREATE ON DATABASE template1 TO "DBReaderTool";
GRANT CONNECT ON DATABASE template1 TO "DBReaderTool" WITH GRANT OPTION;
GRANT CONNECT ON DATABASE template1 TO "DBMaintenanceUser";

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
GRANT USAGE ON TYPES TO db_owner;



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
GRANT USAGE ON TYPES TO db_owner;