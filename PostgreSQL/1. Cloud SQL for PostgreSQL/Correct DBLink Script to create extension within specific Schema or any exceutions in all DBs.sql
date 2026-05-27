DO $$
DECLARE
    /*******************************************************
     * === SET YOUR CONNECTION DETAILS HERE ===
     *******************************************************/
    db_host     TEXT := '10.75.156.3'; -- e.g., 'localhost' or '123.45.67.89'
    db_user     TEXT := 'postgres';         -- e.g., 'postgres'
    db_password TEXT := 'Gcpcloudadmin@2025';      -- <<< WARNING: INSECURE
    /*******************************************************/

    db_name     TEXT;
    command     TEXT;
    conn_string TEXT;
BEGIN
    -- Ensure the 'dblink' extension is available to make remote connections
    BEGIN
        CREATE EXTENSION IF NOT EXISTS dblink;
        RAISE NOTICE 'dblink extension is available.';
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'Could not create dblink extension. Please ensure you have superuser privileges. ERROR: %', SQLERRM;
    END;

    RAISE NOTICE 'Starting to process databases on host %...', db_host;

    -- Loop through all user-created databases
    FOR db_name IN
        SELECT datname
        FROM pg_database
        WHERE  datname NOT IN ('postgres', 'template0', 'cloudsqladmin')
    LOOP
        RAISE NOTICE '-------------------------------------------------';
        RAISE NOTICE 'Processing Database: %', db_name;

        -- Construct the full connection string, including the password.
        -- This string is what dblink uses to connect to each database.
        conn_string := format(
            'host=%s user=%s password=%s dbname=%s',
            db_host,
            db_user,
            db_password,
            db_name
        );

        -- Define the command to be executed remotely
        command := 'CREATE SCHEMA IF NOT EXISTS "DBAdmin"; CREATE EXTENSION IF NOT EXISTS pgstattuple SCHEMA "DBAdmin";';

        -- Use an exception block so an error in one DB does not halt the script
        BEGIN
            -- Execute the command on the remote database
            PERFORM dblink_exec(conn_string, command);
            RAISE NOTICE '  -> SUCCESS: pgstattuple extension has been configured in "%".', db_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING '  -> FAILED to configure extension in "%". ERROR: %', db_name, SQLERRM;
        END;

    END LOOP;

    RAISE NOTICE '-------------------------------------------------';
    RAISE NOTICE 'Script finished.';
END;
$$;
