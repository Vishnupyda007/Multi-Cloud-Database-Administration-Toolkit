
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
           GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO %I;',
          v_actor, sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT USAGE ON SEQUENCES TO %I;',
          v_actor, sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT EXECUTE ON FUNCTIONS TO %I;',
          v_actor, sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT USAGE ON TYPES TO %I;',
          v_actor, sname, db_owner_role
        );

        -- Defaults for postgres (new schema owner)
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO %I;',
          'postgres', sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT USAGE ON SEQUENCES TO %I;',
          'postgres', sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT EXECUTE ON FUNCTIONS TO %I;',
          'postgres', sname, db_owner_role
        );
        EXECUTE format(
          'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
           GRANT USAGE ON TYPES TO %I;',
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

    ---------------------------------------------------------------------------
    -- B) On object creation: make db_owner the owner (=> can DROP/ALTER)
    ---------------------------------------------------------------------------
    IF ev.command_tag IN ('CREATE TABLE', 'CREATE VIEW', 'CREATE MATERIALIZED VIEW',
                          'CREATE SEQUENCE', 'CREATE FUNCTION', 'CREATE TYPE', 'CREATE DOMAIN') THEN
           objtype := ev.object_type;
      objname := ev.object_identity;  -- already qualified and properly formatted
      sname   := ev.schema_name;

      IF sname IS NULL AND objname IS NOT NULL THEN
        BEGIN
          sname := split_part(objname, '.', 1);
        EXCEPTION WHEN OTHERS THEN
          sname := NULL;
        END;
      END IF;

      IF sname IS NULL OR public._is_excluded_schema(sname) THEN
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, objname, v_actor, 'db_owner_ownership', 'skipped',
                'schema unresolved or excluded');
        CONTINUE;
      END IF;

      -- 1) Transfer object ownership to db_owner (type-specific ALTER)
      BEGIN
        IF ev.command_tag = 'CREATE TABLE' THEN
          EXECUTE format('ALTER TABLE %s OWNER TO %I;', objname, db_owner_role);
        ELSIF ev.command_tag = 'CREATE VIEW' THEN
          EXECUTE format('ALTER VIEW %s OWNER TO %I;', objname, db_owner_role);
        ELSIF ev.command_tag = 'CREATE MATERIALIZED VIEW' THEN
          EXECUTE format('ALTER MATERIALIZED VIEW %s OWNER TO %I;', objname, db_owner_role);
        ELSIF ev.command_tag = 'CREATE SEQUENCE' THEN
          EXECUTE format('ALTER SEQUENCE %s OWNER TO %I;', objname, db_owner_role);
        ELSIF ev.command_tag = 'CREATE FUNCTION' THEN
          -- object_identity contains full signature; use %s
          EXECUTE format('ALTER FUNCTION %s OWNER TO %I;', objname, db_owner_role);
        ELSIF ev.command_tag = 'CREATE TYPE' THEN
          EXECUTE format('ALTER TYPE %s OWNER TO %I;', objname, db_owner_role);
        ELSIF ev.command_tag = 'CREATE DOMAIN' THEN
          EXECUTE format('ALTER DOMAIN %s OWNER TO %I;', objname, db_owner_role);
        END IF;

        -- Keep data roles grants (idempotent)
        IF ev.command_tag IN ('CREATE TABLE', 'CREATE MATERIALIZED VIEW') THEN
          EXECUTE format('GRANT SELECT ON %s TO db_datareader, db_datawriter;', objname);
          EXECUTE format('GRANT INSERT, UPDATE, DELETE ON %s TO db_datawriter;', objname);
        ELSIF ev.command_tag = 'CREATE VIEW' THEN
          EXECUTE format('GRANT SELECT ON %s TO db_datareader, db_datawriter;', objname);
        ELSIF ev.command_tag = 'CREATE SEQUENCE' THEN
          EXECUTE format('GRANT USAGE ON %s TO db_datareader, db_datawriter;', objname);
        END IF;

        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, objname, v_actor, 'db_owner_ownership', 'ok',
                format('owner set to %s', db_owner_role));
      EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT;
        INSERT INTO public.ddl_event_log(event_type,command_tag,schema_name,object_ident,actor,step,status,message)
        VALUES (TG_EVENT, TG_TAG, sname, objname, v_actor, 'db_owner_ownership', 'fail',
                format('%s [SQLSTATE: %s]', v_sqlerrm, v_sqlstate));
      END;
    END IF;

  END LOOP;
END;
$func$;

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


select * from public.ddl_event_log