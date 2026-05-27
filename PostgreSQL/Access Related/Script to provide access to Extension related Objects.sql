DO $$
DECLARE
    target_role  TEXT := 'deploytool';
    obj          RECORD;
BEGIN

    -- ----------------------------------------------------------------
    -- 1. FUNCTIONS owned / provided by installed extensions
    -- ----------------------------------------------------------------
    FOR obj IN
        SELECT
            n.nspname                                          AS schema_name,
            p.proname                                         AS obj_name,
            p.prokind,
            pg_get_function_identity_arguments(p.oid)        AS identity_args,
            string_agg(format_type(t.arg_oid, NULL), ', '
                       ORDER BY t.arg_num)                   AS simple_sig
        FROM pg_proc p
        JOIN pg_namespace   n  ON p.pronamespace = n.oid
        JOIN pg_depend      d  ON d.objid = p.oid
                               AND d.deptype = 'e'          -- extension-owned object
        JOIN pg_extension   e  ON e.oid = d.refobjid 
        LEFT JOIN LATERAL
            unnest(p.proargtypes) WITH ORDINALITY AS t(arg_oid, arg_num) ON true where e.extname = 'dblink'
        GROUP BY p.oid, n.nspname, p.proname, p.prokind
    LOOP
        IF obj.prokind = 'f' THEN
            RAISE NOTICE 'GRANT EXECUTE ON FUNCTION %.%(%)',
                obj.schema_name, obj.obj_name, obj.identity_args;
            EXECUTE format(
                'GRANT EXECUTE ON FUNCTION %I.%I(%s) TO %I',
                obj.schema_name, obj.obj_name,
                COALESCE(obj.simple_sig, ''), target_role
            );
        ELSIF obj.prokind = 'p' THEN
            RAISE NOTICE 'GRANT EXECUTE ON PROCEDURE %.%(%)',
                obj.schema_name, obj.obj_name, obj.identity_args;
            EXECUTE format(
                'GRANT EXECUTE ON PROCEDURE %I.%I(%s) TO %I',
                obj.schema_name, obj.obj_name,
                COALESCE(obj.simple_sig, ''), target_role
            );
        END IF;
    END LOOP;

    -- ----------------------------------------------------------------
    -- 2. TABLES / VIEWS provided by installed extensions
    --    (e.g. pg_stat_statements view, postgis geometry_columns, etc.)
    -- ----------------------------------------------------------------
    FOR obj IN
        SELECT
            n.nspname  AS schema_name,
            c.relname  AS obj_name,
            c.relkind
        FROM pg_class     c
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_depend    d ON d.objid = c.oid
                            AND d.deptype = 'e'
        JOIN pg_extension e ON e.oid = d.refobjid
        WHERE c.relkind IN ('r', 'v', 'm', 'f')  -- table, view, matview, foreign table
    LOOP
        RAISE NOTICE 'GRANT SELECT ON %.%', obj.schema_name, obj.obj_name;
        EXECUTE format(
            'GRANT SELECT ON %I.%I TO %I',
            obj.schema_name, obj.obj_name, target_role
        );
    END LOOP;

    -- ----------------------------------------------------------------
    -- 3. SEQUENCES provided by installed extensions
    -- ----------------------------------------------------------------
    FOR obj IN
        SELECT
            n.nspname AS schema_name,
            c.relname AS obj_name
        FROM pg_class     c
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_depend    d ON d.objid = c.oid
                            AND d.deptype = 'e'
        JOIN pg_extension e ON e.oid = d.refobjid
        WHERE c.relkind = 'S'   -- sequence
    LOOP
        RAISE NOTICE 'GRANT USAGE, SELECT ON SEQUENCE %.%',
            obj.schema_name, obj.obj_name;
        EXECUTE format(
            'GRANT USAGE, SELECT ON SEQUENCE %I.%I TO %I',
            obj.schema_name, obj.obj_name, target_role
        );
    END LOOP;

    -- ----------------------------------------------------------------
    -- 4. TYPES provided by installed extensions
    --    (e.g. postgis geometry, hstore, citext, etc.)
    -- ----------------------------------------------------------------
    FOR obj IN
        SELECT
            n.nspname AS schema_name,
            t.typname AS obj_name
        FROM pg_type      t
        JOIN pg_namespace n ON t.typnamespace = n.oid
        JOIN pg_depend    d ON d.objid = t.oid
                            AND d.deptype = 'e'
        JOIN pg_extension e ON e.oid = d.refobjid
        WHERE t.typtype IN ('b', 'c', 'e', 'r')  -- base, composite, enum, range
          AND t.typname NOT LIKE '\_%'            -- skip array shadow types
    LOOP
        RAISE NOTICE 'GRANT USAGE ON TYPE %.%',
            obj.schema_name, obj.obj_name;
        EXECUTE format(
            'GRANT USAGE ON TYPE %I.%I TO %I',
            obj.schema_name, obj.obj_name, target_role
        );
    END LOOP;

    -- ----------------------------------------------------------------
    -- 5. SCHEMA-level USAGE for every schema that hosts extension objects
    -- ----------------------------------------------------------------
    FOR obj IN
        SELECT DISTINCT n.nspname AS schema_name
        FROM pg_depend    d
        JOIN pg_extension e  ON e.oid = d.refobjid AND d.deptype = 'e'
        JOIN pg_class     c  ON c.oid = d.objid
        JOIN pg_namespace n  ON n.oid = c.relnamespace
        UNION
        SELECT DISTINCT n.nspname
        FROM pg_depend    d
        JOIN pg_extension e  ON e.oid = d.refobjid AND d.deptype = 'e'
        JOIN pg_proc      p  ON p.oid = d.objid
        JOIN pg_namespace n  ON n.oid = p.pronamespace
    LOOP
        RAISE NOTICE 'GRANT USAGE ON SCHEMA %', obj.schema_name;
        EXECUTE format(
            'GRANT USAGE ON SCHEMA %I TO %I',
            obj.schema_name, target_role
        );
    END LOOP;

    RAISE NOTICE 'Done — all extension object privileges granted to %', target_role;
END $$;