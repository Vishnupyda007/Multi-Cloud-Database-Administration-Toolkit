-- ============================================================
-- safe_alter_table
--
-- Improvements included:
--   - Circular dependency detection
--   - Schema-qualified table name support (schema.table)
--   - Cross-schema view handling
--   - View owner preservation
--   - COMMENT ON VIEW preservation
--   - Dry run mode
--
-- Parameters:
--   table_name_in  : Table name — plain 'table' or 'schema.table'
--   alter_sql_in   : One or more ALTER TABLE statements
--                    (semicolon-separated if multiple)
--   dry_run_in     : If TRUE, only logs what would happen — no changes made
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
    full_view_name     TEXT;
    view_rec           RECORD;
    grant_record       RECORD;
    grant_statement    TEXT;
    alter_stmt         TEXT;
    view_count         INT;
    table_schema_oid   OID;
    iter               INT := 0;
    max_iter           INT := 50;  -- cycle guard
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
    CREATE TEMPORARY TABLE temp_view_ddl (
        view_name    TEXT,
        view_schema  TEXT,
        view_def     TEXT,
        view_owner   TEXT,
        view_comment TEXT,
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

    -- --------------------------------------------------------
    -- STEP 2: Seed — views directly dependent on the table
    --         Includes cross-schema views
    -- --------------------------------------------------------
    INSERT INTO temp_view_ddl (view_name, view_schema, view_def, view_owner, view_comment, topo_level)
    SELECT DISTINCT ON (v.oid)
        v.relname,
        n.nspname,
        pg_get_viewdef(v.oid, true),
        pg_get_userbyid(v.relowner),
        obj_description(v.oid, 'pg_class'),
        0
    FROM pg_depend d
    JOIN pg_rewrite   r ON r.oid      = d.objid
    JOIN pg_class     v ON v.oid      = r.ev_class
    JOIN pg_class     t ON t.oid      = d.refobjid
    JOIN pg_namespace n ON n.oid      = v.relnamespace
    WHERE t.relname      = input_table
      AND t.relnamespace = table_schema_oid
      AND v.relkind      = 'v'
      AND v.oid         != t.oid;
    -- Note: cross-schema views are included (no schema filter on v)

    -- --------------------------------------------------------
    -- STEP 3: BFS walk for transitive dependencies
    --         with circular dependency detection
    -- --------------------------------------------------------
    LOOP
        iter := iter + 1;
        IF iter > max_iter THEN
            RAISE EXCEPTION 'Circular dependency detected or dependency depth exceeds % levels. Aborting.', max_iter;
        END IF;

        INSERT INTO temp_view_ddl (view_name, view_schema, view_def, view_owner, view_comment, topo_level)
        SELECT DISTINCT ON (v.oid)
            v.relname,
            n.nspname,
            pg_get_viewdef(v.oid, true),
            pg_get_userbyid(v.relowner),
            obj_description(v.oid, 'pg_class'),
            (SELECT topo_level FROM temp_view_ddl WHERE view_name = p.view_name AND view_schema = p.view_schema) + 1
        FROM temp_view_ddl p
        JOIN pg_class     pv ON pv.relname     = p.view_name
                             AND pv.relnamespace = (
                                    SELECT oid FROM pg_namespace WHERE nspname = p.view_schema
                                 )
                             AND pv.relkind     = 'v'
        JOIN pg_depend    d  ON d.refobjid      = pv.oid
        JOIN pg_rewrite   r  ON r.oid           = d.objid
        JOIN pg_class     v  ON v.oid           = r.ev_class
        JOIN pg_namespace n  ON n.oid           = v.relnamespace
        WHERE v.relkind  = 'v'
          AND v.oid     != pv.oid
          AND NOT EXISTS (
              SELECT 1 FROM temp_view_ddl ex
              WHERE ex.view_name = v.relname AND ex.view_schema = n.nspname
          );

        EXIT WHEN NOT FOUND;
    END LOOP;

    -- Record dependency edges
    INSERT INTO temp_view_deps (parent_view, child_view)
    SELECT DISTINCT pv.relname, cv.relname
    FROM temp_view_ddl p
    JOIN pg_class     pv ON pv.relname      = p.view_name
                         AND pv.relnamespace = (
                                SELECT oid FROM pg_namespace WHERE nspname = p.view_schema
                             )
                         AND pv.relkind     = 'v'
    JOIN pg_depend    d  ON d.refobjid      = pv.oid
    JOIN pg_rewrite   r  ON r.oid           = d.objid
    JOIN pg_class     cv ON cv.oid          = r.ev_class
    JOIN pg_namespace n  ON n.oid           = cv.relnamespace
    WHERE cv.relkind  = 'v'
      AND cv.oid     != pv.oid
      AND cv.relname IN (SELECT view_name FROM temp_view_ddl);

    SELECT COUNT(*) INTO view_count FROM temp_view_ddl;

    IF view_count = 0 THEN
        RAISE NOTICE 'No dependent views found on table %. Proceeding with ALTER only.', full_table_name;
    ELSE
        RAISE NOTICE 'Found % distinct dependent view(s) (including transitive):', view_count;
        FOR view_rec IN
            SELECT view_name, view_schema, view_owner, topo_level
            FROM temp_view_ddl
            ORDER BY topo_level, view_name
        LOOP
            RAISE NOTICE '  [level %] %.% (owner: %)',
                view_rec.topo_level,
                view_rec.view_schema,
                view_rec.view_name,
                view_rec.view_owner;
        END LOOP;

        RAISE NOTICE 'Dependency edges:';
        FOR view_rec IN SELECT parent_view, child_view FROM temp_view_deps ORDER BY parent_view
        LOOP
            RAISE NOTICE '  % --> %', view_rec.parent_view, view_rec.child_view;
        END LOOP;
    END IF;

    -- --------------------------------------------------------
    -- STEP 4: Capture grants for all views
    -- --------------------------------------------------------
    FOR view_rec IN SELECT view_name, view_schema FROM temp_view_ddl ORDER BY view_name
    LOOP
        full_view_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);

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
                CASE
                    WHEN grantee_oid = 0 THEN 'PUBLIC'
                    ELSE pg_get_userbyid(grantee_oid)
                END                              AS grantee,
                pg_get_userbyid(grantor_oid)     AS grantor,
                is_grantable,
                string_agg(privilege_type, ', ') AS privileges
            FROM acl_entries
            WHERE grantee_oid != 0
              AND pg_get_userbyid(grantee_oid) != current_user
            GROUP BY grantee_oid, grantor_oid, is_grantable
        LOOP
            grant_statement := format(
                'GRANT %s ON %s TO %I %s;',
                grant_record.privileges,
                full_view_name,
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

    -- If dry run, stop here — nothing destructive below
    IF dry_run_in THEN
        RAISE NOTICE '[DRY RUN] No changes made. Remove dry_run_in => TRUE to execute.';
        RETURN;
    END IF;

    -- --------------------------------------------------------
    -- STEP 5: Drop views in REVERSE topo order (deepest first)
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, view_schema
        FROM temp_view_ddl
        ORDER BY topo_level DESC, view_name
    LOOP
        full_view_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);
        EXECUTE format('DROP VIEW %s;', full_view_name);
        RAISE NOTICE 'Dropped view: %', full_view_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 6: Execute ALTER TABLE statement(s)
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
    -- STEP 7: Recreate views in CORRECT topo order (shallowest first)
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, view_schema, view_def, view_owner, view_comment
        FROM temp_view_ddl
        ORDER BY topo_level ASC, view_name
    LOOP
        full_view_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);

        -- Recreate view
        EXECUTE format('CREATE VIEW %s AS %s', full_view_name, view_rec.view_def);
        RAISE NOTICE 'Recreated view: %', full_view_name;

        -- Restore owner
        EXECUTE format('ALTER VIEW %s OWNER TO %I;', full_view_name, view_rec.view_owner);
        RAISE NOTICE '  [%] Owner restored to: %', view_rec.view_name, view_rec.view_owner;

        -- Restore comment if it existed
        IF view_rec.view_comment IS NOT NULL THEN
            EXECUTE format('COMMENT ON VIEW %s IS %L;', full_view_name, view_rec.view_comment);
            RAISE NOTICE '  [%] Comment restored: %', view_rec.view_name, view_rec.view_comment;
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 8: Reapply all grants
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, grant_stmt FROM temp_view_grants ORDER BY view_name, grant_stmt
    LOOP
        EXECUTE view_rec.grant_stmt;
        RAISE NOTICE '  [%] Reapplied grant: %', view_rec.view_name, view_rec.grant_stmt;
    END LOOP;

    RAISE NOTICE '== safe_alter_table complete for table: % ==', full_table_name;
END;
$$;