---example run---

-- Logging ON (default) — writes to safe_alter_audit_log
SELECT safe_alter_table(
    'hr.employees',
    'ALTER TABLE hr.employees ADD COLUMN middle_name TEXT'
);

-- Logging OFF — no audit table writes at all, zero overhead
SELECT safe_alter_table(
    'hr.employees',
    'ALTER TABLE hr.employees ADD COLUMN middle_name TEXT',
    enable_log_in => FALSE
);

-- Dry run with logging OFF — just see the NOTICEs, nothing written anywhere
SELECT safe_alter_table(
    'hr.employees',
    'ALTER TABLE hr.employees ADD COLUMN middle_name TEXT',
    dry_run_in    => TRUE,
    enable_log_in => FALSE
);


SELECT "DBAdmin".safedba_alter_table_func(
    'hr.employees',
    'ALTER TABLE hr.employees ADD COLUMN middle_name TEXT;
     ALTER TABLE hr.employees ALTER COLUMN salary TYPE NUMERIC(15,2)',
    dry_run_in    => TRUE,
    enable_log_in => FALSE
);


SELECT "DBAdmin".safedba_alter_table_func(
    'public.RHMS_ROLEMASTER_STG_CURR',
    'ALTER TABLE public."RHMS_ROLEMASTER_STG_CURR"
    ALTER COLUMN roleid TYPE character varying(40),
    ALTER COLUMN rolename TYPE character varying(100),
    ALTER COLUMN primaryportfoliotype TYPE character varying(200),
    ALTER COLUMN portfolioqualifier1type TYPE character varying(200),
    ALTER COLUMN portfolioqualifier2type TYPE character varying(200),
    ALTER COLUMN rolecategorymastername TYPE character varying(100),
    ALTER COLUMN rolecategoryname TYPE character varying(100);',
    dry_run_in    => false,
    enable_log_in => FALSE
);


SELECT "DBAdmin".safedba_alter_table_func(
    'public.CentralRepository_RMG_ResourceRequest_MIG',
    $sql$ALTER TABLE public."CentralRepository_RMG_ResourceRequest_MIG" DROP COLUMN cts_func_skill$sql$
);


--And strips all these column reference patterns from the view:
cts_func_skill,              -- plain column with trailing comma
cts_func_skill AS alias,     -- column with alias
expr AS cts_func_skill,      -- expression aliased to dropped name
cts_func_skill               -- last column, no trailing comma




-- ============================================================
-- AUDIT LOG TABLE — Create once, only needed if enable_log_in = TRUE
-- ============================================================
CREATE TABLE IF NOT EXISTS "DBAdmin".safe_alter_table_audit_log (
    log_id          SERIAL PRIMARY KEY,
    run_id          UUID NOT NULL,
    executed_at     TIMESTAMPTZ DEFAULT now(),
    table_name      TEXT,
    alter_sql       TEXT,
    dry_run         BOOLEAN,
    object_type     TEXT,
    object_schema   TEXT,
    object_name     TEXT,
    action          TEXT,
    detail          TEXT,
    status          TEXT
);


-- ============================================================
-- safe_alter_table
--
-- Parameters:
--   table_name_in  : Table name — plain 'table' or 'schema.table', safe for case sensitive too
--   alter_sql_in   : One or more ALTER TABLE statements
--                    (semicolon-separated if multiple)
--   dry_run_in     : If TRUE, only logs what would happen — no changes made
--   enable_log_in  : If TRUE (default), writes audit log to safe_alter_audit_log
--                    If FALSE, skips all audit logging entirely
-- ============================================================

CREATE OR REPLACE FUNCTION "DBAdmin".safedba_alter_table_func(
    table_name_in       TEXT,
    alter_sql_in        TEXT,
    dry_run_in          BOOLEAN DEFAULT FALSE,
    enable_log_in       BOOLEAN DEFAULT TRUE
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
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
    idx_rec            RECORD;
    grant_statement    TEXT;
    alter_stmt         TEXT;
    view_count         INT;
    table_schema_oid   OID;
    iter               INT := 0;
    max_iter           INT := 50;
    v_run_id           UUID := gen_random_uuid();
    dropped_columns    TEXT[] := '{}';   -- columns being dropped, auto-extracted from ALTER SQL
    dropped_col        TEXT;
    clean_view_def     TEXT;
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
    FROM pg_namespace WHERE nspname = input_schema;

    IF table_schema_oid IS NULL THEN
        RAISE EXCEPTION 'Schema "%" does not exist.', input_schema;
    END IF;

    full_table_name := quote_ident(input_schema) || '.' || quote_ident(input_table);

    IF dry_run_in THEN
        RAISE NOTICE '== [DRY RUN] safe_alter_table for: % (run_id: %) ==', full_table_name, v_run_id;
    ELSE
        RAISE NOTICE '== Starting safe_alter_table for: % (run_id: %) ==', full_table_name, v_run_id;
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
        view_kind    TEXT,
        topo_level   INT DEFAULT 0
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_view_deps (
        parent_view TEXT,
        child_view  TEXT
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_view_grants (
        view_name    TEXT,
        grant_stmt   TEXT,
        grant_level  TEXT
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_matview_indexes (
        view_name   TEXT,
        view_schema TEXT,
        index_name  TEXT,
        index_def   TEXT
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_func_ddl (
        func_oid    OID,
        func_name   TEXT,
        func_schema TEXT,
        func_kind   TEXT,
        func_owner  TEXT,
        func_def    TEXT,
        func_args   TEXT
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_func_grants (
        func_name  TEXT,
        grant_stmt TEXT
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_type_ddl (
        type_oid    OID,
        type_name   TEXT,
        type_schema TEXT,
        type_owner  TEXT,
        type_def    TEXT
    ) ON COMMIT DROP;

    -- Audit buffer: only created when logging is enabled
    IF enable_log_in THEN
        CREATE TEMPORARY TABLE temp_audit_buffer (
            object_type   TEXT,
            object_schema TEXT,
            object_name   TEXT,
            action        TEXT,
            detail        TEXT,
            status        TEXT
        ) ON COMMIT DROP;
    END IF;

    -- --------------------------------------------------------
    -- Validate ALTER SQL references the correct table
    -- Uses word boundary regex (\m \M) to avoid substring matches
    -- e.g. 'employees' will NOT match 'other_employees_backup'
    -- --------------------------------------------------------
    IF NOT (lower(alter_sql_in) ~ ('\m' || lower(input_table) || '\M')) THEN
        IF enable_log_in THEN
            INSERT INTO temp_audit_buffer VALUES (
                'TABLE', input_schema, input_table, 'ERROR',
                'ALTER SQL does not reference table: ' || input_table, 'ERROR'
            );
            INSERT INTO "DBAdmin".safe_alter_audit_log
                (run_id, table_name, alter_sql, dry_run, object_type, object_schema, object_name, action, detail, status)
            SELECT v_run_id, full_table_name, alter_sql_in, dry_run_in,
                   object_type, object_schema, object_name, action, detail, status
            FROM temp_audit_buffer;
        END IF;
        RAISE EXCEPTION 'ALTER SQL does not reference table "%". Aborting.', input_table;
    END IF;

    IF enable_log_in THEN
        INSERT INTO temp_audit_buffer VALUES (
            'TABLE', input_schema, input_table, 'DISCOVERED', full_table_name, 'OK'
        );
    END IF;

    -- --------------------------------------------------------
    -- Auto-extract dropped column names from ALTER SQL
    -- Handles: DROP COLUMN col, DROP COLUMN IF EXISTS col
    -- Captures all dropped columns across multiple statements
    -- --------------------------------------------------------
    SELECT array_agg(lower(trim(match[1])))
    INTO dropped_columns
    FROM regexp_matches(
        lower(alter_sql_in),
        'drop\s+column\s+(?:if\s+exists\s+)?([a-z_][a-z0-9_$]*)',
        'g'
    ) AS match;

    IF dropped_columns IS NOT NULL AND array_length(dropped_columns, 1) > 0 THEN
        RAISE NOTICE 'Detected % dropped column(s): %',
            array_length(dropped_columns, 1),
            array_to_string(dropped_columns, ', ');
    END IF;

    -- --------------------------------------------------------
    -- STEP 2: Discover dependent VIEWS & MATERIALIZED VIEWS
    -- Strip trailing semicolons from pg_get_viewdef() output
    -- --------------------------------------------------------
    INSERT INTO temp_view_ddl (view_name, view_schema, view_def, view_owner, view_comment, view_kind, topo_level)
    SELECT DISTINCT ON (v.oid)
        v.relname, n.nspname,
        rtrim(pg_get_viewdef(v.oid, true), '; '),
        pg_get_userbyid(v.relowner),
        obj_description(v.oid, 'pg_class'),
        v.relkind::TEXT, 0
    FROM pg_depend d
    JOIN pg_rewrite   r ON r.oid      = d.objid
    JOIN pg_class     v ON v.oid      = r.ev_class
    JOIN pg_class     t ON t.oid      = d.refobjid
    JOIN pg_namespace n ON n.oid      = v.relnamespace
    WHERE t.relname      = input_table
      AND t.relnamespace = table_schema_oid
      AND v.relkind      IN ('v', 'm')
      AND v.oid         != t.oid;

    -- BFS for transitive view dependencies
    LOOP
        iter := iter + 1;
        IF iter > max_iter THEN
            IF enable_log_in THEN
                INSERT INTO temp_audit_buffer VALUES (
                    'VIEW', input_schema, null, 'ERROR',
                    'Circular dependency or depth > ' || max_iter, 'ERROR'
                );
                INSERT INTO "DBAdmin".safe_alter_audit_log
                    (run_id, table_name, alter_sql, dry_run, object_type, object_schema, object_name, action, detail, status)
                SELECT v_run_id, full_table_name, alter_sql_in, dry_run_in,
                       object_type, object_schema, object_name, action, detail, status
                FROM temp_audit_buffer;
            END IF;
            RAISE EXCEPTION 'Circular dependency detected or dependency depth exceeds % levels.', max_iter;
        END IF;

        INSERT INTO temp_view_ddl (view_name, view_schema, view_def, view_owner, view_comment, view_kind, topo_level)
        SELECT DISTINCT ON (v.oid)
            v.relname, n.nspname,
            rtrim(pg_get_viewdef(v.oid, true), '; '),
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
                view_rec.view_schema, view_rec.view_name, view_rec.view_owner;
        END LOOP;

        IF enable_log_in THEN
            INSERT INTO temp_audit_buffer
            SELECT
                CASE view_kind WHEN 'm' THEN 'MATVIEW' ELSE 'VIEW' END,
                view_schema, view_name, 'DISCOVERED',
                'topo_level=' || topo_level || ', owner=' || view_owner, 'OK'
            FROM temp_view_ddl;
        END IF;

        RAISE NOTICE 'Dependency edges:';
        FOR view_rec IN SELECT parent_view, child_view FROM temp_view_deps ORDER BY parent_view LOOP
            RAISE NOTICE '  % --> %', view_rec.parent_view, view_rec.child_view;
        END LOOP;
    END IF;

    -- --------------------------------------------------------
    -- STEP 3: Capture matview indexes
    -- --------------------------------------------------------
    INSERT INTO temp_matview_indexes (view_name, view_schema, index_name, index_def)
    SELECT v.view_name, v.view_schema, i.indexname, i.indexdef
    FROM temp_view_ddl v
    JOIN pg_indexes i ON i.tablename  = v.view_name
                     AND i.schemaname = v.view_schema
    WHERE v.view_kind = 'm';

    IF enable_log_in THEN
        INSERT INTO temp_audit_buffer
        SELECT 'INDEX', view_schema, index_name, 'DISCOVERED',
               'On matview: ' || view_name, 'OK'
        FROM temp_matview_indexes;
    END IF;

    FOR idx_rec IN SELECT view_name, index_name FROM temp_matview_indexes ORDER BY view_name LOOP
        RAISE NOTICE '  [%] Matview index captured: %', idx_rec.view_name, idx_rec.index_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 4: Discover FUNCTIONS & PROCEDURES
    -- --------------------------------------------------------
    INSERT INTO temp_func_ddl (func_oid, func_name, func_schema, func_kind, func_owner, func_def, func_args)
    SELECT DISTINCT ON (p.oid)
        p.oid, p.proname, n.nspname, p.prokind::TEXT,
        pg_get_userbyid(p.proowner),
        pg_get_functiondef(p.oid),
        pg_get_function_identity_arguments(p.oid)
    FROM pg_depend d
    JOIN pg_proc      p ON p.oid  = d.objid
    JOIN pg_class     t ON t.oid  = d.refobjid
    JOIN pg_namespace n ON n.oid  = p.pronamespace
    WHERE t.relname      = input_table
      AND t.relnamespace = table_schema_oid
      AND d.deptype      = 'n'
      AND p.prokind      IN ('f', 'p');

    INSERT INTO temp_func_ddl (func_oid, func_name, func_schema, func_kind, func_owner, func_def, func_args)
    SELECT DISTINCT ON (p.oid)
        p.oid, p.proname, n.nspname, p.prokind::TEXT,
        pg_get_userbyid(p.proowner),
        pg_get_functiondef(p.oid),
        pg_get_function_identity_arguments(p.oid)
    FROM temp_view_ddl v
    JOIN pg_class     vc ON vc.relname      = v.view_name
                         AND vc.relnamespace = (
                                SELECT oid FROM pg_namespace WHERE nspname = v.view_schema
                             )
    JOIN pg_depend    d  ON d.refobjid      = vc.oid
    JOIN pg_proc      p  ON p.oid           = d.objid
    JOIN pg_namespace n  ON n.oid           = p.pronamespace
    WHERE d.deptype = 'n'
      AND p.prokind IN ('f', 'p')
      AND NOT EXISTS (SELECT 1 FROM temp_func_ddl ex WHERE ex.func_oid = p.oid);

    IF enable_log_in THEN
        INSERT INTO temp_audit_buffer
        SELECT
            CASE func_kind WHEN 'p' THEN 'PROCEDURE' ELSE 'FUNCTION' END,
            func_schema, func_name, 'DISCOVERED', 'owner=' || func_owner, 'OK'
        FROM temp_func_ddl;
    END IF;

    FOR func_rec IN SELECT func_name, func_schema, func_kind, func_owner FROM temp_func_ddl ORDER BY func_name LOOP
        RAISE NOTICE '  [%] %.% (owner: %)',
            CASE func_rec.func_kind WHEN 'p' THEN 'PROCEDURE' ELSE 'FUNCTION' END,
            func_rec.func_schema, func_rec.func_name, func_rec.func_owner;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 5: Discover COMPOSITE / TABLE TYPES
    -- --------------------------------------------------------
    INSERT INTO temp_type_ddl (type_oid, type_name, type_schema, type_owner, type_def)
    SELECT DISTINCT ON (ty.oid)
        ty.oid, ty.typname, n.nspname,
        pg_get_userbyid(ty.typowner),
        'CREATE TYPE ' || quote_ident(n.nspname) || '.' || quote_ident(ty.typname) || ' AS (' ||
        string_agg(
            quote_ident(a.attname) || ' ' || pg_catalog.format_type(a.atttypid, a.atttypmod),
            ', ' ORDER BY a.attnum
        ) || ')'
    FROM pg_depend d
    JOIN pg_type      ty ON ty.oid     = d.objid
    JOIN pg_class     t  ON t.oid      = d.refobjid
    JOIN pg_namespace n  ON n.oid      = ty.typnamespace
    JOIN pg_class     tc ON tc.oid     = ty.typrelid
    JOIN pg_attribute a  ON a.attrelid = tc.oid AND a.attnum > 0 AND NOT a.attisdropped
    WHERE t.relname      = input_table
      AND t.relnamespace = table_schema_oid
      AND ty.typtype     = 'c'
      AND d.deptype      = 'n'
    GROUP BY ty.oid, ty.typname, n.nspname, ty.typowner;

    IF enable_log_in THEN
        INSERT INTO temp_audit_buffer
        SELECT 'TYPE', type_schema, type_name, 'DISCOVERED', 'owner=' || type_owner, 'OK'
        FROM temp_type_ddl;
    END IF;

    FOR type_rec IN SELECT type_name, type_schema, type_owner FROM temp_type_ddl ORDER BY type_name LOOP
        RAISE NOTICE '  [TYPE] %.% (owner: %)', type_rec.type_schema, type_rec.type_name, type_rec.type_owner;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 6: Capture TABLE-LEVEL + COLUMN-LEVEL grants for views
    -- --------------------------------------------------------
    FOR view_rec IN SELECT view_name, view_schema FROM temp_view_ddl ORDER BY view_name
    LOOP
        full_obj_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);

        -- Table-level grants
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
                WHERE c.relname = view_rec.view_name
                  AND n.nspname = view_rec.view_schema
                  AND c.relacl  IS NOT NULL
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
                grant_record.privileges, full_obj_name, grant_record.grantee,
                CASE WHEN grant_record.is_grantable THEN 'WITH GRANT OPTION' ELSE '' END
            );
            INSERT INTO temp_view_grants VALUES (view_rec.view_name, grant_statement, 'TABLE');
            RAISE NOTICE '  [%] Table-grant captured for "%": %',
                view_rec.view_name, grant_record.grantee, grant_statement;
        END LOOP;

        -- Column-level grants
        FOR grant_record IN
            SELECT
                a.attname                                        AS col_name,
                CASE WHEN ace.grantee = 0 THEN 'PUBLIC'
                     ELSE pg_get_userbyid(ace.grantee) END      AS grantee,
                ace.is_grantable,
                string_agg(ace.privilege_type, ', ')            AS privileges
            FROM pg_class c
            JOIN pg_namespace  n ON n.oid      = c.relnamespace
            JOIN pg_attribute  a ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped,
            LATERAL aclexplode(a.attacl) AS ace
            WHERE c.relname   = view_rec.view_name
              AND n.nspname   = view_rec.view_schema
              AND a.attacl    IS NOT NULL
              AND ace.grantee != 0
              AND pg_get_userbyid(ace.grantee) != current_user
            GROUP BY a.attname, ace.grantee, ace.is_grantable
        LOOP
            grant_statement := format(
                'GRANT %s (%s) ON %s TO %I %s;',
                grant_record.privileges, grant_record.col_name,
                full_obj_name, grant_record.grantee,
                CASE WHEN grant_record.is_grantable THEN 'WITH GRANT OPTION' ELSE '' END
            );
            INSERT INTO temp_view_grants VALUES (view_rec.view_name, grant_statement, 'COLUMN');
            RAISE NOTICE '  [%] Column-grant captured for "%" on col "%": %',
                view_rec.view_name, grant_record.grantee, grant_record.col_name, grant_statement;
        END LOOP;

        IF NOT FOUND THEN
            RAISE NOTICE '  [%] No column grants found.', view_rec.view_name;
        END IF;
    END LOOP;

    IF enable_log_in THEN
        INSERT INTO temp_audit_buffer
        SELECT 'GRANT', null, view_name, 'GRANT_CAPTURED', grant_stmt, 'OK'
        FROM temp_view_grants;
    END IF;

    -- --------------------------------------------------------
    -- STEP 7: Capture grants for functions & procedures
    -- --------------------------------------------------------
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
                WHERE p.oid = func_rec.func_oid AND p.proacl IS NOT NULL
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
                full_obj_name, grant_record.grantee,
                CASE WHEN grant_record.is_grantable THEN 'WITH GRANT OPTION' ELSE '' END
            );
            INSERT INTO temp_func_grants VALUES (func_rec.func_name, grant_statement);
            RAISE NOTICE '  [%] Grant captured for "%": %',
                func_rec.func_name, grant_record.grantee, grant_statement;
        END LOOP;
    END LOOP;

    IF enable_log_in THEN
        INSERT INTO temp_audit_buffer
        SELECT 'GRANT', null, func_name, 'GRANT_CAPTURED', grant_stmt, 'OK'
        FROM temp_func_grants;
    END IF;

    -- --------------------------------------------------------
    -- DRY RUN stops here
    -- --------------------------------------------------------
    IF dry_run_in THEN
        IF enable_log_in THEN
            INSERT INTO "DBAdmin".safe_alter_audit_log
                (run_id, table_name, alter_sql, dry_run, object_type, object_schema, object_name, action, detail, status)
            SELECT v_run_id, full_table_name, alter_sql_in, TRUE,
                   object_type, object_schema, object_name, action, detail, status
            FROM temp_audit_buffer;
        END IF;
        RAISE NOTICE '[DRY RUN] No changes made. Set dry_run_in => FALSE to execute. (run_id: %)', v_run_id;
        RETURN;
    END IF;

    -- --------------------------------------------------------
    -- STEP 8: Drop views in REVERSE topo order
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, view_schema, view_kind
        FROM temp_view_ddl ORDER BY topo_level DESC, view_name
    LOOP
        full_obj_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);
        BEGIN
            IF view_rec.view_kind = 'm' THEN
                EXECUTE format('DROP MATERIALIZED VIEW %s;', full_obj_name);
                RAISE NOTICE 'Dropped materialized view: %', full_obj_name;
            ELSE
                EXECUTE format('DROP VIEW %s;', full_obj_name);
                RAISE NOTICE 'Dropped view: %', full_obj_name;
            END IF;
            IF enable_log_in THEN
                INSERT INTO temp_audit_buffer VALUES (
                    CASE view_rec.view_kind WHEN 'm' THEN 'MATVIEW' ELSE 'VIEW' END,
                    view_rec.view_schema, view_rec.view_name, 'DROPPED', null, 'OK'
                );
            END IF;
        EXCEPTION WHEN OTHERS THEN
            IF enable_log_in THEN
                INSERT INTO temp_audit_buffer VALUES (
                    CASE view_rec.view_kind WHEN 'm' THEN 'MATVIEW' ELSE 'VIEW' END,
                    view_rec.view_schema, view_rec.view_name, 'ERROR', SQLERRM, 'ERROR'
                );
                INSERT INTO "DBAdmin".safe_alter_audit_log
                    (run_id, table_name, alter_sql, dry_run, object_type, object_schema, object_name, action, detail, status)
                SELECT v_run_id, full_table_name, alter_sql_in, FALSE,
                       object_type, object_schema, object_name, action, detail, status
                FROM temp_audit_buffer;
            END IF;
            RAISE;
        END;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 9: Drop functions & procedures
    -- --------------------------------------------------------
    FOR func_rec IN SELECT func_name, func_schema, func_kind, func_args FROM temp_func_ddl ORDER BY func_name
    LOOP
        full_obj_name := quote_ident(func_rec.func_schema) || '.' || quote_ident(func_rec.func_name);
        BEGIN
            IF func_rec.func_kind = 'p' THEN
                EXECUTE format('DROP PROCEDURE %s(%s);', full_obj_name, func_rec.func_args);
                RAISE NOTICE 'Dropped procedure: %(%)', full_obj_name, func_rec.func_args;
            ELSE
                EXECUTE format('DROP FUNCTION %s(%s);', full_obj_name, func_rec.func_args);
                RAISE NOTICE 'Dropped function: %(%)', full_obj_name, func_rec.func_args;
            END IF;
            IF enable_log_in THEN
                INSERT INTO temp_audit_buffer VALUES (
                    CASE func_rec.func_kind WHEN 'p' THEN 'PROCEDURE' ELSE 'FUNCTION' END,
                    func_rec.func_schema, func_rec.func_name, 'DROPPED', null, 'OK'
                );
            END IF;
        EXCEPTION WHEN OTHERS THEN
            IF enable_log_in THEN
                INSERT INTO temp_audit_buffer VALUES (
                    CASE func_rec.func_kind WHEN 'p' THEN 'PROCEDURE' ELSE 'FUNCTION' END,
                    func_rec.func_schema, func_rec.func_name, 'ERROR', SQLERRM, 'ERROR'
                );
                INSERT INTO "DBAdmin".safe_alter_audit_log
                    (run_id, table_name, alter_sql, dry_run, object_type, object_schema, object_name, action, detail, status)
                SELECT v_run_id, full_table_name, alter_sql_in, FALSE,
                       object_type, object_schema, object_name, action, detail, status
                FROM temp_audit_buffer;
            END IF;
            RAISE;
        END;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 10: Drop composite / table types
    -- --------------------------------------------------------
    FOR type_rec IN SELECT type_name, type_schema FROM temp_type_ddl ORDER BY type_name
    LOOP
        full_obj_name := quote_ident(type_rec.type_schema) || '.' || quote_ident(type_rec.type_name);
        BEGIN
            EXECUTE format('DROP TYPE %s;', full_obj_name);
            RAISE NOTICE 'Dropped type: %', full_obj_name;
            IF enable_log_in THEN
                INSERT INTO temp_audit_buffer VALUES (
                    'TYPE', type_rec.type_schema, type_rec.type_name, 'DROPPED', null, 'OK'
                );
            END IF;
        EXCEPTION WHEN OTHERS THEN
            IF enable_log_in THEN
                INSERT INTO temp_audit_buffer VALUES (
                    'TYPE', type_rec.type_schema, type_rec.type_name, 'ERROR', SQLERRM, 'ERROR'
                );
                INSERT INTO "DBAdmin".safe_alter_audit_log
                    (run_id, table_name, alter_sql, dry_run, object_type, object_schema, object_name, action, detail, status)
                SELECT v_run_id, full_table_name, alter_sql_in, FALSE,
                       object_type, object_schema, object_name, action, detail, status
                FROM temp_audit_buffer;
            END IF;
            RAISE;
        END;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 11: Execute ALTER TABLE statement(s)
    -- --------------------------------------------------------
    RAISE NOTICE 'Running ALTER TABLE on %...', full_table_name;
    FOREACH alter_stmt IN ARRAY string_to_array(alter_sql_in, ';')
    LOOP
        alter_stmt := trim(alter_stmt);
        CONTINUE WHEN alter_stmt = '';
        BEGIN
            RAISE NOTICE 'Executing: %', alter_stmt;
            EXECUTE alter_stmt;
            IF enable_log_in THEN
                INSERT INTO temp_audit_buffer VALUES (
                    'TABLE', input_schema, input_table, 'ALTER', alter_stmt, 'OK'
                );
            END IF;
        EXCEPTION WHEN OTHERS THEN
            IF enable_log_in THEN
                INSERT INTO temp_audit_buffer VALUES (
                    'TABLE', input_schema, input_table, 'ERROR',
                    'ALTER failed: ' || SQLERRM || ' | Statement: ' || alter_stmt, 'ERROR'
                );
                INSERT INTO "DBAdmin".safe_alter_audit_log
                    (run_id, table_name, alter_sql, dry_run, object_type, object_schema, object_name, action, detail, status)
                SELECT v_run_id, full_table_name, alter_sql_in, FALSE,
                       object_type, object_schema, object_name, action, detail, status
                FROM temp_audit_buffer;
            END IF;
            RAISE EXCEPTION 'ALTER TABLE failed: % | Fix the issue and re-run. All changes have been rolled back.', SQLERRM;
        END;
    END LOOP;
    RAISE NOTICE 'ALTER TABLE complete.';

    -- --------------------------------------------------------
    -- STEP 12: Recreate composite / table types
    -- --------------------------------------------------------
    FOR type_rec IN SELECT type_name, type_schema, type_owner, type_def FROM temp_type_ddl ORDER BY type_name
    LOOP
        full_obj_name := quote_ident(type_rec.type_schema) || '.' || quote_ident(type_rec.type_name);
        EXECUTE type_rec.type_def;
        EXECUTE format('ALTER TYPE %s OWNER TO %I;', full_obj_name, type_rec.type_owner);
        RAISE NOTICE 'Recreated type: % (owner: %)', full_obj_name, type_rec.type_owner;
        IF enable_log_in THEN
            INSERT INTO temp_audit_buffer VALUES (
                'TYPE', type_rec.type_schema, type_rec.type_name,
                'RECREATED', 'owner=' || type_rec.type_owner, 'OK'
            );
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 13: Recreate functions & procedures
    -- --------------------------------------------------------
    FOR func_rec IN SELECT func_name, func_schema, func_kind, func_owner, func_def FROM temp_func_ddl ORDER BY func_name
    LOOP
        full_obj_name := quote_ident(func_rec.func_schema) || '.' || quote_ident(func_rec.func_name);
        EXECUTE func_rec.func_def;
        IF func_rec.func_kind = 'p' THEN
            EXECUTE format('ALTER PROCEDURE %s OWNER TO %I;', full_obj_name, func_rec.func_owner);
        ELSE
            EXECUTE format('ALTER FUNCTION %s OWNER TO %I;', full_obj_name, func_rec.func_owner);
        END IF;
        RAISE NOTICE 'Recreated %: % (owner: %)',
            CASE func_rec.func_kind WHEN 'p' THEN 'procedure' ELSE 'function' END,
            full_obj_name, func_rec.func_owner;
        IF enable_log_in THEN
            INSERT INTO temp_audit_buffer VALUES (
                CASE func_rec.func_kind WHEN 'p' THEN 'PROCEDURE' ELSE 'FUNCTION' END,
                func_rec.func_schema, func_rec.func_name,
                'RECREATED', 'owner=' || func_rec.func_owner, 'OK'
            );
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 14: Recreate views & materialized views
    -- Auto-strips dropped columns from saved view definitions
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, view_schema, view_def, view_owner, view_comment, view_kind
        FROM temp_view_ddl ORDER BY topo_level ASC, view_name
    LOOP
        full_obj_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);
        clean_view_def := view_rec.view_def;

        -- Auto-remove each dropped column from the view SELECT list
        IF dropped_columns IS NOT NULL THEN
            FOREACH dropped_col IN ARRAY dropped_columns
            LOOP
                -- Removes lines containing the dropped column, handling:
                --   colname                    — plain reference
                --   colname,                   — with trailing comma
                --   colname AS alias           — col aliased to something else
                --   colname AS colname         — redundant self-alias
                -- Does NOT remove: other_col AS colname
                --   (alias matches but source column is different — still valid)
                clean_view_def := regexp_replace(
                    clean_view_def,
                    '(,?\s*\n?\s*)' ||
                    '\m' || dropped_col || '\M' ||   -- word boundary: exact col name match
                    '(\s+as\s+\S+)?' ||              -- optional AS alias (any alias name)
                    '\s*,?',                         -- optional trailing comma
                    '',
                    'gi'
                );

                IF clean_view_def != view_rec.view_def THEN
                    RAISE NOTICE '  [%] Auto-removed dropped column "%" from view definition.',
                        view_rec.view_name, dropped_col;
                END IF;
            END LOOP;
        END IF;

        IF view_rec.view_kind = 'm' THEN
            EXECUTE format('CREATE MATERIALIZED VIEW %s AS %s;', full_obj_name, clean_view_def);
            EXECUTE format('ALTER MATERIALIZED VIEW %s OWNER TO %I;', full_obj_name, view_rec.view_owner);
        ELSE
            EXECUTE format('CREATE VIEW %s AS %s', full_obj_name, clean_view_def);
            EXECUTE format('ALTER VIEW %s OWNER TO %I;', full_obj_name, view_rec.view_owner);
        END IF;

        IF view_rec.view_comment IS NOT NULL THEN
            EXECUTE format('COMMENT ON %s %s IS %L;',
                CASE view_rec.view_kind WHEN 'm' THEN 'MATERIALIZED VIEW' ELSE 'VIEW' END,
                full_obj_name, view_rec.view_comment);
            RAISE NOTICE '  [%] Comment restored.', view_rec.view_name;
        END IF;

        RAISE NOTICE 'Recreated %: % (owner: %)',
            CASE view_rec.view_kind WHEN 'm' THEN 'materialized view' ELSE 'view' END,
            full_obj_name, view_rec.view_owner;
        IF enable_log_in THEN
            INSERT INTO temp_audit_buffer VALUES (
                CASE view_rec.view_kind WHEN 'm' THEN 'MATVIEW' ELSE 'VIEW' END,
                view_rec.view_schema, view_rec.view_name,
                'RECREATED', 'owner=' || view_rec.view_owner, 'OK'
            );
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 15: Recreate matview indexes
    -- --------------------------------------------------------
    FOR idx_rec IN SELECT view_name, view_schema, index_name, index_def FROM temp_matview_indexes ORDER BY view_name
    LOOP
        EXECUTE idx_rec.index_def;
        RAISE NOTICE '  [%] Index recreated: %', idx_rec.view_name, idx_rec.index_name;
        IF enable_log_in THEN
            INSERT INTO temp_audit_buffer VALUES (
                'INDEX', idx_rec.view_schema, idx_rec.index_name,
                'INDEX_RECREATED', 'On matview: ' || idx_rec.view_name, 'OK'
            );
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 16: Refresh materialized views
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, view_schema FROM temp_view_ddl
        WHERE view_kind = 'm' ORDER BY topo_level ASC, view_name
    LOOP
        full_obj_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);
        EXECUTE format('REFRESH MATERIALIZED VIEW %s;', full_obj_name);
        RAISE NOTICE 'Refreshed materialized view: %', full_obj_name;
        IF enable_log_in THEN
            INSERT INTO temp_audit_buffer VALUES (
                'MATVIEW', view_rec.view_schema, view_rec.view_name,
                'MATVIEW_REFRESHED', null, 'OK'
            );
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 17: Reapply all grants — TABLE first, then COLUMN
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, grant_stmt FROM temp_view_grants
        ORDER BY view_name, grant_level DESC, grant_stmt
    LOOP
        EXECUTE view_rec.grant_stmt;
        RAISE NOTICE '  [%] Reapplied grant: %', view_rec.view_name, view_rec.grant_stmt;
        IF enable_log_in THEN
            INSERT INTO temp_audit_buffer VALUES (
                'GRANT', null, view_rec.view_name,
                'GRANT_REAPPLIED', view_rec.grant_stmt, 'OK'
            );
        END IF;
    END LOOP;

    FOR func_rec IN SELECT func_name, grant_stmt FROM temp_func_grants ORDER BY func_name, grant_stmt
    LOOP
        EXECUTE func_rec.grant_stmt;
        RAISE NOTICE '  [%] Reapplied grant: %', func_rec.func_name, func_rec.grant_stmt;
        IF enable_log_in THEN
            INSERT INTO temp_audit_buffer VALUES (
                'GRANT', null, func_rec.func_name,
                'GRANT_REAPPLIED', func_rec.grant_stmt, 'OK'
            );
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- FINAL: Flush entire audit buffer in one single INSERT
    -- --------------------------------------------------------
    IF enable_log_in THEN
        INSERT INTO "DBAdmin".safe_alter_audit_log
            (run_id, table_name, alter_sql, dry_run, object_type, object_schema, object_name, action, detail, status)
        SELECT v_run_id, full_table_name, alter_sql_in, FALSE,
               object_type, object_schema, object_name, action, detail, status
        FROM temp_audit_buffer;
    END IF;

    RAISE NOTICE '== safe_alter_table complete for: % (run_id: %) ==', full_table_name, v_run_id;
END;
$$;