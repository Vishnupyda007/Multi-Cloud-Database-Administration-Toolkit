DO $$ 
DECLARE 
    r record;
BEGIN 
    -- Change 'public' to your schema name and 'my_user' to your role
    FOR r IN 
        SELECT typname 
        FROM pg_type t 
        JOIN pg_namespace n ON n.oid = t.typnamespace 
        WHERE n.nspname = 'public' 
          AND t.typtype IN ('e', 'c', 'd') -- e=enum, c=composite, d=domain
    LOOP 
        EXECUTE 'GRANT USAGE ON TYPE public.' || quote_ident(r.typname) || ' TO "db_datareader"';
    END LOOP; 
END $$;




---------------------------OR---------------------------------------


DO $$ 
DECLARE 
    r record;
BEGIN 
    FOR r IN 
        -- Regular user-defined types in schema
        SELECT n.nspname, t.typname 
        FROM pg_type t 
        JOIN pg_namespace n ON n.oid = t.typnamespace 
        WHERE n.nspname = 'public' 
          AND t.typtype IN ('e', 'c', 'd')  -- e=enum, c=composite, d=domain
		  AND t.typcategory != 'A'  --no array types

        UNION

        -- Extension-related types (across all schemas)
        SELECT DISTINCT n.nspname, t.typname
        FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        JOIN pg_depend d ON d.objid = t.oid
        JOIN pg_extension e ON e.oid = d.refobjid
        WHERE d.deptype = 'e'              -- 'e' = installed by extension
          AND t.typtype IN ('e', 'c', 'd', 'b')  -- added 'b' for base types from extensions
          AND t.typcategory != 'A'  
    LOOP 
        EXECUTE 'GRANT USAGE ON TYPE ' 
              || quote_ident(r.nspname) || '.' 
              || quote_ident(r.typname) 
              || ' TO "db_datareader"';
    END LOOP; 
END $$;




-------
ALTER DEFAULT PRIVILEGES FOR ROLE "prodgke-devops-serviceacc@cb0228600a-citprod-gc.iam","proddb-devops-serviceacc@cb0228600a-citprod-gc.iam"
in schema public
GRANT USAGE ON TYPES TO db_datareader;