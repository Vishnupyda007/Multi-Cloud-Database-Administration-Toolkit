/*
====================================================================================
-- Master Revocation Script for All Users in a Single Database
--
-- This script finds all roles in the current database (except for 'postgres')
-- and revokes their privileges on specific "DBAdmin" objects and on the
-- schema itself. It also revokes privileges from the PUBLIC role.
--
-- This is a plain SQL script, designed to be run directly in the pgAdmin
-- Query Tool for each database you wish to clean up.
====================================================================================
*/
DO $$
DECLARE
    -- A variable to hold the current role name during the loop
    rol TEXT;
BEGIN
    RAISE NOTICE '--- Starting master revocation in database: % ---', current_database();
    RAISE NOTICE 'Looping through all roles to revoke privileges...';

    -- Loop through every role in the current database, except for the 'postgres' superuser.
    FOR rol IN
        SELECT rolname FROM pg_catalog.pg_roles WHERE rolname <> 'postgres'
    LOOP
        -- Use an inner block to catch errors (e.g., object doesn't exist)
        -- and prevent the entire script from stopping.
        BEGIN
            RAISE NOTICE 'Processing role: %', rol;

            -- Dynamically execute REVOKE statements for the current role.
            -- The %I specifier safely quotes identifiers, which is crucial for role names.
            EXECUTE format('REVOKE ALL ON TABLE "DBAdmin".ddl_event_log FROM %I', rol);
            EXECUTE format('REVOKE ALL ON FUNCTION "DBAdmin"._is_excluded_schema(text) FROM %I', rol);
            EXECUTE format('REVOKE ALL ON FUNCTION "DBAdmin"._set_adp_for_postgres(text) FROM %I', rol);
            EXECUTE format('REVOKE ALL ON FUNCTION "DBAdmin"._ddl_transfer_owner_and_grant() FROM %I', rol);
            EXECUTE format('REVOKE ALL ON SCHEMA "DBAdmin" FROM %I', rol);

        EXCEPTION
            -- This handles cases where "DBAdmin" or its objects don't exist in this DB,
            -- or the role had no privileges to begin with. The script will continue.
            WHEN undefined_object OR invalid_grant_operation THEN
                 RAISE NOTICE '--> Some "DBAdmin" objects do not exist or role has no privileges; skipping for role %.', rol;
            WHEN OTHERS THEN
                RAISE WARNING 'An unexpected error occurred for role %: %', rol, SQLERRM;
        END;
    END LOOP;

    -- Finally, perform a blanket revoke from the PUBLIC pseudo-role. This is critical
    -- for removing any default permissions that might have been granted to all users.
    RAISE NOTICE '-------------------------------------------------------';
    RAISE NOTICE 'Revoking all privileges from the PUBLIC role...';
    BEGIN
        REVOKE ALL ON SCHEMA "DBAdmin" FROM PUBLIC;
        REVOKE ALL ON TABLE "DBAdmin".ddl_event_log FROM PUBLIC;
        REVOKE ALL ON FUNCTION "DBAdmin"._is_excluded_schema(text) FROM PUBLIC;
        REVOKE ALL ON FUNCTION "DBAdmin"._set_adp_for_postgres(text) FROM PUBLIC;
        REVOKE ALL ON FUNCTION "DBAdmin"._ddl_transfer_owner_and_grant() FROM PUBLIC;
    EXCEPTION
        WHEN undefined_object THEN
            RAISE NOTICE '--> "DBAdmin" schema or objects do not exist; nothing to revoke from PUBLIC.';
    END;

    RAISE NOTICE '--- Finished master revocation in database: % ---', current_database();
END;
$$;
