-- PostgreSQL Role and Privileges Backup Script
DO
$$
DECLARE
    target_role TEXT := 'ats-4681-np-sa@cb0104074a-citnonprod-gc.iam';
    r RECORD;
    m RECORD;
    obj RECORD;
    seq RECORD;
    sch RECORD;
    func RECORD;
    db RECORD;
BEGIN
    --------------------------------------------------------------------
    -- Step 1: Backup Role Attributes
    --------------------------------------------------------------------
    FOR r IN 
        SELECT * FROM pg_roles WHERE rolname = target_role
    LOOP
        RAISE NOTICE 'CREATE ROLE "%";', r.rolname;
        RAISE NOTICE 'CREATE ROLE "%" % % % % % %;', 
            r.rolname,
            CASE WHEN r.rolsuper THEN 'SUPERUSER' ELSE 'NOSUPERUSER' END,
            CASE WHEN r.rolcreatedb THEN 'CREATEDB' ELSE '' END,
            CASE WHEN r.rolcreaterole THEN 'CREATEROLE' ELSE '' END,
            CASE WHEN r.rolcanlogin THEN 'LOGIN' ELSE '' END,
            CASE WHEN r.rolreplication THEN 'REPLICATION' ELSE '' END,
            CASE WHEN r.rolbypassrls THEN 'BYPASSRLS' ELSE '' END;
    END LOOP;

    --------------------------------------------------------------------
    -- Step 2: Backup Role Memberships
    --------------------------------------------------------------------
    FOR m IN
        SELECT pr.rolname AS granted_role
        FROM pg_auth_members am
        JOIN pg_roles pr ON am.roleid = pr.oid
        JOIN pg_roles pr2 ON am.member = pr2.oid
        WHERE pr2.rolname = target_role
    LOOP
        RAISE NOTICE 'GRANT "%" TO "%";', m.granted_role, target_role;
    END LOOP;

    --------------------------------------------------------------------
    -- Step 3a: Backup Table Privileges (ignore system/toast/temp schemas)
    --------------------------------------------------------------------
    FOR obj IN
        SELECT table_schema, table_name, privilege_type
        FROM information_schema.role_table_grants
        WHERE grantee = target_role
          AND table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
          AND table_schema NOT LIKE 'pg_temp%'
    LOOP
        RAISE NOTICE 'GRANT % ON TABLE "%"."%" TO "%";', 
            obj.privilege_type, obj.table_schema, obj.table_name, target_role;
    END LOOP;

    --------------------------------------------------------------------
    -- Step 3b: Backup Sequence Privileges (ignore system/toast/temp schemas)
    --------------------------------------------------------------------
    FOR seq IN
        SELECT ns.nspname AS schema_name,
               c.relname AS sequence_name
        FROM pg_class c
        JOIN pg_namespace ns ON ns.oid = c.relnamespace
        WHERE c.relkind = 'S'
          AND ns.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
          AND ns.nspname NOT LIKE 'pg_temp%'
    LOOP
        IF has_sequence_privilege(target_role, seq.schema_name || '.' || seq.sequence_name, 'USAGE') THEN
            RAISE NOTICE 'GRANT USAGE ON SEQUENCE "%"."%" TO "%";', seq.schema_name, seq.sequence_name, target_role;
        END IF;
        IF has_sequence_privilege(target_role, seq.schema_name || '.' || seq.sequence_name, 'SELECT') THEN
            RAISE NOTICE 'GRANT SELECT ON SEQUENCE "%"."%" TO "%";', seq.schema_name, seq.sequence_name, target_role;
        END IF;
        IF has_sequence_privilege(target_role, seq.schema_name || '.' || seq.sequence_name, 'UPDATE') THEN
            RAISE NOTICE 'GRANT UPDATE ON SEQUENCE "%"."%" TO "%";', seq.schema_name, seq.sequence_name, target_role;
        END IF;
    END LOOP;

    --------------------------------------------------------------------
    -- Step 4: Backup Schema Privileges (ignore system/toast/temp schemas)
    --------------------------------------------------------------------
    FOR sch IN
        SELECT n.nspname AS schema_name
        FROM pg_namespace n
        WHERE (has_schema_privilege(target_role, n.oid, 'USAGE')
           OR has_schema_privilege(target_role, n.oid, 'CREATE'))
          AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
          AND n.nspname NOT LIKE 'pg_temp%'
    LOOP
        IF has_schema_privilege(target_role, sch.schema_name, 'USAGE') THEN
            RAISE NOTICE 'GRANT USAGE ON SCHEMA "%" TO "%";', sch.schema_name, target_role;
        END IF;
        IF has_schema_privilege(target_role, sch.schema_name, 'CREATE') THEN
            RAISE NOTICE 'GRANT CREATE ON SCHEMA "%" TO "%";', sch.schema_name, target_role;
        END IF;
    END LOOP;

    --------------------------------------------------------------------
    -- Step 5: Backup Function Privileges (ignore system/toast/temp schemas)
    --------------------------------------------------------------------
    FOR func IN
        SELECT ns.nspname AS schema_name,
               proc.proname AS function_name,
               pg_get_function_identity_arguments(proc.oid) AS args
        FROM pg_proc proc
        JOIN pg_namespace ns ON proc.pronamespace = ns.oid
        JOIN information_schema.role_routine_grants g
          ON g.routine_schema = ns.nspname
         AND g.routine_name = proc.proname
        WHERE g.grantee = target_role
          AND ns.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
          AND ns.nspname NOT LIKE 'pg_temp%'
    LOOP
        RAISE NOTICE 'GRANT EXECUTE ON FUNCTION "%"."%"(%) TO "%";', 
            func.schema_name, func.function_name, func.args, target_role;
    END LOOP;

    --------------------------------------------------------------------
    -- Step 6: Backup Database-Level Privileges
    --------------------------------------------------------------------
    FOR db IN
        SELECT datname
        FROM pg_database
        WHERE has_database_privilege(target_role, datname, 'CONNECT')
           OR has_database_privilege(target_role, datname, 'TEMP')
    LOOP
        IF has_database_privilege(target_role, db.datname, 'CONNECT') THEN
            RAISE NOTICE 'GRANT CONNECT ON DATABASE "%" TO "%";', db.datname, target_role;
        END IF;
        IF has_database_privilege(target_role, db.datname, 'TEMP') THEN
            RAISE NOTICE 'GRANT TEMP ON DATABASE "%" TO "%";', db.datname, target_role;
        END IF;
    END LOOP;

    --------------------------------------------------------------------
    -- Step 7: Backup Other Object-Level Privileges (ignore system/toast/temp schemas)
    --------------------------------------------------------------------
    -- Views and Materialized Views
    FOR obj IN
        SELECT g.table_schema, g.table_name, g.privilege_type
        FROM information_schema.role_table_grants g
        JOIN information_schema.tables t
          ON g.table_schema = t.table_schema
         AND g.table_name = t.table_name
        WHERE g.grantee = target_role
          AND t.table_type IN ('VIEW', 'MATERIALIZED VIEW')
          AND g.table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
          AND g.table_schema NOT LIKE 'pg_temp%'
    LOOP
        RAISE NOTICE 'GRANT % ON "%"."%" TO "%";', obj.privilege_type, obj.table_schema, obj.table_name, target_role;
    END LOOP;

    -- Types
    FOR obj IN
        SELECT ns.nspname AS schema_name, typ.typname AS type_name
        FROM pg_type typ
        JOIN pg_namespace ns ON typ.typnamespace = ns.oid
        WHERE has_type_privilege(target_role, typ.oid, 'USAGE')
          AND ns.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
          AND ns.nspname NOT LIKE 'pg_temp%'
    LOOP
        RAISE NOTICE 'GRANT USAGE ON TYPE "%"."%" TO "%";', obj.schema_name, obj.type_name, target_role;
    END LOOP;

    -- Domains
    FOR obj IN
        SELECT ns.nspname AS schema_name, typ.typname AS domain_name
        FROM pg_type typ
        JOIN pg_namespace ns ON typ.typnamespace = ns.oid
        WHERE typ.typtype = 'd'
          AND has_type_privilege(target_role, typ.oid, 'USAGE')
          AND ns.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
          AND ns.nspname NOT LIKE 'pg_temp%'
    LOOP
        RAISE NOTICE 'GRANT USAGE ON DOMAIN "%"."%" TO "%";', obj.schema_name, obj.domain_name, target_role;
    END LOOP;

    -- Foreign Tables (fixed column names)
    FOR obj IN
        SELECT foreign_table_schema, foreign_table_name
        FROM information_schema.foreign_tables
        WHERE has_table_privilege(
                  target_role,
                  quote_ident(foreign_table_schema) || '.' || quote_ident(foreign_table_name),
                  'SELECT'
              )
          AND foreign_table_schema NOT IN ('pg_catalog','information_schema','pg_toast')
          AND foreign_table_schema NOT LIKE 'pg_temp%'
    LOOP
        RAISE NOTICE 'GRANT SELECT ON FOREIGN TABLE "%"."%" TO "%";',
            obj.foreign_table_schema, obj.foreign_table_name, target_role;
    END LOOP;
END
$$;