DO $$
DECLARE
  -- >>>>>>>>>>>>>>>>>>>>>>> CONFIGURE <<<<<<<<<<<<<<<<<<<<<<
  new_owner     text    := 'npgke-devops-serviceacc@cb0104074a-citnonprod-gc.iam';  -- <<< target owner
  dry_run       boolean := false;                  -- true = print only
  -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  has_proc_kind boolean := current_setting('server_version_num')::int >= 110000;
  stmt          text;
  applied       int := 0;
BEGIN
  --------------------------------------------------------------------
  -- 1) TABLES / VIEWS / MATERIALIZED VIEWS / SEQUENCES
  --    - Skip foreign tables (FDW)
  --    - Skip objects owned by dblink/postgres_fdw extensions
  --------------------------------------------------------------------
  FOR stmt IN
    SELECT format(
      'ALTER %s %I.%I OWNER TO %I;',
      CASE c.relkind
        WHEN 'r' THEN 'TABLE'
        WHEN 'p' THEN 'TABLE'              -- partitioned table
        WHEN 'v' THEN 'VIEW'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
        WHEN 'S' THEN 'SEQUENCE'
      END,
      n.nspname, c.relname, new_owner
    )
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
--    WHERE n.nspname not in ('public', 'DBAdmin','pg_catalog','information_schema','google_vacuum_mgmt')
      AND c.relkind IN ('r','p','v','m','S')
      AND c.relkind <> 'f'  -- skip foreign tables (FDW) and c.relname not like '%google_db_%' and c.relname not like '%hypo_%'
      AND NOT EXISTS (       -- skip extension-owned
        SELECT 1
        FROM pg_depend d
        JOIN pg_extension e ON e.oid = d.refobjid
        WHERE d.classid = 'pg_class'::regclass
          AND d.objid   = c.oid
          AND d.deptype = 'e'
          AND e.extname IN ('dblink','postgres_fdw','citext','vector','pgcrypto','btree_gist') -- anyother extensions related as well
      )
  LOOP
    IF dry_run THEN
      RAISE NOTICE '%', stmt;
    ELSE
      EXECUTE stmt;
    END IF;
    applied := applied + 1;
  END LOOP;

  --------------------------------------------------------------------
  -- 2) FUNCTIONS in public (skip extension-owned)
  --    prokind = 'f' identifies functions
  --------------------------------------------------------------------
  FOR stmt IN
    SELECT format(
      'ALTER FUNCTION %I.%I(%s) OWNER TO %I;',
      n.nspname, p.proname,
      pg_get_function_identity_arguments(p.oid),
      new_owner
    )
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
--    WHERE n.nspname not in ('public', 'DBAdmin','pg_catalog','information_schema','google_vacuum_mgmt')
      AND p.prokind = 'f' and p.proname not like '%google_db_%' and p.proname not like '%hypo_%'
      AND NOT EXISTS (
        SELECT 1
        FROM pg_depend d
        JOIN pg_extension e ON e.oid = d.refobjid
        WHERE d.classid = 'pg_proc'::regclass
          AND d.objid   = p.oid
          AND d.deptype = 'e'
          AND e.extname IN ('dblink','postgres_fdw','citext','vector','pgcrypto','btree_gist')
      )
  LOOP
    IF dry_run THEN
      RAISE NOTICE '%', stmt;
    ELSE
      EXECUTE stmt;
    END IF;
    applied := applied + 1;
  END LOOP;

  --------------------------------------------------------------------
  -- 3) PROCEDURES in public (PG 11+; skip extension-owned)
  --    prokind = 'p' identifies procedures
  --------------------------------------------------------------------
  IF has_proc_kind THEN
    FOR stmt IN
      SELECT format(
        'ALTER PROCEDURE %I.%I(%s) OWNER TO %I;',
        n.nspname, p.proname,
        pg_get_function_identity_arguments(p.oid),
        new_owner
      )
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
--  WHERE n.nspname not in ('public', 'DBAdmin','pg_catalog','information_schema','google_vacuum_mgmt')

        AND p.prokind = 'p'
        AND NOT EXISTS (
          SELECT 1
          FROM pg_depend d
          JOIN pg_extension e ON e.oid = d.refobjid
          WHERE d.classid = 'pg_proc'::regclass
            AND d.objid   = p.oid
            AND d.deptype = 'e'
            AND e.extname IN ('dblink','postgres_fdw','citext','vector','pgcrypto','btree_gist')
        )
    LOOP
      IF dry_run THEN
        RAISE NOTICE '%', stmt;
      ELSE
        EXECUTE stmt;
      END IF;
      applied := applied + 1;
    END LOOP;
  ELSE
    RAISE NOTICE 'Skipping procedures: server_version_num < 110000';
  END IF;

  --------------------------------------------------------------------
  -- 4) TYPES in public
  --    - Alter only base/composite/domain/enum/range/multirange
  --    - Skip array types (typcategory = 'A' or names like '_int4', '_vector')
  --    - Skip composite row types that belong to tables (typtype='c' AND typrelid<>0)
  --    - Skip extension-owned
  --------------------------------------------------------------------
  FOR stmt IN
    SELECT format(
      'ALTER TYPE %I.%I OWNER TO %I;',
      n.nspname, t.typname, new_owner
    )
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
--    WHERE n.nspname not in ('public', 'DBAdmin','pg_catalog','information_schema','google_vacuum_mgmt')
      AND t.typtype IN ('b','c','d','e','r','m')  -- base, composite, domain, enum, range, multirange
      AND t.typcategory <> 'A'                    -- skip array categories
      AND t.typname NOT LIKE '\_%' ESCAPE '\'     -- skip names like _int4/_vector
      AND NOT (t.typtype = 'c' AND t.typrelid <> 0)  -- SKIP table row types
      AND NOT EXISTS (
        SELECT 1
        FROM pg_depend d
        JOIN pg_extension e ON e.oid = d.refobjid
        WHERE d.classid = 'pg_type'::regclass
          AND d.objid   = t.oid
          AND d.deptype = 'e'
          AND e.extname IN ('dblink','postgres_fdw','citext','vector','pgcrypto','btree_gist')
      )
  LOOP
    IF dry_run THEN
      RAISE NOTICE '%', stmt;
    ELSE
      EXECUTE stmt;
    END IF;
    applied := applied + 1;
  END LOOP;

  --------------------------------------------------------------------
  -- Summary
  --------------------------------------------------------------------
  RAISE NOTICE 'Completed. Statements processed: % (dry_run=%)', applied, dry_run;
END$$;





-----------------for table/views/mat views ------------------

DO $$
DECLARE
  new_owner text := 'your_new_owner_role';  -- <<< set target owner
  _sql      text;
BEGIN
  FOR _sql IN
    SELECT format(
      'ALTER %s %I.%I OWNER TO %I;',
      CASE c.relkind
        WHEN 'r' THEN 'TABLE'
        WHEN 'p' THEN 'TABLE'              -- partitioned table
        WHEN 'v' THEN 'VIEW'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
        WHEN 'S' THEN 'SEQUENCE'
      END,
      n.nspname, c.relname, new_owner
    )
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
--    WHERE n.nspname not in ('public', 'DBAdmin','pg_catalog','information_schema','google_vacuum_mgmt')
      AND c.relkind IN ('r','p','v','m','S')
      AND c.relkind <> 'f'  -- skip foreign tables (FDW)
      AND NOT EXISTS (       -- skip extension-owned objects (dblink/postgres_fdw)
        SELECT 1
        FROM pg_depend d
        JOIN pg_extension e ON e.oid = d.refobjid
        WHERE d.classid = 'pg_class'::regclass
          AND d.objid   = c.oid
          AND d.deptype = 'e'
          AND e.extname IN ('dblink','postgres_fdw')
      )
  LOOP
    EXECUTE _sql;
  END LOOP;
END$$;




-----------------Functions-------------------


DO $$
DECLARE
  new_owner text := 'your_new_owner_role';  -- <<< set target owner
  _sql      text;
BEGIN
  FOR _sql IN
    SELECT format(
      'ALTER FUNCTION %I.%I(%s) OWNER TO %I;',
      n.nspname, p.proname,
      pg_get_function_identity_arguments(p.oid),
      new_owner
    )
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'  -- functions
      AND NOT EXISTS (
        SELECT 1
        FROM pg_depend d
        JOIN pg_extension e ON e.oid = d.refobjid
        WHERE d.classid = 'pg_proc'::regclass
          AND d.objid   = p.oid
          AND d.deptype = 'e'
          AND e.extname IN ('dblink','postgres_fdw')
      )
  LOOP
    EXECUTE _sql;
  END LOOP;
END$$;






--------------------Procedures------------------


DO $$
DECLARE
  new_owner     text := 'your_new_owner_role';              -- <<< set target owner
  has_proc_kind boolean := current_setting('server_version_num')::int >= 110000;
  _sql          text;
BEGIN
  IF has_proc_kind THEN
    FOR _sql IN
      SELECT format(
        'ALTER PROCEDURE %I.%I(%s) OWNER TO %I;',
        n.nspname, p.proname,
        pg_get_function_identity_arguments(p.oid),
        new_owner
      )
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.prokind = 'p'  -- procedures (PG11+)
        AND NOT EXISTS (
          SELECT 1
          FROM pg_depend d
          JOIN pg_extension e ON e.oid = d.refobjid
          WHERE d.classid = 'pg_proc'::regclass
            AND d.objid   = p.oid
            AND d.deptype = 'e'
            AND e.extname IN ('dblink','postgres_fdw')
        )
    LOOP
      EXECUTE _sql;
    END LOOP;
  ELSE
    RAISE NOTICE 'Skipping procedures: server_version_num < 110000';
  END IF;
END$$;




---------------------Types--------------------

DO $$
DECLARE
  new_owner text := 'your_new_owner_role';  -- <<< set target owner
  _sql      text;
BEGIN
  -- We only alter "real" base/composite/domain/enum/range/multirange types.
  -- Array types (typcategory = 'A' or names like '_vector') are skipped,
  -- because altering the base type updates the array type automatically.
  FOR _sql IN
    SELECT format(
      'ALTER TYPE %I.%I OWNER TO %I;',
      n.nspname, t.typname, new_owner
    )
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typtype IN ('b','c','d','e','r','m')
      AND t.typcategory <> 'A'
      AND t.typname NOT LIKE '\_%' ESCAPE '\'
      AND NOT EXISTS (
        SELECT 1
        FROM pg_depend d
        JOIN pg_extension e ON e.oid = d.refobjid
        WHERE d.classid = 'pg_type'::regclass
          AND d.objid   = t.oid
          AND d.deptype = 'e'
          AND e.extname IN ('dblink','postgres_fdw')
      )
  LOOP
    EXECUTE _sql;
  END LOOP;
END$$;