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

