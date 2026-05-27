DO $$
DECLARE
    /************************************************************
     *                  CONFIGURATION VARIABLES                  *
     ************************************************************/

    -- 1. List the schemas you want to EXCLUDE from the ownership transfer.
    --    Common schemas to exclude are 'public', 'pg_catalog', etc.
    --    Example: ARRAY['public', 'shared_schemas']
    schemas_to_exclude TEXT[] := ARRAY['public','DBAdmin','google_vacuum_mgmt'];

    -- 2. Set the new owner for all other schemas.
    new_owner_role      TEXT     := 'OneC_4671';

    /************************************************************
     *                      SCRIPT LOGIC                      *
     *          (No changes needed below this line)           *
     ************************************************************/
    
    sch              TEXT;
    object_record    RECORD;
    command          TEXT;

BEGIN
    -- Check if the new owner role exists
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = new_owner_role) THEN
        RAISE EXCEPTION 'Target role "%" does not exist. Please create the role before running this script.', new_owner_role;
    END IF;

    -- Loop through each user-created schema in the database
    FOR sch IN
        SELECT schema_name
        FROM information_schema.schemata
        WHERE schema_name <> 'information_schema'
          AND schema_name NOT LIKE 'pg_%' -- Exclude system schemas
    LOOP
        -- Check if the current schema is in the exclusion list
        IF sch = ANY(schemas_to_exclude) THEN
            RAISE NOTICE '-------------------------------------------------------------------';
            RAISE NOTICE 'Skipping schema "%" because it is in the exclusion list.', sch;
            CONTINUE; -- Skip to the next schema in the loop
        END IF;

        RAISE NOTICE '-------------------------------------------------------------------';
        RAISE NOTICE 'Processing schema: %', sch;
        RAISE NOTICE '-------------------------------------------------------------------';

        -- 1. Change the ownership of the schema itself
        RAISE NOTICE 'Changing owner of schema "%" to "%"', sch, new_owner_role;
        EXECUTE format('ALTER SCHEMA %I OWNER TO %I', sch, new_owner_role);

        -- 2. Change ownership of all TABLES, VIEWS, and MATERIALIZED VIEWS in the schema
        FOR object_record IN
            SELECT table_name FROM information_schema.tables WHERE table_schema = sch
        LOOP
            command := format('ALTER TABLE %I.%I OWNER TO %I', sch, object_record.table_name, new_owner_role);
            RAISE NOTICE '  -> %', command;
            EXECUTE command;
        END LOOP;
        
        -- 3. Change ownership of all SEQUENCES in the schema
        FOR object_record IN
            SELECT sequence_name FROM information_schema.sequences WHERE sequence_schema = sch
        LOOP
            command := format('ALTER SEQUENCE %I.%I OWNER TO %I', sch, object_record.sequence_name, new_owner_role);
            RAISE NOTICE '  -> %', command;
            EXECUTE command;
        END LOOP;

        -- 4. Change ownership of all FUNCTIONS and PROCEDURES (Routines) in the schema
        FOR object_record IN
            SELECT p.proname AS routine_name, pg_get_function_identity_arguments(p.oid) AS routine_args, p.prokind
            FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = sch
        LOOP
            IF object_record.prokind = 'f' THEN -- It's a Function
                command := format('ALTER FUNCTION %I.%I(%s) OWNER TO %I', sch, object_record.routine_name, object_record.routine_args, new_owner_role);
            ELSIF object_record.prokind = 'p' THEN -- It's a Procedure
                command := format('ALTER PROCEDURE %I.%I(%s) OWNER TO %I', sch, object_record.routine_name, object_record.routine_args, new_owner_role);
            ELSE -- It might be an Aggregate, etc.
                command := format('ALTER AGGREGATE %I.%I(%s) OWNER TO %I', sch, object_record.routine_name, object_record.routine_args, new_owner_role);
            END IF;
            
            RAISE NOTICE '  -> %', command;
            EXECUTE command;
        END LOOP;

    END LOOP;

    RAISE NOTICE '-------------------------------------------------------------------';
    RAISE NOTICE 'Schema ownership transfer script completed successfully.';
    RAISE NOTICE '-------------------------------------------------------------------';
END $$;
