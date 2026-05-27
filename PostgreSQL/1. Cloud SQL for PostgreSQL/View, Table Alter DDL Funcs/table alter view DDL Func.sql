-- ============================================================
-- safe_alter_table
--
-- Pass a TABLE name and your ALTER statement(s).
-- The function will automatically:
--   1. Discover all DISTINCT views that depend on the table
--   2. Save each view's DDL and grants
--   3. Drop each dependent view (no CASCADE)
--   4. Run your ALTER TABLE statement(s)
--   5. Recreate each view with its original definition
--   6. Reapply all grants
--
-- Parameters:
--   table_name_in  : Name of the table being altered
--   alter_sql_in   : One or more ALTER TABLE statements
--                    (semicolon-separated if multiple)
-- ============================================================

CREATE OR REPLACE FUNCTION "DBAdmin".safe_alter_table_func(
    table_name_in  TEXT,
    alter_sql_in   TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    full_table_name  TEXT;
    full_view_name   TEXT;
    view_rec         RECORD;
    grant_record     RECORD;
    grant_statement  TEXT;
    alter_stmt       TEXT;
    view_count       INT;
    current_schema_oid OID;
BEGIN
    -- Resolve current schema OID once — avoids case sensitivity issues
    SELECT oid INTO current_schema_oid
    FROM pg_namespace
    WHERE nspname = current_schema();

    full_table_name := quote_ident(current_schema()) || '.' || quote_ident(table_name_in);
    RAISE NOTICE '== Starting safe_alter_table for table: % ==', full_table_name;

    -- --------------------------------------------------------
    -- STEP 1: Create temp tables to store view DDL and grants
    -- --------------------------------------------------------
    CREATE TEMPORARY TABLE temp_view_ddl (
        view_name   TEXT,
        view_schema TEXT,
        view_def    TEXT
    ) ON COMMIT DROP;

    CREATE TEMPORARY TABLE temp_view_grants (
        view_name   TEXT,
        grant_stmt  TEXT
    ) ON COMMIT DROP;

    -- --------------------------------------------------------
    -- STEP 2: Discover all DISTINCT views that depend on the table
    --         Uses OID-based lookup to avoid case sensitivity issues
    --         DISTINCT on (v.oid) prevents duplicate rows caused by
    --         pg_depend returning one row per column reference
    -- --------------------------------------------------------
    INSERT INTO temp_view_ddl (view_name, view_schema, view_def)
    SELECT DISTINCT ON (v.oid)
        v.relname                   AS view_name,
        n.nspname                   AS view_schema,
        pg_get_viewdef(v.oid, true) AS view_def
    FROM pg_depend d
    JOIN pg_rewrite    r ON r.oid       = d.objid
    JOIN pg_class      v ON v.oid       = r.ev_class
    JOIN pg_class      t ON t.oid       = d.refobjid
    JOIN pg_namespace  n ON n.oid       = v.relnamespace
    WHERE t.relname        = table_name_in        -- case-insensitive match via pg_class
      AND t.relnamespace   = current_schema_oid   -- OID match, no string comparison
      AND v.relkind        = 'v'                  -- views only
      AND v.oid           != t.oid                -- exclude self-references
      AND n.oid            = current_schema_oid;  -- same schema only

    SELECT COUNT(*) INTO view_count FROM temp_view_ddl;

    IF view_count = 0 THEN
        RAISE NOTICE 'No dependent views found on table %. Proceeding with ALTER only.', full_table_name;
    ELSE
        RAISE NOTICE 'Found % distinct dependent view(s):', view_count;
        FOR view_rec IN SELECT view_name FROM temp_view_ddl ORDER BY view_name LOOP
            RAISE NOTICE '  -> %', view_rec.view_name;
        END LOOP;
    END IF;

    -- --------------------------------------------------------
    -- STEP 3: Save grants for each dependent view
    -- --------------------------------------------------------
    FOR view_rec IN SELECT view_name, view_schema FROM temp_view_ddl ORDER BY view_name
    LOOP
        full_view_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);

        FOR grant_record IN
            -- Expand ACL entries once in a subquery, then aggregate and resolve names
            WITH acl_entries AS (
                SELECT
                    ace.grantee                      AS grantee_oid,
                    ace.grantor                      AS grantor_oid,
                    ace.is_grantable                 AS is_grantable,
                    ace.privilege_type               AS privilege_type
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
                END                                  AS grantee,
                pg_get_userbyid(grantor_oid)         AS grantor,
                is_grantable,
                string_agg(privilege_type, ', ')     AS privileges
            FROM acl_entries
            WHERE grantee_oid != 0   -- exclude PUBLIC; adjust if PUBLIC grants are needed
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

            RAISE NOTICE '  [%] Grant captured for "%": %', view_rec.view_name, grant_record.grantee, grant_statement;
        END LOOP;

        -- Log views that have no grants
        IF NOT FOUND THEN
            RAISE NOTICE '  [%] No grants found.', view_rec.view_name;
        END IF;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 4: Drop each dependent view (NO CASCADE)
    -- --------------------------------------------------------
    FOR view_rec IN SELECT view_name, view_schema FROM temp_view_ddl ORDER BY view_name
    LOOP
        full_view_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);
        EXECUTE format('DROP VIEW %s;', full_view_name);
        RAISE NOTICE 'Dropped view: %', full_view_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 5: Execute the ALTER TABLE statement(s)
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
    -- STEP 6: Recreate each view from saved DDL
    -- --------------------------------------------------------
    FOR view_rec IN SELECT view_name, view_schema, view_def FROM temp_view_ddl ORDER BY view_name
    LOOP
        full_view_name := quote_ident(view_rec.view_schema) || '.' || quote_ident(view_rec.view_name);
        EXECUTE format('CREATE VIEW %s AS %s', full_view_name, view_rec.view_def);
        RAISE NOTICE 'Recreated view: %', full_view_name;
    END LOOP;

    -- --------------------------------------------------------
    -- STEP 7: Reapply all grants
    -- --------------------------------------------------------
    FOR view_rec IN SELECT view_name, grant_stmt FROM temp_view_grants ORDER BY view_name, grant_stmt
    LOOP
        EXECUTE view_rec.grant_stmt;
        RAISE NOTICE '  [%] Reapplied grant: %', view_rec.view_name, view_rec.grant_stmt;
    END LOOP;

    RAISE NOTICE '== safe_alter_table complete for table: % ==', full_table_name;
END;
$$;


