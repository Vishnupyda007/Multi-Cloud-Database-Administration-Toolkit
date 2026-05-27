
--grant the postgres role to the schema owner role 
grant "OneC_4671" to postgres;
-- Transfer ownership of schemas owned by OneC_4671 to postgres
DO $$
DECLARE
    rname text := 'OneC_4671';
    target_owner text := 'postgres';
    schemaname text;
BEGIN
    FOR schemaname IN
        SELECT n.nspname
        FROM pg_namespace n
        JOIN pg_roles r ON r.oid = n.nspowner
        WHERE r.rolname = rname
          AND n.nspname NOT IN ('pg_catalog','information_schema','pg_tSSoast')
          AND n.nspname NOT LIKE 'pg_temp_%'
          AND n.nspname NOT LIKE 'pg_toast_temp_%'
    LOOP
        RAISE NOTICE 'Altering owner of schema % to %', schemaname, target_owner;
        EXECUTE format('ALTER SCHEMA %I OWNER TO %I', schemaname, target_owner);
    END LOOP;
END
$$;

-- === Grants on existing objects & schemas ===
DO $$
DECLARE
    rname text := 'OneC_4671';
    schemaname text;
BEGIN
    FOR schemaname IN
        SELECT n.nspname
        FROM pg_namespace n
        WHERE n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
          AND n.nspname NOT LIKE 'pg_temp_%'
          AND n.nspname NOT LIKE 'pg_toast_temp_%'
    LOOP
        -- On the schema itself (to allow object creation/usage):
        EXECUTE format('GRANT USAGE, CREATE ON SCHEMA %I TO %I', schemaname, rname);

        -- On all tables/views:
        EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO %I', schemaname, rname);

        -- On all sequences (needed for INSERT with serial/identity and manual sequence ops):
        -- USAGE: nextval; SELECT: read current value; UPDATE: setval
        EXECUTE format('GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA %I TO %I', schemaname, rname);

        -- On all functions (and procedures, where supported) for execution:
        EXECUTE format('GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA %I TO %I', schemaname, rname);
        -- If your PG version supports PROCEDURES (PG 11+):
        --EXECUTE format('GRANT usage ON types IN SCHEMA %I TO %I', schemaname, rname);
    END LOOP;
END
$$;

-- === Default privileges for FUTURE objects created by postgres in these schemas ===
-- Apply for objects created by 'postgres' (the new owner). If other owners will create
-- objects, repeat for those owners by setting "FOR ROLE that_owner".
DO $$
DECLARE
    rname text := 'OneC_4671';
    owner_role text := 'postgres';
    schemaname text;
BEGIN
    FOR schemaname IN
        SELECT n.nspname
        FROM pg_namespace n
        WHERE n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
          AND n.nspname NOT LIKE 'pg_temp_%'
          AND n.nspname NOT LIKE 'pg_toast_temp_%'
    LOOP
        -- Ensure default privileges are set by the OWNER role (postgres) in each schema.
        -- Note: ALTER DEFAULT PRIVILEGES affects future objects created by that owner.
        EXECUTE format($fmt$
            ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
            GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I
        $fmt$, owner_role, schemaname, rname);

        EXECUTE format($fmt$
            ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
            GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO %I
        $fmt$, owner_role, schemaname, rname);

        EXECUTE format($fmt$
            ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
            GRANT EXECUTE ON FUNCTIONS TO %I
        $fmt$, owner_role, schemaname, rname);

        -- For PROCEDURES (PG 11+)
        EXECUTE format($fmt$
            ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I
            GRANT usage ON types TO %I
        $fmt$, owner_role, schemaname, rname);
    END LOOP;
END
$$;

-- OPTIONAL: If you also want USAGE on TYPES in these schemas (common with custom types/domains):
-- ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA your_schema GRANT USAGE ON TYPES TO OneC_4671;
