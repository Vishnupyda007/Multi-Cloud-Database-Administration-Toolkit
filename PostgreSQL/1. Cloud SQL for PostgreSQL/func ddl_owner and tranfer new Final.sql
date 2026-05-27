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
            EXECUTE format('GRANT USAGE ON TYPE %s TO PUBLIC;', ident);
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



