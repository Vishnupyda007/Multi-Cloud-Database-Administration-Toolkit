DO $$

DECLARE

    v_ddl TEXT;

BEGIN

    FOR v_ddl IN

        SELECT

            'CREATE TABLE IF NOT EXISTS ' || quote_ident(c.table_schema) || '.' || quote_ident(c.table_name) || E'\n(\n' ||

            string_agg(

                '    ' || quote_ident(c.column_name) || ' ' ||

                CASE

                    WHEN c.data_type LIKE '%timestamp%' THEN

                        'timestamp(' || CASE WHEN pa.atttypmod > 0 THEN pa.atttypmod::text ELSE '6' END || ') without time zone'

                    WHEN c.character_maximum_length IS NOT NULL

                        THEN c.data_type || '(' || c.character_maximum_length || ')'

                    WHEN c.data_type IN ('integer','bigint','smallint','boolean','text','date')

                        THEN c.data_type

                    WHEN c.numeric_precision IS NOT NULL AND c.numeric_scale IS NOT NULL

                        THEN c.data_type || '(' || c.numeric_precision || ',' || c.numeric_scale || ')'

                    ELSE c.data_type

                END ||

                CASE

                    WHEN c.column_default IS NOT NULL

                        THEN ' DEFAULT ' || c.column_default

                    ELSE ''

                END ||

                CASE

                    WHEN c.is_nullable = 'NO' THEN ' NOT NULL'

                    ELSE ''

                END,

                E',\n' ORDER BY c.ordinal_position

            ) ||

            COALESCE(

                E',\n    CONSTRAINT ' || quote_ident(tc.constraint_name) ||

                ' PRIMARY KEY (' ||

                (

                    SELECT string_agg(quote_ident(kcu2.column_name), ', '

                           ORDER BY kcu2.ordinal_position)

                    FROM information_schema.key_column_usage kcu2

                    WHERE kcu2.constraint_name = tc.constraint_name

                      AND kcu2.table_schema = c.table_schema

                      AND kcu2.table_name = c.table_name

                ) || ')',

                ''

            ) ||

            E'\n);'

        FROM information_schema.columns c

        -- Join to get timestamp precision

        JOIN pg_class pc

            ON pc.relname = c.table_name

        JOIN pg_namespace pn

            ON pn.oid = pc.relnamespace

            AND pn.nspname = c.table_schema

        JOIN pg_attribute pa

            ON pa.attrelid = pc.oid

            AND pa.attname = c.column_name

            AND pa.attnum > 0

        LEFT JOIN information_schema.table_constraints tc

            ON  tc.table_schema  = c.table_schema

            AND tc.table_name    = c.table_name

            AND tc.constraint_type = 'PRIMARY KEY'

        WHERE c.table_schema = 'public'

        AND c.table_name IN (

            'TGT_ESA_PS_CTPC_ARCTYP_TBL_STG_CURR',

            'TGT_ESA_PS_CTPC_PRJARC_MAP_STG_CURR',

            'TGT_HCM_PS_DEPT_TBL_STG_CURR',

            'TGT_HCM_PS_LOCATION_TBL_STG_CURR',

            'TGT_LM_VW_LOCATIONMASTER_STG_CURR',

            'TGT_RHMS_TBL_EDS_ROLEDATAILS_STG_CURR',

            'TGT_RHMS_TBL_EDS_ROLEMASTER_STG_CURR',

            'TGT_CENTRALREPOSITORY_JOB_REFERENCE_MIG',

            'TGT_ESA_PS_CTSPC_PRNT_CUST_STG_CURR'

        )

        GROUP BY c.table_schema, c.table_name, tc.constraint_name

        ORDER BY c.table_name

    LOOP

        RAISE NOTICE '%', v_ddl;

    END LOOP;

END;

$$;
 