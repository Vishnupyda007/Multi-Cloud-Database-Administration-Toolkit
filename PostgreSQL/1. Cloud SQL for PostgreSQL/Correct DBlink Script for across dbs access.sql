DO $$
DECLARE
    /*******************************************************
     * === SET YOUR CONNECTION DETAILS HERE ===
     *******************************************************/
    db_host        TEXT := '10.75.154.10';
    db_port        INT  := 5432;
    admin_user     TEXT := 'postgres';               -- admin or cloudsqlsuperuser
    admin_password TEXT := 'Gcpcloudadmin@2025';     -- ⚠ avoid plaintext in prod
    maint_user     TEXT := 'DBMaintenanceUser';      -- your maintenance role
    dbadmin_schema TEXT := 'DBAdmin';                -- schema hosting pgstattuple
    include_dbs    TEXT[] := NULL;                   -- e.g., ARRAY['db1','db2'] or NULL for all
    exclude_dbs    TEXT[] := ARRAY['postgres','template0','cloudsqladmin'];
    /*******************************************************/

    db_name     TEXT;
    conn_string TEXT;
    sql_remote  TEXT;
BEGIN
    -- Ensure dblink is available in the current (meta) DB
    BEGIN
        CREATE EXTENSION IF NOT EXISTS dblink;
        RAISE NOTICE 'dblink extension is available.';
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Could not create dblink extension. Please ensure you have superuser privileges. ERROR: %', SQLERRM;
    END;

    -- Optional: PG14+ grant pg_maintain once, so reindex is allowed without object ownership
    PERFORM 1 FROM pg_roles WHERE rolname = 'pg_maintain';
    IF FOUND THEN
        EXECUTE format('GRANT pg_maintain TO %I', maint_user);
        RAISE NOTICE 'Granted pg_maintain to %.', maint_user;
    ELSE
        RAISE NOTICE 'Role pg_maintain not present; skipping.';
    END IF;

    RAISE NOTICE 'Starting to process databases on host %...', db_host;

    -- Loop through all user-created databases (respect include/exclude)
    FOR db_name IN
        SELECT datname
        FROM pg_database
        WHERE datallowconn
          AND NOT datistemplate
          AND (include_dbs IS NULL OR datname = ANY(include_dbs))
          AND (exclude_dbs IS NULL OR NOT (datname = ANY(exclude_dbs)))
        ORDER BY datname
    LOOP
        RAISE NOTICE '-------------------------------------------------';
        RAISE NOTICE 'Processing Database: %', db_name;

        -- Local grant: CONNECT on the database to maintenance user
        BEGIN
            EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', db_name, maint_user);
            RAISE NOTICE '  -> Granted CONNECT on database "%".', db_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING '  -> FAILED to grant CONNECT on "%". ERROR: %', db_name, SQLERRM;
        END;

        -- Build the remote connection string for this DB
        conn_string := format(
            'host=%s port=%s user=%s password=%s dbname=%s sslmode=require',
            db_host, db_port, admin_user, admin_password, db_name
        );

        -- Compose remote SQL (idempotent):
        --  1) CREATE SCHEMA DBAdmin
        --  2) CREATE EXTENSION pgstattuple IN DBAdmin
        --  3) GRANT USAGE ON SCHEMA DBAdmin TO maint_user
        --  4) TRY to GRANT EXECUTE on DBAdmin.pgstattuple(regclass); ignore if undefined
        sql_remote := format($remote$
            CREATE SCHEMA IF NOT EXISTS %1$I;
            CREATE EXTENSION IF NOT EXISTS pgstattuple WITH SCHEMA %1$I;

            GRANT USAGE ON SCHEMA %1$I TO %2$I;

            DO $x$
            BEGIN
              BEGIN
                EXECUTE 'GRANT EXECUTE ON FUNCTION %1$I.pgstattuple(regclass) TO %2$I; GRANT EXECUTE ON FUNCTION %1$I.pgstatindex(text) to %2$I; grant usage on schema "DBAdmin" to "DBMaintenanceUser"; --grant select,delete on table "DBAdmin".ddl_event_log to "DBMaintenanceUser"';
              EXCEPTION WHEN undefined_function THEN
                -- function not present (older server or extension install failed) -> ignore
                NULL;
              END;
            END
            $x$;
        $remote$, dbadmin_schema, maint_user);

        -- Execute on the remote database
        BEGIN
            PERFORM dblink_exec(conn_string, sql_remote);
            RAISE NOTICE '  -> SUCCESS in "%": schema/extension/grants configured.', db_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING '  -> FAILED in "%". ERROR: %', db_name, SQLERRM;
        END;

    END LOOP;

    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Script finished.';
END;
$$;




