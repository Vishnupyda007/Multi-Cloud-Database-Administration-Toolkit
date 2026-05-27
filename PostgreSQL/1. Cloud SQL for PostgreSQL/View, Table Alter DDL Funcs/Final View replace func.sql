-- ============================================================
-- safe_replace_view
--
-- Replaces a view's definition while preserving all dependent
-- objects and their permissions. Handles:
--   - Dependent views + materialized views (BFS topo sort)
--   - Matview indexes + auto refresh
--   - Functions & procedures (direct + via dependent views)
--   - Table-level + column-level grants (incl. PUBLIC + IAM)
--   - INSTEAD OF triggers
--   - Rules on views
--   - RLS policies
--   - Security barrier / invoker options
--   - Owner + comment preservation
--   - Cross-schema dependents
--   - Circular dependency guard
--   - New query validation before any destructive action
--   - Dry run mode

-- Dry run first — see all dependent objects and grants
SELECT "DBAdmin".alter_view_safedba_func('public.vw_esa_ps_item_stg_curr',
    $query$SELECT business_unit,
    cust_id,
    item,
    item_line,
    item_status,
    entry_type,
    bal_amt,
    accounting_dt,
    asof_dt,
    post_dt,
    due_dt,
    po_ref,
    pymnt_terms_cd,
    item_seq_num,
    bal_currency,
    currency_cd,
    consol_invoice,
    payment_method,
    orig_item_amt,
    invoice_dt,
    entered_dttm,
    last_update_dttm,
    rec_created_by,
    source_upd_dttm AS lastupdateddatetime,
    rec_created_dttm,
    record_status,
    src_seq_num
   FROM esa_ps_item_stg_curr
  WHERE record_status <> 'D'::bpchar;$query$,
    dry_run_in => TRUE
);

-- Execute — replace the view
SELECT safe_replace_view(
    'hr.emp_view',
    'SELECT id, name, salary, department, new_col FROM hr.employees'
);

-- Plain view name (uses current schema)
SELECT safe_replace_view(
    'emp_view',
    'SELECT id, name FROM employees WHERE active = true'
);
--
-- Parameters:
--   view_name_in  : View to replace — plain 'view' or 'schema.view'
--   new_query_in  : The new SELECT statement for the view
--   dry_run_in    : If TRUE, logs what would happen — no changes made
-- ============================================================

CREATE OR REPLACE FUNCTION "DBAdmin".alter_view_safedba_func(
    view_name_in  TEXT,
    new_query_in  TEXT,
    dry_run_in    BOOLEAN DEFAULT FALSE
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
    input_schema      TEXT;
    input_view        TEXT;
    full_view_name    TEXT;
    full_obj_name     TEXT;
    view_rec          RECORD;
    grant_record      RECORD;
    func_rec          RECORD;
    idx_rec           RECORD;
    grant_statement   TEXT;
    view_count        INT;
    target_schema_oid OID;
    iter              INT := 0;
    max_iter          INT := 50;
    target_owner      TEXT;
    target_comment    TEXT;
    target_reloptions TEXT[];
    view_security_opt TEXT;
BEGIN
    -- --------------------------------------------------------
    -- Parse schema.view or plain view input
    -- --------------------------------------------------------
    IF position('.' IN view_name_in) > 0 THEN
        input_schema := split_part(view_name_in, '.', 1);
        input_view   := split_part(view_name_in, '.', 2);
    ELSE
        input_schema := current_schema();
        input_view   := view_name_in;
    END IF;

    SELECT oid INTO target_schema_oid
    FROM pg_namespace WHERE nspname = input_schema;

    IF target_schema_oid IS NULL THEN
        RAISE EXCEPTION 'Schema "%" does not exist.', input_schema;
    END IF;

    -- Verify view exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relname = input_view
          AND n.nspname = input_schema
          AND c.relkind = 'v'
    ) THEN
        RAISE EXCEPTION 'View "%.%" does not exist.', input_schema, input_view;
    END IF;

    -- --------------------------------------------------------
    -- Validate new_query_in before touching anything
    -- --------------------------------------------------------
    IF new_query_in IS NULL OR trim(new_query_in) = '' THEN
        RAISE EXCEPTION 'new_query_in cannot be NULL or empty.';
    END IF;

    -- Strip trailing semicolon and whitespace from new query
    new_query_in := rtrim(new_query_in, '; ');

    -- Strip leading whitespace/newlines/tabs, then check case-insensitively
    IF lower(regexp_replace(trim(both E'\n\r\t ' from new_query_in), '^\s+', '', 'g')) NOT LIKE 'select%' THEN
        RAISE EXCEPTION 'new_query_in must be a SELECT statement. Got: %', left(trim(new_query_in), 50);
    END IF;

    -- Syntax-check the new query using EXPLAIN (dry parse only, no execution)
    BEGIN
        EXECUTE format('EXPLAIN SELECT * FROM (%s) _q', new_query_in);
    EXCEPTION WHEN OTHERS THEN
        RAISE EXCEPTION 'new_query_in is not a valid SELECT statement: %', SQLERRM;
    END;

    full_view_name := quote_ident(input_schema) || '.' || quote_ident(input_view);

    IF dry_run_in THEN
        RAISE NOTICE '== [DRY RUN] safe_replace_view for: % ==', full_view_name;
    ELSE
        RAISE NOTICE '== Starting safe_replace_view for: % ==', full_view_name;
    END IF;

    -- --------------------------------------------------------
    -- STEP 1: Capture target view metadata
    -- --------------------------------------------------------
    SELECT
        pg_get_userbyid(c.relowner),
        obj_description(c.oid, 'pg_class'),
        c.reloptions
    INTO target_owner, target_comment, target_reloptions
    FROM pg_class     c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = input_view AND n.nspname = input_schema;

    -- Build security option string from reloptions
    -- e.g. security_barrier=true or security_invoker=true
    SELECT string_agg(opt, ', ')
    INTO view_security_opt
    FROM unnest(target_reloptions) AS opt
    WHERE opt ILIKE 'security_%';

    RAISE NOTICE 'Target view owner: %, security options: %',
        target_owner, COALESCE(view_security_opt, 'none');

    -- --------------------------------------------------------
    -- STEP 2: Temp tables with indexes for performance
    -- --------------------------------------------------------
    CREATE TEMPORARY TABLE temp_view_ddl (
        view_name    TEXT,
        view_schema  TEXT,
        view_schema_oid OID,     -- resolved once, avoids repeated pg_namespace lookups
        view_def     TEXT,
        view_owner   TEXT,
        view_comment TEXT,
        view_kind    TEXT,       -- 'v' = view, 'm' = materialized view
        reloptions   TEXT[],
        topo_level   INT DEFAULT 0,
        is_target    BOOLEAN DEFAULT FALSE
    ) ON COMMIT DROP;

    CREATE INDEX ON temp_view_ddl (view_name, view_schema);
    CREATE INDEX ON temp_view_ddl (topo_level);

    CREATE TEMPORARY TABLE temp_view_deps (
        parent_view TEXT,
        child_view  TEXT
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_view_grants (
        view_name   TEXT,
        grant_stmt  TEXT,
        grant_level TEXT    -- 'TABLE' or 'COLUMN'
    ) ON COMMIT DROP;

    CREATE INDEX ON temp_view_grants (view_name);

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

    CREATE TEMPORARY TABLE temp_triggers (
        view_name    TEXT,
        view_schema  TEXT,
        trigger_name TEXT,
        trigger_def  TEXT    -- full CREATE TRIGGER statement from pg_get_triggerdef()
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_rules (
        view_name   TEXT,
        view_schema TEXT,
        rule_name   TEXT,
        rule_def    TEXT    -- full CREATE RULE statement from pg_get_ruledef()
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_rls_policies (
        view_name    TEXT,
        view_schema  TEXT,
        policy_name  TEXT,
        policy_def   TEXT    -- reconstructed CREATE POLICY statement
    ) ON COMMIT DROP;

    -- Resolve all schema OIDs upfront into a lookup table — avoids
    -- repeated pg_namespace subqueries inside BFS and grant loops
    CREATE TEMPORARY TABLE temp_schema_oids (
        schema_name TEXT,
        schema_oid  OID
    ) ON COMMIT DROP;

    CREATE INDEX ON temp_schema_oids (schema_name);

    INSERT INTO temp_schema_oids (schema_name, schema_oid)
    SELECT nspname, oid FROM pg_namespace;

    -- --------------------------------------------------------
    -- STEP 3: Seed with target view
    -- Strip trailing semicolon from pg_get_viewdef() output —
    -- pg_get_viewdef() sometimes includes a trailing semicolon
    -- which breaks CREATE VIEW ... AS <def> execution
    -- --------------------------------------------------------
    INSERT INTO temp_view_ddl (view_name, view_schema, view_schema_oid, view_def,
                               view_owner, view_comment, view_kind, reloptions, topo_level, is_target)
    SELECT
        c.relname, n.nspname, n.oid,
        rtrim(pg_get_viewdef(c.oid, true), '; '),
        pg_get_userbyid(c.relowner),
        obj_description(c.oid, 'pg_class'),
        c.relkind::TEXT,
        c.reloptions,
        0, TRUE
    FROM pg_class     c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname   = input_view
      AND n.nspname   = input_schema
      AND c.relkind   = 'v';

    -- --------------------------------------------------------
    -- STEP 4: BFS — discover dependent views + matviews
    --         Uses pre-resolved schema OIDs for performance
    -- --------------------------------------------------------
    LOOP
        iter := iter + 1;
        IF iter > max_iter THEN
            RAISE EXCEPTION 'Circular dependency detected or depth exceeds % levels.', max_iter;
        END IF;

        INSERT INTO temp_view_ddl (view_name, view_schema, view_schema_oid, view_def,
                                   view_owner, view_comment, view_kind, reloptions, topo_level, is_target)
        SELECT DISTINCT ON (v.oid)
            v.relname, n.nspname, n.oid,
            rtrim(pg_get_viewdef(v.oid, true), '; '),
            pg_get_userbyid(v.relowner),
            obj_description(v.oid, 'pg_class'),
            v.relkind::TEXT,
            v.reloptions,
            p.topo_level + 1,
            FALSE
        FROM temp_view_ddl     p
        JOIN temp_schema_oids  so ON so.schema_name = p.view_schema   -- OID lookup from cache
        JOIN pg_class          pv ON pv.relname      = p.view_name
                                  AND pv.relnamespace = so.schema_oid
                                  AND pv.relkind      IN ('v', 'm')
        JOIN pg_depend         d  ON d.refobjid       = pv.oid
        JOIN pg_rewrite        r  ON r.oid            = d.objid
        JOIN pg_class          v  ON v.oid            = r.ev_class
        JOIN pg_namespace      n  ON n.oid            = v.relnamespace
        WHERE v.relkind IN ('v', 'm')
          AND v.oid    != pv.oid
          AND NOT EXISTS (
              SELECT 1 FROM temp_view_ddl ex
              WHERE ex.view_name = v.relname AND ex.view_schema = n.nspname
          );

        EXIT WHEN NOT FOUND;
    END LOOP;

    -- Dependency edges for logging
    INSERT INTO temp_view_deps (parent_view, child_view)
    SELECT DISTINCT pv.relname, cv.relname
    FROM temp_view_ddl    p
    JOIN temp_schema_oids so ON so.schema_name = p.view_schema
    JOIN pg_class         pv ON pv.relname      = p.view_name
                             AND pv.relnamespace = so.schema_oid
                             AND pv.relkind      IN ('v', 'm')
    JOIN pg_depend        d  ON d.refobjid       = pv.oid
    JOIN pg_rewrite       r  ON r.oid            = d.objid
    JOIN pg_class         cv ON cv.oid           = r.ev_class
    JOIN pg_namespace     n  ON n.oid            = cv.relnamespace
    WHERE cv.relkind IN ('v', 'm')
      AND cv.oid    != pv.oid
      AND cv.relname IN (SELECT view_name FROM temp_view_ddl);

    SELECT COUNT(*) - 1 INTO view_count FROM temp_view_ddl;

    RAISE NOTICE 'Target view: %.%', input_schema, input_view;
    IF view_count = 0 THEN
        RAISE NOTICE 'No dependent views found.';
    ELSE
        RAISE NOTICE 'Found % dependent object(s):', view_count;
        FOR view_rec IN
            SELECT view_name, view_schema, view_owner, view_kind, topo_level
            FROM temp_view_ddl WHERE is_target = FALSE
            ORDER BY topo_level, view_name
        LOOP
            RAISE NOTICE '  [level %] [%] %.% (owner: %)',
                view_rec.topo_level,
                CASE view_rec.view_kind WHEN 'm' THEN 'MATVIEW' ELSE 'VIEW' END,
                view_rec.view_schema, view_rec.view_name, view_rec.view_owner;
        END LOOP;
        RAISE NOTICE 'Dependency edges:';
        FOR view_rec IN SELECT parent_view, child_view FROM temp_view_deps ORDER BY parent_view LOOP
            RAISE NOTICE '  % --> %', view_rec.parent_view, view_rec.child_view;
        END LOOP;
    END IF;

    -- --------------------------------------------------------
    -- STEP 5: Capture matview indexes
    -- --------------------------------------------------------
    INSERT INTO temp_matview_indexes (view_name, view_schema, index_name, index_def)
    SELECT v.view_name, v.view_schema, i.indexname, i.indexdef
    FROM temp_view_ddl v
    JOIN pg_indexes    i ON i.tablename  = v.view_name
                        AND i.schemaname = v.view_schema
    WHERE v.view_kind = 'm';

    FOR idx_rec IN SELECT view_name, index_name FROM temp_matview_indexes ORDER BY view_name LOOP
        RAISE NOTICE '  [%] Matview index captured: %', idx_rec.view_name, idx_rec.index_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 6: Capture INSTEAD OF triggers on all views
    -- --------------------------------------------------------
    INSERT INTO temp_triggers (view_name, view_schema, trigger_name, trigger_def)
    SELECT
        c.relname,
        n.nspname,
        t.tgname,
        pg_get_triggerdef(t.oid, true)
    FROM temp_view_ddl    v
    JOIN temp_schema_oids so ON so.schema_name = v.view_schema
    JOIN pg_class         c  ON c.relname      = v.view_name
                             AND c.relnamespace = so.schema_oid
    JOIN pg_namespace     n  ON n.oid           = c.relnamespace
    JOIN pg_trigger       t  ON t.tgrelid       = c.oid
    WHERE NOT t.tgisinternal   -- exclude constraint triggers
      AND t.tgtype & 64 = 64;  -- INSTEAD OF triggers (bit 6)

    FOR view_rec IN SELECT view_name, trigger_name FROM temp_triggers ORDER BY view_name LOOP
        RAISE NOTICE '  [%] INSTEAD OF trigger captured: %', view_rec.view_name, view_rec.trigger_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 7: Capture rules on all views (excluding _RETURN)
    -- --------------------------------------------------------
    INSERT INTO temp_rules (view_name, view_schema, rule_name, rule_def)
    SELECT
        c.relname,
        n.nspname,
        r.rulename,
        pg_get_ruledef(r.oid, true)
    FROM temp_view_ddl    v
    JOIN temp_schema_oids so ON so.schema_name = v.view_schema
    JOIN pg_class         c  ON c.relname      = v.view_name
                             AND c.relnamespace = so.schema_oid
    JOIN pg_namespace     n  ON n.oid           = c.relnamespace
    JOIN pg_rewrite       r  ON r.ev_class      = c.oid
    WHERE r.rulename != '_RETURN';  -- exclude the internal view SELECT rule

    FOR view_rec IN SELECT view_name, rule_name FROM temp_rules ORDER BY view_name LOOP
        RAISE NOTICE '  [%] Rule captured: %', view_rec.view_name, view_rec.rule_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 8: Capture RLS policies on all views
    -- --------------------------------------------------------
    INSERT INTO temp_rls_policies (view_name, view_schema, policy_name, policy_def)
    SELECT
        c.relname,
        n.nspname,
        p.polname,
        -- Reconstruct CREATE POLICY statement from pg_policy
        format(
            'CREATE POLICY %I ON %I.%I AS %s FOR %s TO %s%s%s;',
            p.polname,
            n.nspname,
            c.relname,
            CASE p.polpermissive WHEN TRUE THEN 'PERMISSIVE' ELSE 'RESTRICTIVE' END,
            CASE p.polcmd
                WHEN 'r' THEN 'SELECT'
                WHEN 'a' THEN 'INSERT'
                WHEN 'w' THEN 'UPDATE'
                WHEN 'd' THEN 'DELETE'
                ELSE 'ALL'
            END,
            COALESCE(
                (SELECT string_agg(pg_get_userbyid(r), ', ')
                 FROM unnest(p.polroles) AS r
                 WHERE r != 0),
                'PUBLIC'
            ),
            CASE WHEN p.polqual IS NOT NULL
                 THEN ' USING (' || pg_get_expr(p.polqual, c.oid) || ')'
                 ELSE '' END,
            CASE WHEN p.polwithcheck IS NOT NULL
                 THEN ' WITH CHECK (' || pg_get_expr(p.polwithcheck, c.oid) || ')'
                 ELSE '' END
        )
    FROM temp_view_ddl    v
    JOIN temp_schema_oids so ON so.schema_name = v.view_schema
    JOIN pg_class         c  ON c.relname      = v.view_name
                             AND c.relnamespace = so.schema_oid
    JOIN pg_namespace     n  ON n.oid           = c.relnamespace
    JOIN pg_policy        p  ON p.polrelid      = c.oid;

    FOR view_rec IN SELECT view_name, policy_name FROM temp_rls_policies ORDER BY view_name LOOP
        RAISE NOTICE '  [%] RLS policy captured: %', view_rec.view_name, view_rec.policy_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 9: Discover FUNCTIONS & PROCEDURES
    --         Direct (on target view) + transitive (via dependents)
    --         Batched — no per-view loop
    -- --------------------------------------------------------
    INSERT INTO temp_func_ddl (func_oid, func_name, func_schema, func_kind, func_owner, func_def, func_args)
    SELECT DISTINCT ON (p.oid)
        p.oid, p.proname, n.nspname, p.prokind::TEXT,
        pg_get_userbyid(p.proowner),
        pg_get_functiondef(p.oid),
        pg_get_function_identity_arguments(p.oid)
    FROM temp_view_ddl    v
    JOIN temp_schema_oids so ON so.schema_name = v.view_schema
    JOIN pg_class         vc ON vc.relname      = v.view_name
                             AND vc.relnamespace = so.schema_oid
    JOIN pg_depend        d  ON d.refobjid      = vc.oid
    JOIN pg_proc          p  ON p.oid           = d.objid
    JOIN pg_namespace     n  ON n.oid           = p.pronamespace
    WHERE d.deptype  = 'n'
      AND p.prokind  IN ('f', 'p');

    FOR func_rec IN SELECT func_name, func_schema, func_kind, func_owner FROM temp_func_ddl ORDER BY func_name LOOP
        RAISE NOTICE '  [%] %.% (owner: %)',
            CASE func_rec.func_kind WHEN 'p' THEN 'PROCEDURE' ELSE 'FUNCTION' END,
            func_rec.func_schema, func_rec.func_name, func_rec.func_owner;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 10: Capture TABLE-LEVEL grants — BATCHED across all views
    -- --------------------------------------------------------
    INSERT INTO temp_view_grants (view_name, grant_stmt, grant_level)
    SELECT
        v.view_name,
        format(
            'GRANT %s ON %s TO %I %s;',
            privs.privileges,
            quote_ident(v.view_schema) || '.' || quote_ident(v.view_name),
            privs.grantee,
            CASE WHEN privs.is_grantable THEN 'WITH GRANT OPTION' ELSE '' END
        ),
        'TABLE'
    FROM temp_view_ddl v
    JOIN LATERAL (
        WITH acl_entries AS (
            SELECT
                ace.grantee        AS grantee_oid,
                ace.is_grantable   AS is_grantable,
                ace.privilege_type AS privilege_type
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace,
            LATERAL aclexplode(c.relacl) AS ace
            WHERE c.relname  = v.view_name
              AND n.nspname  = v.view_schema
              AND c.relacl   IS NOT NULL
        )
        SELECT
            CASE WHEN grantee_oid = 0 THEN 'PUBLIC'
                 ELSE pg_get_userbyid(grantee_oid) END AS grantee,
            is_grantable,
            string_agg(privilege_type, ', ')           AS privileges
        FROM acl_entries
        -- Include PUBLIC (grantee_oid = 0) this time
        WHERE pg_get_userbyid(grantee_oid) != current_user
           OR grantee_oid = 0
        GROUP BY grantee_oid, is_grantable
    ) privs ON TRUE;

    -- --------------------------------------------------------
    -- STEP 11: Capture COLUMN-LEVEL grants — BATCHED across all views
    -- --------------------------------------------------------
    INSERT INTO temp_view_grants (view_name, grant_stmt, grant_level)
    SELECT
        v.view_name,
        format(
            'GRANT %s (%s) ON %s TO %I %s;',
            col_privs.privileges,
            col_privs.col_name,
            quote_ident(v.view_schema) || '.' || quote_ident(v.view_name),
            col_privs.grantee,
            CASE WHEN col_privs.is_grantable THEN 'WITH GRANT OPTION' ELSE '' END
        ),
        'COLUMN'
    FROM temp_view_ddl v
    JOIN LATERAL (
        SELECT
            a.attname                                        AS col_name,
            CASE WHEN ace.grantee = 0 THEN 'PUBLIC'
                 ELSE pg_get_userbyid(ace.grantee) END      AS grantee,
            ace.is_grantable,
            string_agg(ace.privilege_type, ', ')            AS privileges
        FROM pg_class      c
        JOIN pg_namespace  n ON n.oid      = c.relnamespace
        JOIN pg_attribute  a ON a.attrelid = c.oid
                            AND a.attnum   > 0
                            AND NOT a.attisdropped,
        LATERAL aclexplode(a.attacl) AS ace
        WHERE c.relname   = v.view_name
          AND n.nspname   = v.view_schema
          AND a.attacl    IS NOT NULL
          AND (ace.grantee = 0 OR pg_get_userbyid(ace.grantee) != current_user)
        GROUP BY a.attname, ace.grantee, ace.is_grantable
    ) col_privs ON TRUE;

    -- Log all captured grants
    FOR view_rec IN
        SELECT view_name, grant_stmt, grant_level
        FROM temp_view_grants ORDER BY view_name, grant_level DESC, grant_stmt
    LOOP
        RAISE NOTICE '  [%] [%] Grant captured: %',
            view_rec.view_name, view_rec.grant_level, view_rec.grant_stmt;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 12: Capture FUNCTION grants — BATCHED
    -- --------------------------------------------------------
    INSERT INTO temp_func_grants (func_name, grant_stmt)
    SELECT
        f.func_name,
        format(
            'GRANT %s ON %s %s TO %I %s;',
            fg.privileges,
            CASE f.func_kind WHEN 'p' THEN 'PROCEDURE' ELSE 'FUNCTION' END,
            quote_ident(f.func_schema) || '.' || quote_ident(f.func_name),
            fg.grantee,
            CASE WHEN fg.is_grantable THEN 'WITH GRANT OPTION' ELSE '' END
        )
    FROM temp_func_ddl f
    JOIN LATERAL (
        WITH acl_entries AS (
            SELECT
                ace.grantee        AS grantee_oid,
                ace.is_grantable   AS is_grantable,
                ace.privilege_type AS privilege_type
            FROM pg_proc p,
            LATERAL aclexplode(p.proacl) AS ace
            WHERE p.oid = f.func_oid AND p.proacl IS NOT NULL
        )
        SELECT
            CASE WHEN grantee_oid = 0 THEN 'PUBLIC'
                 ELSE pg_get_userbyid(grantee_oid) END AS grantee,
            is_grantable,
            string_agg(privilege_type, ', ')           AS privileges
        FROM acl_entries
        WHERE grantee_oid = 0 OR pg_get_userbyid(grantee_oid) != current_user
        GROUP BY grantee_oid, is_grantable
    ) fg ON TRUE;

    FOR func_rec IN SELECT func_name, grant_stmt FROM temp_func_grants ORDER BY func_name LOOP
        RAISE NOTICE '  [%] Function grant captured: %', func_rec.func_name, func_rec.grant_stmt;
    END LOOP;

    -- --------------------------------------------------------
    -- DRY RUN stops here
    -- --------------------------------------------------------
    IF dry_run_in THEN
        RAISE NOTICE '[DRY RUN] No changes made. Set dry_run_in => FALSE to execute.';
        RETURN;
    END IF;

    -- --------------------------------------------------------
    -- STEP 13: Drop functions & procedures
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
    -- STEP 14: Drop all views + matviews in REVERSE topo order
    --          (deepest dependents first, target view last)
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
    -- STEP 15: Recreate target view with NEW definition
    --          Restore security options from reloptions
    -- --------------------------------------------------------
    EXECUTE format(
        'CREATE VIEW %s%s AS %s',
        full_view_name,
        CASE WHEN view_security_opt IS NOT NULL
             THEN ' WITH (' || view_security_opt || ')'
             ELSE '' END,
        new_query_in
    );
    EXECUTE format('ALTER VIEW %s OWNER TO %I;', full_view_name, target_owner);

    IF target_comment IS NOT NULL THEN
        EXECUTE format('COMMENT ON VIEW %s IS %L;', full_view_name, target_comment);
        RAISE NOTICE '  Comment restored on target view.';
    END IF;

    RAISE NOTICE 'Recreated target view: % with new definition (owner: %)',
        full_view_name, target_owner;

    -- --------------------------------------------------------
    -- STEP 16: Recreate dependent views + matviews in topo order
    --          Restore security options per view
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, view_schema, view_def, view_owner, view_comment, view_kind, reloptions
        FROM temp_view_ddl
        WHERE is_target = FALSE
        ORDER BY topo_level ASC, view_name
    LOOP
        full_obj_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);

        -- Extract security options for this dependent view
        SELECT string_agg(opt, ', ')
        INTO view_security_opt
        FROM unnest(view_rec.reloptions) AS opt
        WHERE opt ILIKE 'security_%';

        IF view_rec.view_kind = 'm' THEN
            EXECUTE format('CREATE MATERIALIZED VIEW %s AS %s;', full_obj_name, view_rec.view_def);
            EXECUTE format('ALTER MATERIALIZED VIEW %s OWNER TO %I;', full_obj_name, view_rec.view_owner);
            RAISE NOTICE 'Recreated materialized view: % (owner: %)', full_obj_name, view_rec.view_owner;
        ELSE
            EXECUTE format(
                'CREATE VIEW %s%s AS %s',
                full_obj_name,
                CASE WHEN view_security_opt IS NOT NULL
                     THEN ' WITH (' || view_security_opt || ')'
                     ELSE '' END,
                view_rec.view_def
            );
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
    -- STEP 17: Recreate matview indexes
    -- --------------------------------------------------------
    FOR idx_rec IN SELECT view_name, view_schema, index_name, index_def FROM temp_matview_indexes ORDER BY view_name
    LOOP
        EXECUTE idx_rec.index_def;
        RAISE NOTICE '  [%] Index recreated: %', idx_rec.view_name, idx_rec.index_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 18: Refresh materialized views (shallowest first)
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, view_schema FROM temp_view_ddl
        WHERE view_kind = 'm'
        ORDER BY topo_level ASC, view_name
    LOOP
        full_obj_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);
        EXECUTE format('REFRESH MATERIALIZED VIEW %s;', full_obj_name);
        RAISE NOTICE 'Refreshed materialized view: %', full_obj_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 19: Recreate RLS policies
    -- --------------------------------------------------------
    FOR view_rec IN SELECT view_name, view_schema, policy_name, policy_def FROM temp_rls_policies ORDER BY view_name
    LOOP
        full_obj_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);
        -- Enable RLS on the view first if it had policies
        EXECUTE format('ALTER VIEW %s ENABLE ROW LEVEL SECURITY;', full_obj_name);
        EXECUTE view_rec.policy_def;
        RAISE NOTICE '  [%] RLS policy recreated: %', view_rec.view_name, view_rec.policy_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 20: Recreate INSTEAD OF triggers
    -- --------------------------------------------------------
    FOR view_rec IN SELECT view_name, trigger_name, trigger_def FROM temp_triggers ORDER BY view_name
    LOOP
        EXECUTE view_rec.trigger_def;
        RAISE NOTICE '  [%] Trigger recreated: %', view_rec.view_name, view_rec.trigger_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 21: Recreate rules
    -- --------------------------------------------------------
    FOR view_rec IN SELECT view_name, rule_name, rule_def FROM temp_rules ORDER BY view_name
    LOOP
        EXECUTE view_rec.rule_def;
        RAISE NOTICE '  [%] Rule recreated: %', view_rec.view_name, view_rec.rule_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 22: Recreate functions & procedures
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
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 23: Reapply all grants — TABLE first, then COLUMN
    -- --------------------------------------------------------
    FOR view_rec IN
        SELECT view_name, grant_stmt FROM temp_view_grants
        ORDER BY view_name, grant_level DESC, grant_stmt
    LOOP
        EXECUTE view_rec.grant_stmt;
        RAISE NOTICE '  [%] Reapplied grant: %', view_rec.view_name, view_rec.grant_stmt;
    END LOOP;

    FOR func_rec IN SELECT func_name, grant_stmt FROM temp_func_grants ORDER BY func_name, grant_stmt
    LOOP
        EXECUTE func_rec.grant_stmt;
        RAISE NOTICE '  [%] Reapplied function grant: %', func_rec.func_name, func_rec.grant_stmt;
    END LOOP;

    RAISE NOTICE '== safe_replace_view complete for: % ==', full_view_name;
END;
$$;