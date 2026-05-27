CREATE ROLE permission_granter;



-- Connect to your user database (e.g., 'og_db')
grant connect on database ent_data_store to permission_granter with grant option;
-- Give 'permission_granter' the ability to pass on USAGE rights for the schema
GRANT USAGE ON SCHEMA public TO permission_granter WITH GRANT OPTION;

-- Give 'permission_granter' the ability to pass on table rights
GRANT SELECT  ON ALL TABLES IN SCHEMA public TO permission_granter WITH GRANT OPTION;

-- Do the same for all future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON  TABLES TO permission_granter WITH GRANT OPTION;




-- Run this from any database
GRANT permission_granter TO deploytool;

--grant "OneC_4681" to postgres;

-- =====================================================================
-- SCRIPT TO GRANT CONNECT (WITH GRANT OPTION) ON ALL USER DATABASES
-- Run this script from the 'postgres' database.
-- =====================================================================

DO $$
DECLARE
    -- Declare a variable to hold the name of each database as we loop
    db_name TEXT;
BEGIN
    RAISE NOTICE 'Starting to grant CONNECT permissions for role "permission_granter"...';

    -- Loop through all databases that are not templates and not the 'postgres' DB itself
    FOR db_name IN
        SELECT datname
        FROM pg_database
        WHERE datistemplate = false
          AND datname NOT IN ('postgres', 'cloudsqladmin','template0','template1') -- Exclude system/admin DBs
    LOOP
        -- Log which database we are currently processing
        RAISE NOTICE ' -> Processing database: %', quote_ident(db_name);

        -- Dynamically build and execute the GRANT command for the current database
        -- %I is a format specifier that safely quotes the database name as an identifier.
        EXECUTE format('GRANT CONNECT ON DATABASE %I TO permission_granter WITH GRANT OPTION;', db_name);

        RAISE NOTICE '    -> Granted CONNECT on database % to "permission_granter".', quote_ident(db_name);

    END LOOP;

    RAISE NOTICE '--- All user databases processed successfully! ---';
END $$;


-- =====================================================================
-- DYNAMIC SCRIPT TO GRANT PERMISSIONS ACROSS ALL SCHEMAS
-- =====================================================================

DO $$
DECLARE
    -- Declare a variable to hold the name of each schema as we loop
    schema_name TEXT;
BEGIN
    RAISE NOTICE 'Starting to grant permissions for role "permission_granter" across all user schemas...';

    -- Loop through all schemas in the current database that are not system schemas
    -- (like 'pg_catalog' or 'information_schema')
    FOR schema_name IN
        SELECT s.nspname
        FROM pg_catalog.pg_namespace s
        WHERE s.nspname NOT IN ('pg_toast', 'pg_catalog', 'information_schema','google_vacuum_mgmt','anon')
          AND s.nspname NOT LIKE 'pg_toast_temp_%'
          AND s.nspname NOT LIKE 'pg_temp_%'
    LOOP
        -- Log which schema we are currently processing
        RAISE NOTICE 'Processing schema: %', quote_ident(schema_name);

        -- 1. Grant USAGE on the schema itself, with GRANT OPTION
        EXECUTE format('GRANT USAGE ON SCHEMA %I TO permission_granter WITH GRANT OPTION;', schema_name);

        -- 2. Grant SELECT on all existing tables in this schema, with GRANT OPTION
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO permission_granter WITH GRANT OPTION;', schema_name);

        -- 3. Grant SELECT on all FUTURE tables created in this schema, with GRANT OPTION
        -- The ALTER DEFAULT PRIVILEGES command needs to be formatted carefully
        EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT ON TABLES TO permission_granter WITH GRANT OPTION;', schema_name);

        RAISE NOTICE ' -> Granted USAGE and SELECT on existing and future tables in schema %.', quote_ident(schema_name);

    END LOOP;

    RAISE NOTICE '--- All schemas processed successfully! ---';
END $$;
