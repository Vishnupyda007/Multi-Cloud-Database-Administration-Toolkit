
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT datname
    FROM pg_database
    WHERE datistemplate = false
      AND datname not in  ('postgres','cloudsqladmin')
  LOOP
    EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM PUBLIC;', r.datname);
  END LOOP;
END;
$$;


-- This script revokes CONNECT privilege from the PUBLIC role for all user databases.
DO $$
DECLARE
  db_name text;
BEGIN
  -- Loop through all databases, excluding templates and specific admin DBs.
  FOR db_name IN
    SELECT datname
    FROM pg_database
    WHERE datistemplate = false
      AND datname NOT IN ('postgres', 'cloudadmin') -- Add any other dbs to exclude
  LOOP
    RAISE NOTICE 'Revoking ALL privileges on database % from PUBLIC.', db_name;
    -- Revoke CONNECT, CREATE, and TEMPORARY privileges from the PUBLIC role.
    -- This ensures no user can connect unless explicitly granted.
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC;', db_name);
  END LOOP;
END;
$$;


-------

DO $$
DECLARE
  r RECORD;
  target_role CONSTANT TEXT := 'test_user1'; --provide the user/role name
BEGIN
  FOR r IN
    SELECT datname
    FROM pg_database
    WHERE datistemplate = false
      AND datname not in ('cloudsqladmin') --excluding the system databases
  LOOP
    RAISE NOTICE 'Revoking CONNECT on database % from role %', r.datname, target_role;
    EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM %I;', r.datname, target_role);
  END LOOP;
END;
$$ LANGUAGE plpgsql;



--------
-- This script revokes ALL database-level privileges for a SINGLE login.
DO $$
DECLARE
  v_login_name text := 'your_login_name_here'; -- << SET YOUR LOGIN NAME HERE
  v_db_name    text;
BEGIN
  RAISE NOTICE 'Starting revocation for login: %', v_login_name;
  FOR v_db_name IN
    SELECT datname
    FROM pg_database
    WHERE datistemplate = false
  LOOP
    RAISE NOTICE '--> Revoking ALL on database % from %', v_db_name, v_login_name;
    -- This revokes CONNECT, CREATE, etc., for the specified login,
    -- overriding any privileges inherited from PUBLIC.
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM %I;', v_db_name, v_login_name);
  END LOOP;
  RAISE NOTICE 'Revocation complete for login: %', v_login_name;
END;
$$;


---------------------------------------

DO $$
DECLARE
  db_name text;
BEGIN
  -- Loop through all databases, excluding templates and the specified admin DBs.
  FOR db_name IN
    SELECT datname
    FROM pg_database
    WHERE datistemplate = false
      AND datname NOT IN ('postgres', 'template0', 'template1', 'cloudadmin')
  LOOP
    -- This message provides feedback on which database is being processed.
    RAISE NOTICE 'Granting CONNECT on database: % to roles...', db_name;

    -- Dynamically and safely execute the GRANT statement for the current database in the loop.
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO db_owner, db_datareader, db_datawriter, permission_granter;', db_name);
  END LOOP;
END;
$$;



---------------

-- After connecting to a database, run this entire block.
DO $$
DECLARE
  sname text;
  creator_role text;
BEGIN
  -- This loop iterates through all schemas in the current database.
  FOR sname IN
    SELECT nspname FROM pg_catalog.pg_namespace
  LOOP
    --
    -- Embedded logic to skip system/excluded schemas
    --
    IF sname IN ('pg_catalog', 'information_schema', 'pg_toast')
       OR sname LIKE 'pg_temp_%'
       OR sname LIKE 'pg_toast_temp_%'
       OR sname = ANY (ARRAY[
            'anon', 'cron', 'google_vacuum_mgmt', 'pgagent',
            'timescaledb_internal', '_timescaledb_internal',
            'topology', 'tiger'
          ])
    THEN
      RAISE NOTICE 'Skipping excluded schema: %', sname;
      CONTINUE;
    END IF;

    RAISE NOTICE 'Applying permissions for schema: %', sname;

    -------------------------------------------------------------------------
    -- Step 1: Grant Schema-Level Privileges
    -------------------------------------------------------------------------
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO db_datareader, db_datawriter, "DBReaderTool", db_owner;', sname);
    EXECUTE format('GRANT CREATE ON SCHEMA %I TO db_owner;', sname);
    EXECUTE format('GRANT USAGE ON SCHEMA %I TO "DBReaderTool" WITH GRANT OPTION;', sname);

    -------------------------------------------------------------------------
    -- Step 2: Grant Permissions on ALL EXISTING Objects
    -------------------------------------------------------------------------
    RAISE NOTICE '--> Applying grants to EXISTING objects in %', sname;
    -- Tables
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO "DBReaderTool" WITH GRANT OPTION;', sname);
    EXECUTE format('GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO db_datawriter;', sname);
    EXECUTE format('GRANT ALL ON ALL TABLES IN SCHEMA %I TO db_owner;', sname);

    -- Sequences
    EXECUTE format('GRANT USAGE ON ALL SEQUENCES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);
    EXECUTE format('GRANT ALL ON ALL SEQUENCES IN SCHEMA %I TO db_owner;', sname);

    -- Functions
    EXECUTE format('GRANT ALL ON ALL FUNCTIONS IN SCHEMA %I TO db_owner;', sname);

    -------------------------------------------------------------------------
    -- Step 3: Set Default Privileges for ALL FUTURE Objects
    -------------------------------------------------------------------------
    RAISE NOTICE '--> Applying default privileges for FUTURE objects in %', sname;
    -- Loop through the roles that are expected to create objects
    FOREACH creator_role IN ARRAY ARRAY['db_owner', 'postgres']
    LOOP
      RAISE NOTICE '----> Setting defaults for objects created by role: %', creator_role;
      -- Future Tables
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO db_datareader, db_datawriter;', creator_role, sname);
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO "DBReaderTool" WITH GRANT OPTION;', creator_role, sname);
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT INSERT, UPDATE, DELETE ON TABLES TO db_datawriter;', creator_role, sname);
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT ALL ON TABLES TO db_owner;', creator_role, sname);

      -- Future Sequences
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT USAGE ON SEQUENCES TO db_datareader, db_datawriter;', creator_role, sname);
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT ALL ON SEQUENCES TO db_owner;', creator_role, sname);

      -- Future Functions
      EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT ALL ON FUNCTIONS TO db_owner;', creator_role, sname);
    END LOOP;

    -- Grant USAGE on future TYPES created by 'postgres' to 'db_owner'
    RAISE NOTICE '----> Setting default USAGE ON TYPES for db_owner in schema %', sname;
    EXECUTE format('ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA %I GRANT USAGE ON TYPES TO db_owner;', sname);

  END LOOP;
END;
$$;


grant connect on database "TestHouse_DB" to test_user;

grant db_datareader to test_user;

