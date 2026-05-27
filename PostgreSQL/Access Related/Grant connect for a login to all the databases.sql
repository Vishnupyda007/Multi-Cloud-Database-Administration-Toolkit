-- This script grants the CONNECT privilege to a specified role for all user databases.
-- It dynamically queries pg_database and excludes system/template databases.

DO $$
DECLARE
    -- Variable to hold the name of each database during the loop.
    db_name text;
    -- The user or role you want to grant connect access to.
    -- IMPORTANT: Replace 'your_user_role' with the actual role name.
    target_role text := 'your_user_role'; 
BEGIN
    RAISE NOTICE 'Starting to grant CONNECT on all user databases to role: %', target_role;

    -- Loop through all databases that are not templates and allow connections.
    FOR db_name IN 
        SELECT datname 
        FROM pg_database 
        WHERE datistemplate = false 
          AND datname NOT IN ('postgres') -- Explicitly exclude the 'postgres' admin database
    LOOP
        -- Build the GRANT statement dynamically using format()
        -- %I is used for identifiers (like database and role names) to protect against SQL injection.
        EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I;', db_name, target_role);
        
        -- Print a notice to the console to show progress.
        RAISE NOTICE 'Granted CONNECT on database: "%" to role: "%"', db_name, target_role;
    END LOOP;

    RAISE NOTICE 'Script finished. CONNECT has been granted on all user databases.';
END $$;

