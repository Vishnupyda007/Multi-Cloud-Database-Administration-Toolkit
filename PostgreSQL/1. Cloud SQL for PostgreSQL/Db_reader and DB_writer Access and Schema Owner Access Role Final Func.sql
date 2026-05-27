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



CREATE OR REPLACE FUNCTION public._ddl_transfer_owner_and_grant()
RETURNS EVENT_TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $func$
DECLARE
  ev RECORD;
  sname              text;
  owner_regrole      text;   -- previous owner role name as text
  ident              text;
  v_actor            text := session_user;  -- use session_user to capture the real invoker
  v_sqlstate         text;
  v_sqlerrm          text;
  objname            text;
  objtype            text;
BEGIN
  FOR ev IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP

    ------------------------------------------------------------------------------
    -- A) On CREATE SCHEMA: transfer owner, grant schema usage/create, set defaults
    ------------------------------------------------------------------------------
    IF ev.command_tag = 'CREATE SCHEMA' THEN
      ident := ev.object_identity;

      -- Resolve schema name reliably:
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
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO db_datareader, db_datawriter;', sname);
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

        IF owner_regrole IS NOT NULL AND owner_regrole <> 'postgres' THEN
          EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I;', sname, owner_regrole);
          EXECUTE format('GRANT CREATE ON SCHEMA %I TO %I;', sname, owner_regrole);
        END IF;

        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'alter_owner', 'ok',
                CASE WHEN owner_regrole IS NULL
                     THEN 'previous owner unknown'
                     ELSE format('previous owner preserved: %s', owner_regrole)
                END);
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'alter_owner', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));

        BEGIN
          IF owner_regrole IS NOT NULL AND owner_regrole <> 'postgres' THEN
            EXECUTE format('GRANT USAGE ON SCHEMA %I TO %I;', sname, owner_regrole);
            EXECUTE format('GRANT CREATE ON SCHEMA %I TO %I;', sname, owner_regrole);
          END IF;
          INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
          VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_create_usage_postfail', 'ok', NULL);
        EXCEPTION WHEN OTHERS THEN
          GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
          INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
          VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'grant_create_usage_postfail', 'fail',
                  format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
        END;
      END;

      -- 4) Alter Default Privileges: for session_user (real invoker) and postgres
      BEGIN
        -- Defaults for the actual invoker (session_user)
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT SELECT ON TABLES TO db_datareader, db_datawriter;',
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
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT USAGE ON TYPES TO db_datareader, db_datawriter;',
          v_actor, sname
        );

        -- Defaults for postgres (new owner, may create objects)
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT SELECT ON TABLES TO db_datareader, db_datawriter;',
          'postgres', sname
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT INSERT, UPDATE, DELETE ON TABLES TO db_datawriter;',
          'postgres', sname
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT USAGE ON SEQUENCES TO db_datareader, db_datawriter;',
          'postgres', sname
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT USAGE ON TYPES TO db_datareader, db_datawriter;',
          'postgres', sname
        );

        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, ident, v_actor, 'set_default_privileges', 'ok',
                format('defaults set for roles: %s, postgres', v_actor));
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

    ------------------------------------------------------------------------------
    -- B) On CREATE TABLE / VIEW / MATERIALIZED VIEW: grant on the specific object
    ------------------------------------------------------------------------------
    IF ev.command_tag IN ('CREATE TABLE', 'CREATE VIEW', 'CREATE MATERIALIZED VIEW') THEN
      -- Resolve schema and object name
      objtype := ev.object_type;     -- e.g., 'table', 'view', 'materialized view'
      objname := ev.object_identity; -- e.g., schema.obj
      sname   := ev.schema_name;

      -- Fallback: try to split object_identity "schema.object"
      IF sname IS NULL AND objname IS NOT NULL THEN
        BEGIN
          sname := split_part(objname, '.', 1);
        EXCEPTION WHEN OTHERS THEN
          sname := NULL;
        END;
      END IF;

      -- Skip excluded schemas
      IF sname IS NULL OR public._is_excluded_schema(sname) THEN
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, objname, v_actor, 'grant_new_object', 'skipped', 'schema unresolved or excluded');
        CONTINUE;
      END IF;

      -- Grant privileges on the newly created object
      BEGIN
        -- Tables & materialized views: table-level privileges apply
        IF ev.command_tag IN ('CREATE TABLE', 'CREATE MATERIALIZED VIEW') THEN
          EXECUTE format('GRANT SELECT ON %s TO db_datareader, db_datawriter;', objname);
          EXECUTE format('GRANT INSERT, UPDATE, DELETE ON %s TO db_datawriter;', objname);
        ELSIF ev.command_tag = 'CREATE VIEW' THEN
          -- Views: only SELECT (DML doesn’t apply to views unless INSTEAD OF rules)
          EXECUTE format('GRANT SELECT ON %s TO db_datareader, db_datawriter;', objname);
        END IF;

        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, objname, v_actor, 'grant_new_object', 'ok', objtype);
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
               INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, objname, v_actor, 'grant_new_object', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;
    END IF;

  END LOOP;
END;
$func$;




-- Event triggers
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
      WHEN TAG IN ('ALTER SCHEMA','CREATE TABLE','CREATE VIEW','CREATE MATERIALIZED VIEW')
      EXECUTE FUNCTION public._ddl_transfer_owner_and_grant();
  END IF;
END
$$;
