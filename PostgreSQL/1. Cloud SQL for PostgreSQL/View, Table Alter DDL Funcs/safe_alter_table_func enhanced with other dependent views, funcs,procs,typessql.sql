-- ============================================================
-- safe_alter_table
--
-- Handles all dependent objects before ALTER TABLE:
--   - Views (regular)
--   - Materialized Views
--   - Functions & Procedures
--   - Composite / Table Types
--
-- Parameters:
--   table_name_in  : Table name — plain 'table' or 'schema.table'
--   alter_sql_in   : One or more ALTER TABLE statements
--                    (semicolon-separated if multiple)
--   dry_run_in     : If TRUE, only logs what would happen — no changes made

-- Dry run first to see all dependent objects that will be affected
SELECT safe_alter_table(
    'hr.employees',
    'ALTER TABLE hr.employees DROP COLUMN old_code',
    dry_run_in => TRUE
);

-- Execute for real
SELECT safe_alter_table(
    'hr.employees',
    'ALTER TABLE hr.employees DROP COLUMN old_code'
);

-- Multiple ALTERs with schema-qualified table
SELECT safe_alter_table(
    'hr.employees',
    'ALTER TABLE hr.employees ADD COLUMN middle_name TEXT;
     ALTER TABLE hr.employees ALTER COLUMN salary TYPE NUMERIC(15,2)'
);
-- ============================================================

CREATE OR REPLACE FUNCTION "DBAdmin".safe_alter_table_func(
    table_name_in  TEXT,
    alter_sql_in   TEXT,
    dry_run_in     BOOLEAN DEFAULT FALSE
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    input_schema       TEXT;
    input_table        TEXT;
    full_table_name    TEXT;
    full_obj_name      TEXT;
    view_rec           RECORD;
    grant_record       RECORD;
    func_rec           RECORD;
    type_rec           RECORD;
    grant_statement    TEXT;
    alter_stmt         TEXT;
    view_count         INT;
    table_schema_oid   OID;
    iter               INT := 0;
    max_iter           INT := 50;
BEGIN
    -- --------------------------------------------------------
    -- Parse schema.table or plain table input
    -- --------------------------------------------------------
    IF position('.' IN table_name_in) > 0 THEN
        input_schema := split_part(table_name_in, '.', 1);
        input_table  := split_part(table_name_in, '.', 2);
    ELSE
        input_schema := current_schema();
        input_table  := table_name_in;
    END IF;

    SELECT oid INTO table_schema_oid
    FROM pg_namespace
    WHERE nspname = input_schema;

    IF table_schema_oid IS NULL THEN
        RAISE EXCEPTION 'Schema "%" does not exist.', input_schema;
    END IF;

    full_table_name := quote_ident(input_schema) || '.' || quote_ident(input_table);

    IF dry_run_in THEN
        RAISE NOTICE '== [DRY RUN] safe_alter_table for table: % ==', full_table_name;
    ELSE
        RAISE NOTICE '== Starting safe_alter_table for table: % ==', full_table_name;
    END IF;

    -- --------------------------------------------------------
    -- STEP 1: Temp tables
    -- --------------------------------------------------------

    -- Regular views + materialized views
    CREATE TEMPORARY TABLE temp_view_ddl (
        view_name    TEXT,
        view_schema  TEXT,
        view_def     TEXT,
        view_owner   TEXT,
        view_comment TEXT,
        view_kind    TEXT,   -- 'v' = view, 'm' = materialized view
        topo_level   INT DEFAULT 0
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_view_deps (
        parent_view TEXT,
        child_view  TEXT
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_view_grants (
        view_name  TEXT,
        grant_stmt TEXT
    ) ON COMMIT DROP;

    -- Functions & Procedures
    CREATE TEMPORARY TABLE temp_func_ddl (
        func_oid    OID,
        func_name   TEXT,
        func_schema TEXT,
        func_kind   TEXT,   -- 'f' = function, 'p' = procedure
        func_owner  TEXT,
        func_def    TEXT,   -- full CREATE OR REPLACE definition
        func_args   TEXT    -- argument signature for drop
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_func_grants (
        func_name  TEXT,
        grant_stmt TEXT
    ) ON COMMIT DROP;

    -- Composite / Table types
    CREATE TEMPORARY TABLE temp_type_ddl (
        type_oid    OID,
        type_name   TEXT,
        type_schema TEXT,
        type_owner  TEXT,
        type_def    TEXT    -- reconstructed CREATE TYPE ... AS (...)
    ) ON COMMIT DROP;

    -- --------------------------------------------------------
    -- STEP 2: Discover dependent VIEWS & MATERIALIZED VIEWS
    -- --------------------------------------------------------
    INSERT INTO temp_view_ddl (view_name, view_schema, view_def, view_owner, view_comment, view_kind, topo_level)
    SELECT DISTINCT ON (v.oid)
        v.relname,
        n.nspname,
        pg_get_viewdef(v.oid, true),
        pg_get_userbyid(v.relowner),
        obj_description(v.oid, 'pg_class'),
        v.relkind::TEXT,
        0
    FROM pg_depend d
    JOIN pg_rewrite   r ON r.oid      = d.objid
    JOIN pg_class     v ON v.oid      = r.ev_class
    JOIN pg_class     t ON t.oid      = d.refobjid
    JOIN pg_namespace n ON n.oid      = v.relnamespace
    WHERE t.relname      = input_table
      AND t.relnamespace = table_schema_oid
      AND v.relkind      IN ('v', 'm')   -- views and materialized views
      AND v.oid         != t.oid;

    -- BFS walk for transitive view dependencies
    LOOP
        iter := iter + 1;
        IF iter > max_iter THEN
            RAISE EXCEPTION 'Circular dependency detected or depth exceeds % levels.', max_iter;
        END IF;

        INSERT INTO temp_view_ddl (view_name, view_schema, view_def, view_owner, view_comment, view_kind, topo_level)
        SELECT DISTINCT ON (v.oid)
            v.relname,
            n.nspname,
            pg_get_viewdef(v.oid, true),
            pg_get_userbyid(v.relowner),
            obj_description(v.oid, 'pg_class'),
            v.relkind::TEXT,
            (SELECT topo_level FROM temp_view_ddl
             WHERE view_name = p.view_name AND view_schema = p.view_schema) + 1
        FROM temp_view_ddl p
        JOIN pg_class     pv ON pv.relname      = p.view_name
                             AND pv.relnamespace = (
                                    SELECT oid FROM pg_namespace WHERE nspname = p.view_schema
                                 )
                             AND pv.relkind      IN ('v', 'm')
        JOIN pg_depend    d  ON d.refobjid       = pv.oid
        JOIN pg_rewrite   r  ON r.oid            = d.objid
        JOIN pg_class     v  ON v.oid            = r.ev_class
        JOIN pg_namespace n  ON n.oid            = v.relnamespace
        WHERE v.relkind IN ('v', 'm')
          AND v.oid    != pv.oid
          AND NOT EXISTS (
              SELECT 1 FROM temp_view_ddl ex
              WHERE ex.view_name = v.relname AND ex.view_schema = n.nspname
          );

        EXIT WHEN NOT FOUND;
    END LOOP;

    -- Dependency edges
    INSERT INTO temp_view_deps (parent_view, child_view)
    SELECT DISTINCT pv.relname, cv.relname
    FROM temp_view_ddl p
    JOIN pg_class     pv ON pv.relname      = p.view_name
                         AND pv.relnamespace = (
                                SELECT oid FROM pg_namespace WHERE nspname = p.view_schema
                             )
                         AND pv.relkind     IN ('v', 'm')
    JOIN pg_depend    d  ON d.refobjid      = pv.oid
    JOIN pg_rewrite   r  ON r.oid           = d.objid
    JOIN pg_class     cv ON cv.oid          = r.ev_class
    JOIN pg_namespace n  ON n.oid           = cv.relnamespace
    WHERE cv.relkind IN ('v', 'm')
      AND cv.oid    != pv.oid
      AND cv.relname IN (SELECT view_name FROM temp_view_ddl);

    SELECT COUNT(*) INTO view_count FROM temp_view_ddl;
    IF view_count = 0 THEN
        RAISE NOTICE 'No dependent views/materialized views found.';
    ELSE
        RAISE NOTICE 'Found % dependent view(s)/materialized view(s):', view_count;
        FOR view_rec IN
            SELECT view_name, view_schema, view_owner, view_kind, topo_level
            FROM temp_view_ddl ORDER BY topo_level, view_name
        LOOP
            RAISE NOTICE '  [level %] [%] %.% (owner: %)',
                view_rec.topo_level,
                CASE view_rec.view_kind WHEN 'm' THEN 'MATVIEW' ELSE 'VIEW' END,
                view_rec.view_schema,
                view_rec.view_name,
                view_rec.view_owner;
        END LOOP;
        RAISE NOTICE 'Dependency edges:';
        FOR view_rec IN SELECT parent_view, child_view FROM temp_view_deps ORDER BY parent_view LOOP
            RAISE NOTICE '  % --> %', view_rec.parent_view, view_rec.child_view;
        END LOOP;
    END IF;

    -- --------------------------------------------------------
    -- STEP 3: Discover dependent FUNCTIONS & PROCEDURES
    -- --------------------------------------------------------
    INSERT INTO temp_func_ddl (func_oid, func_name, func_schema, func_kind, func_owner, func_def, func_args)
    SELECT DISTINCT ON (p.oid)
        p.oid,
        p.proname,
        n.nspname,
        p.prokind::TEXT,
        pg_get_userbyid(p.proowner),
        pg_get_functiondef(p.oid),
        pg_get_function_identity_arguments(p.oid)   -- needed for DROP signature
    FROM pg_depend d
    JOIN pg_proc      p ON p.oid  = d.objid
    JOIN pg_class     t ON t.oid  = d.refobjid
    JOIN pg_namespace n ON n.oid  = p.pronamespace
    WHERE t.relname      = input_table
      AND t.relnamespace = table_schema_oid
      AND d.deptype      = 'n'   -- normal dependency
      AND p.prokind      IN ('f', 'p');   -- functions and procedures

    IF NOT FOUND THEN
        RAISE NOTICE 'No dependent functions/procedures found.';
    ELSE
        RAISE NOTICE 'Found dependent function(s)/procedure(s):';
        FOR func_rec IN
            SELECT func_name, func_schema, func_kind, func_owner FROM temp_func_ddl ORDER BY func_name
        LOOP
            RAISE NOTICE '  [%] %.% (owner: %)',
                CASE func_rec.func_kind WHEN 'p' THEN 'PROCEDURE' ELSE 'FUNCTION' END,
                func_rec.func_schema,
                func_rec.func_name,
                func_rec.func_owner;
        END LOOP;
    END IF;

    -- --------------------------------------------------------
    -- STEP 4: Discover dependent COMPOSITE / TABLE TYPES
    -- --------------------------------------------------------
    INSERT INTO temp_type_ddl (type_oid, type_name, type_schema, type_owner, type_def)
    SELECT DISTINCT ON (ty.oid)
        ty.oid,
        ty.typname,
        n.nspname,
        pg_get_userbyid(ty.typowner),
        -- Reconstruct CREATE TYPE ... AS (...) from pg_attribute
        'CREATE TYPE ' || quote_ident(n.nspname) || '.' || quote_ident(ty.typname) || ' AS (' ||
        string_agg(
            quote_ident(a.attname) || ' ' || pg_catalog.format_type(a.atttypid, a.atttypmod),
            ', ' ORDER BY a.attnum
        ) || ')'
    FROM pg_depend d
    JOIN pg_type      ty ON ty.oid   = d.objid
    JOIN pg_class     t  ON t.oid    = d.refobjid
    JOIN pg_namespace n  ON n.oid    = ty.typnamespace
    JOIN pg_class     tc ON tc.oid   = ty.typrelid   -- composite type's backing class
    JOIN pg_attribute a  ON a.attrelid = tc.oid AND a.attnum > 0 AND NOT a.attisdropped
    WHERE t.relname      = input_table
      AND t.relnamespace = table_schema_oid
      AND ty.typtype     = 'c'   -- composite types only
      AND d.deptype      = 'n'
    GROUP BY ty.oid, ty.typname, n.nspname, ty.typowner;

    IF NOT FOUND THEN
        RAISE NOTICE 'No dependent composite/table types found.';
    ELSE
        RAISE NOTICE 'Found dependent composite/table type(s):';
        FOR type_rec IN SELECT type_name, type_schema, type_owner FROM temp_type_ddl ORDER BY type_name LOOP
            RAISE NOTICE '  [TYPE] %.% (owner: %)',
                type_rec.type_schema, type_rec.type_name, type_rec.type_owner;
        END LOOP;
    END IF;

    -- --------------------------------------------------------
    -- STEP 5: Capture grants for all views & materialized views
    -- --------------------------------------------------------
    FOR view_rec IN SELECT view_name, view_schema FROM temp_view_ddl ORDER BY view_name
    LOOP
        full_obj_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);

        FOR grant_record IN
            WITH acl_entries AS (
                SELECT
                    ace.grantee        AS grantee_oid,
                    ace.grantor        AS grantor_oid,
                    ace.is_grantable   AS is_grantable,
                    ace.privilege_type AS privilege_type
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace,
                LATERAL aclexplode(c.relacl) AS ace
                WHERE c.relname  = view_rec.view_name
                  AND n.nspname  = view_rec.view_schema
                  AND c.relacl   IS NOT NULL
            )
            SELECT
                CASE WHEN grantee_oid = 0 THEN 'PUBLIC'
                     ELSE pg_get_userbyid(grantee_oid) END AS grantee,
                is_grantable,
                string_agg(privilege_type, ', ')           AS privileges
            FROM acl_entries
            WHERE grantee_oid != 0
              AND pg_get_userbyid(grantee_oid) != current_user
            GROUP BY grantee_oid, grantor_oid, is_grantable
        LOOP
            grant_statement := format(
                'GRANT %s ON %s TO %I %s;',
                grant_record.privileges,
                full_obj_name,
                grant_record.grantee,
                CASE WHEN grant_record.is_grantable THEN 'WITH GRANT OPTION' ELSE '' END
            );
            INSERT INTO temp_view_grants (view_name, grant_stmt)
            VALUES (view_rec.view_name, grant_statement);
            RAISE NOTICE '  [%] Grant captured for "%": %',
                view_rec.view_name, grant_record.grantee, grant_statement;
        END LOOP;

        IF NOT FOUND THEN
            RAISE NOTICE '  [%] No grants found.', view_rec.view_name;
        END IF;
    END LOOP;

    -- Capture grants for functions & procedures
    FOR func_rec IN SELECT func_oid, func_name, func_schema, func_kind FROM temp_func_ddl ORDER BY func_name
    LOOP
        full_obj_name := quote_ident(func_rec.func_schema) || '.' || quote_ident(func_rec.func_name);

        FOR grant_record IN
            WITH acl_entries AS (
                SELECT
                    ace.grantee        AS grantee_oid,
                    ace.is_grantable   AS is_grantable,
                    ace.privilege_type AS privilege_type
                FROM pg_proc p,
                LATERAL aclexplode(p.proacl) AS ace
                WHERE p.oid = func_rec.func_oid
                  AND p.proacl IS NOT NULL
            )
            SELECT
                CASE WHEN grantee_oid = 0 THEN 'PUBLIC'
                     ELSE pg_get_userbyid(grantee_oid) END AS grantee,
                is_grantable,
                string_agg(privilege_type, ', ')           AS privileges
            FROM acl_entries
            WHERE grantee_oid != 0
              AND pg_get_userbyid(grantee_oid) != current_user
            GROUP BY grantee_oid, is_grantable
        LOOP
            grant_statement := format(
                'GRANT %s ON %s %s TO %I %s;',
                grant_record.privileges,
                CASE func_rec.func_kind WHEN 'p' THEN 'PROCEDURE' ELSE 'FUNCTION' END,
                full_obj_name,
                grant_record.grantee,
                CASE WHEN grant_record.is_grantable THEN 'WITH GRANT OPTION' ELSE '' END
            );
            INSERT INTO temp_func_grants (func_name, grant_stmt)
            VALUES (func_rec.func_name, grant_statement);
            RAISE NOTICE '  [%] Grant captured for "%": %',
                func_rec.func_name, grant_record.grantee, grant_statement;
        END LOOP;

        IF NOT FOUND THEN
            RAISE NOTICE '  [%] No grants found.', func_rec.func_name;
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- Dry run stops here
    -- --------------------------------------------------------
    IF dry_run_in THEN
        RAISE NOTICE '[DRY RUN] No changes made. Set dry_run_in => FALSE to execute.';
        RETURN;
    END IF;

    -- --------------------------------------------------------
    -- STEP 6: Drop views in REVERSE topo order (deepest first)
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, view_schema, view_kind
        FROM temp_view_ddl
        ORDER BY topo_level DESC, view_name
    LOOP
        full_obj_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);
        IF view_rec.view_kind = 'm' THEN
            EXECUTE format('DROP MATERIALIZED VIEW %s;', full_obj_name);
            RAISE NOTICE 'Dropped materialized view: %', full_obj_name;
        ELSE
            EXECUTE format('DROP VIEW %s;', full_obj_name);
            RAISE NOTICE 'Dropped view: %', full_obj_name;
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 7: Drop functions & procedures
    -- --------------------------------------------------------
    FOR func_rec IN SELECT func_name, func_schema, func_kind, func_args FROM temp_func_ddl ORDER BY func_name
    LOOP
        full_obj_name := quote_ident(func_rec.func_schema) || '.' || quote_ident(func_rec.func_name);
        IF func_rec.func_kind = 'p' THEN
            EXECUTE format('DROP PROCEDURE %s(%s);', full_obj_name, func_rec.func_args);
            RAISE NOTICE 'Dropped procedure: %(%)', full_obj_name, func_rec.func_args;
        ELSE
            EXECUTE format('DROP FUNCTION %s(%s);', full_obj_name, func_rec.func_args);
            RAISE NOTICE 'Dropped function: %(%)', full_obj_name, func_rec.func_args;
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 8: Drop composite / table types
    -- --------------------------------------------------------
    FOR type_rec IN SELECT type_name, type_schema FROM temp_type_ddl ORDER BY type_name
    LOOP
        full_obj_name := quote_ident(type_rec.type_schema) || '.' || quote_ident(type_rec.type_name);
        EXECUTE format('DROP TYPE %s;', full_obj_name);
        RAISE NOTICE 'Dropped type: %', full_obj_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 9: Execute ALTER TABLE statement(s)
    -- --------------------------------------------------------
    RAISE NOTICE 'Running ALTER TABLE on %...', full_table_name;
    FOREACH alter_stmt IN ARRAY string_to_array(alter_sql_in, ';')
    LOOP
        alter_stmt := trim(alter_stmt);
        CONTINUE WHEN alter_stmt = '';
        RAISE NOTICE 'Executing: %', alter_stmt;
        EXECUTE alter_stmt;
    END LOOP;
    RAISE NOTICE 'ALTER TABLE complete.';

    -- --------------------------------------------------------
    -- STEP 10: Recreate composite / table types
    -- --------------------------------------------------------
    FOR type_rec IN SELECT type_name, type_schema, type_owner, type_def FROM temp_type_ddl ORDER BY type_name
    LOOP
        full_obj_name := quote_ident(type_rec.type_schema) || '.' || quote_ident(type_rec.type_name);
        EXECUTE type_rec.type_def;
        EXECUTE format('ALTER TYPE %s OWNER TO %I;', full_obj_name, type_rec.type_owner);
        RAISE NOTICE 'Recreated type: % (owner: %)', full_obj_name, type_rec.type_owner;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 11: Recreate functions & procedures
    -- --------------------------------------------------------
    FOR func_rec IN SELECT func_name, func_schema, func_kind, func_owner, func_def FROM temp_func_ddl ORDER BY func_name
    LOOP
        full_obj_name := quote_ident(func_rec.func_schema) || '.' || quote_ident(func_rec.func_name);
        EXECUTE func_rec.func_def;
        IF func_rec.func_kind = 'p' THEN
            EXECUTE format('ALTER PROCEDURE %s OWNER TO %I;', full_obj_name, func_rec.func_owner);
            RAISE NOTICE 'Recreated procedure: % (owner: %)', full_obj_name, func_rec.func_owner;
        ELSE
            EXECUTE format('ALTER FUNCTION %s OWNER TO %I;', full_obj_name, func_rec.func_owner);
            RAISE NOTICE 'Recreated function: % (owner: %)', full_obj_name, func_rec.func_owner;
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 12: Recreate views & materialized views
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, view_schema, view_def, view_owner, view_comment, view_kind
        FROM temp_view_ddl
        ORDER BY topo_level ASC, view_name
    LOOP
        full_obj_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);

        IF view_rec.view_kind = 'm' THEN
            EXECUTE format('CREATE MATERIALIZED VIEW %s AS %s;', full_obj_name, view_rec.view_def);
            EXECUTE format('ALTER MATERIALIZED VIEW %s OWNER TO %I;', full_obj_name, view_rec.view_owner);
            RAISE NOTICE 'Recreated materialized view: % (owner: %)', full_obj_name, view_rec.view_owner;
        ELSE
            EXECUTE format('CREATE VIEW %s AS %s', full_obj_name, view_rec.view_def);
            EXECUTE format('ALTER VIEW %s OWNER TO %I;', full_obj_name, view_rec.view_owner);
            RAISE NOTICE 'Recreated view: % (owner: %)', full_obj_name, view_rec.view_owner;
        END IF;

        IF view_rec.view_comment IS NOT NULL THEN
            EXECUTE format('COMMENT ON %s %s IS %L;',
                CASE view_rec.view_kind WHEN 'm' THEN 'MATERIALIZED VIEW' ELSE 'VIEW' END,
                full_obj_name, view_rec.view_comment);
            RAISE NOTICE '  [%] Comment restored.', view_rec.view_name;
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 13: Reapply all grants
    -- --------------------------------------------------------
    FOR view_rec IN SELECT view_name, grant_stmt FROM temp_view_grants ORDER BY view_name, grant_stmt
    LOOP
        EXECUTE view_rec.grant_stmt;
        RAISE NOTICE '  [%] Reapplied grant: %', view_rec.view_name, view_rec.grant_stmt;
    END LOOP;

    FOR func_rec IN SELECT func_name, grant_stmt FROM temp_func_grants ORDER BY func_name, grant_stmt
    LOOP
        EXECUTE func_rec.grant_stmt;
        RAISE NOTICE '  [%] Reapplied grant: %', func_rec.func_name, func_rec.grant_stmt;
    END LOOP;

    RAISE NOTICE '== safe_alter_table complete for table: % ==', full_table_name;
END;
$$;