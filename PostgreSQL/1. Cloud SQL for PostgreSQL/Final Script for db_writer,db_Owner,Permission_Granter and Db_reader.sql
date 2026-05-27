-- FUNCTION: public._ddl_transfer_owner_and_grant()

-- DROP FUNCTION IF EXISTS public._ddl_transfer_owner_and_grant();

CREATE OR REPLACE FUNCTION public._ddl_transfer_owner_and_grant()
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

      INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
      VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'resolve', 'ok',
              CASE WHEN sname IS NULL THEN 'schema_name unresolved' ELSE 'schema_name resolved' END);

      IF sname IS NULL THEN
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'exclude', 'skipped',
                'cannot resolve schema_name; skipping');
        CONTINUE;
      END IF;

      IF public._is_excluded_schema(sname) THEN
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'exclude', 'skipped', 'excluded schema');
        CONTINUE;
      END IF;

      -- 1) Base schema usage for data roles
      BEGIN
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO db_datareader, db_datawriter, permission_granter;', sname);
		EXECUTE format('GRANT USAGE ON SCHEMA %I TO permission_granter with grant option;', sname);
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_usage', 'ok', NULL);
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_usage', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;

      -- 2) Immediate coverage for existing objects
      BEGIN
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);
		EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO permission_granter WITH GRANT OPTION;', sname);
        EXECUTE format('GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO db_datawriter;', sname);
        EXECUTE format('GRANT USAGE ON ALL SEQUENCES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);
		
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_existing_objects', 'ok', NULL);
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
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

        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'alter_owner', 'ok',
                CASE WHEN owner_regrole IS NULL
                     THEN 'previous owner unknown'
                     ELSE format('previous owner preserved: %s; db_owner granted', owner_regrole)
                END);
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
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
           GRANT all ON TYPES TO %I;',
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
           GRANT SELECT ON TABLES TO permission_granter with grant option;',
          v_actor, sname
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT INSERT, UPDATE, DELETE ON TABLES TO db_datawriter;',
          v_actor, sname
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT USAGE ON SEQUENCES TO db_datareader, db_datawriter;',
          v_actor, sname
        );

        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'set_default_privileges', 'ok',
                format('defaults set for roles: %s, postgres; db_owner=%s', v_actor, db_owner_role));
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'set_default_privileges', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;

      -- 5) Optional: keep your ADP helper
      BEGIN
        PERFORM public._set_adp_for_postgres(sname);
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'set_adp', 'ok', NULL);
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'set_adp', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;

    END IF; -- CREATE SCHEMA

    
  END LOOP;
END;
$BODY$;



-----------------



-- FUNCTION: public._set_adp_for_postgres(text)

-- DROP FUNCTION IF EXISTS public._set_adp_for_postgres(text);

CREATE OR REPLACE FUNCTION public._set_adp_for_postgres(
	target_schema text)
    RETURNS void
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE SECURITY DEFINER PARALLEL UNSAFE
    SET search_path=pg_catalog
AS $BODY$
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

  EXECUTE format(
    'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO permission_granter with grant option;','postgres', target_schema)	;

  EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT USAGE ON SCHEMAS TO db_datareader, db_datawriter;';
  EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT USAGE ON SCHEMAS TO permission_granter with grant option;';
END;
$BODY$;





------------------




-- FUNCTION: public._is_excluded_schema(text)

-- DROP FUNCTION IF EXISTS public._is_excluded_schema(text);

CREATE OR REPLACE FUNCTION public._is_excluded_schema(
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
$BODY$;

ALTER FUNCTION public._is_excluded_schema(text)
    OWNER TO postgres;




--------------------------------------------------



-- Event triggers (keep your existing attachments and add the tags we now handle)
DROP EVENT TRIGGER IF EXISTS et_schema_create_transfer_owner;
CREATE EVENT TRIGGER et_schema_create_transfer_owner
  ON ddl_command_end
  WHEN TAG IN ('CREATE SCHEMA')
  EXECUTE FUNCTION public._ddl_transfer_owner_and_grant();

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_event_trigger WHERE evtname = 'et_on_all_create_alter') THEN
    CREATE EVENT TRIGGER et_on_all_create_alter
      ON ddl_command_end
      WHEN TAG IN (
        'ALTER SCHEMA',
        'CREATE TABLE','CREATE VIEW','CREATE MATERIALIZED VIEW',
        'CREATE SEQUENCE','CREATE FUNCTION','CREATE TYPE','CREATE DOMAIN'
      )
      EXECUTE FUNCTION public._ddl_transfer_owner_and_grant();
  END IF;
END $$




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


