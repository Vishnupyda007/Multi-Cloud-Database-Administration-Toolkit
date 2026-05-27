SELECT
    t.relname AS table_name,
    i.relname AS index_name,
    am.amname AS index_type,
    -- Full CREATE INDEX script
    'CREATE ' ||
    CASE WHEN ix.indisunique THEN 'UNIQUE ' ELSE '' END ||
    'INDEX ' || i.relname ||
    ' ON ' || n.nspname || '.' || t.relname ||
    ' USING ' || am.amname ||
    ' ( ' ||
    -- Key columns with sort order (only applicable for BTREE)
    (
        SELECT STRING_AGG(
            col_def,
            ', '
            ORDER BY key_ord
        )
        FROM (
            SELECT
                c.attname ||
                CASE
                    WHEN am.amname = 'btree' THEN
                        CASE WHEN ix.indoption[col_pos - 1] & 1 = 1 THEN ' DESC' ELSE ' ASC' END
                    ELSE ''
                END ||
                -- NULLS ordering (btree only)
                CASE
                    WHEN am.amname = 'btree' THEN
                        CASE WHEN ix.indoption[col_pos - 1] & 2 = 2 THEN ' NULLS FIRST' ELSE ' NULLS LAST' END
                    ELSE ''
                END AS col_def,
                col_pos AS key_ord
            FROM
                UNNEST(ix.indkey) WITH ORDINALITY AS u(attnum, col_pos)
                JOIN pg_attribute c
                    ON  c.attrelid = t.oid
                    AND c.attnum   = u.attnum
            WHERE
                u.attnum > 0  -- exclude included (INCLUDE clause) columns; for PG < 11 all are key cols
                -- For PG 11+ indnkeyatts distinguishes key vs included cols:
                AND col_pos <= ix.indnkeyatts
        ) key_cols
    ) ||
    ' )' ||
    -- INCLUDE columns (PostgreSQL 11+)
    COALESCE(
        (
            SELECT ' INCLUDE (' ||
                STRING_AGG(c.attname, ', ' ORDER BY col_pos) ||
            ')'
            FROM
                UNNEST(ix.indkey) WITH ORDINALITY AS u(attnum, col_pos)
                JOIN pg_attribute c
                    ON  c.attrelid = t.oid
                    AND c.attnum   = u.attnum
            WHERE
                u.attnum > 0
                AND col_pos > ix.indnkeyatts   -- only included columns
        ),
        ''
    ) ||
    -- Partial index WHERE clause
    COALESCE(' WHERE ' || pg_get_expr(ix.indpred, ix.indrelid), '') ||
    -- Storage parameters (WITH clause)
    COALESCE(
        (
            SELECT ' WITH (' || STRING_AGG(opt, ', ') || ')'
            FROM UNNEST(i.reloptions) AS opt
        ),
        ''
    ) ||
    -- Tablespace
    COALESCE(' TABLESPACE ' || ts.spcname, '') ||
    ';'
    AS create_index_script

FROM
    pg_index       ix
    JOIN pg_class  t   ON  t.oid = ix.indrelid
    JOIN pg_class  i   ON  i.oid = ix.indexrelid
    JOIN pg_am     am  ON  am.oid = i.relam
    JOIN pg_namespace n ON  n.oid = t.relnamespace
    LEFT JOIN pg_tablespace ts ON ts.oid = i.reltablespace

WHERE
    -- Exclude primary keys  (comment out to include them)
    ix.indisprimary = FALSE

    -- Exclude unique constraints created via CONSTRAINT syntax (comment to include)
    AND NOT EXISTS (
        SELECT 1 FROM pg_constraint con
        WHERE  con.conindid = ix.indexrelid
          AND  con.contype  = 'u'
    )

    -- Exclude system / catalog tables
    AND n.nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')

    -- Restrict to specific index types if needed (comment out to get ALL types)
    AND am.amname IN ('btree', 'gin', 'gist', 'brin', 'hash', 'spgist')

    -- Uncomment to filter by schema:
    -- AND n.nspname = 'public'

    -- Uncomment to filter by table:
    -- AND t.relname IN ('your_table1', 'your_table2')

    -- Uncomment to filter by specific index type:
    -- AND am.amname = 'gin'

ORDER BY
    n.nspname,a
    t.relname,
    i.relname;



---------


SELECT
    t.relname AS table_name,
    i.relname AS index_name,
    am.amname AS index_type,
    -- Full CREATE INDEX script
    'CREATE ' ||
    CASE WHEN ix.indisunique THEN 'UNIQUE ' ELSE '' END ||
    'INDEX ' || i.relname ||
    ' ON ' || n.nspname || '.' || t.relname ||
    ' USING ' || am.amname ||
    ' ( ' ||
    -- Key columns with sort order (only applicable for BTREE)
    (
        SELECT STRING_AGG(
            col_def,
            ', '
            ORDER BY key_ord
        )
        FROM (
            SELECT
                c.attname ||
                CASE
                    WHEN am.amname = 'btree' THEN
                        CASE WHEN ix.indoption[col_pos - 1] & 1 = 1 THEN ' DESC' ELSE ' ASC' END
                    ELSE ''
                END ||
                -- NULLS ordering (btree only)
                CASE
                    WHEN am.amname = 'btree' THEN
                        CASE WHEN ix.indoption[col_pos - 1] & 2 = 2 THEN ' NULLS FIRST' ELSE ' NULLS LAST' END
                    ELSE ''
                END AS col_def,
                col_pos AS key_ord
            FROM
                UNNEST(ix.indkey) WITH ORDINALITY AS u(attnum, col_pos)
                JOIN pg_attribute c
                    ON  c.attrelid = t.oid
                    AND c.attnum   = u.attnum
            WHERE
                u.attnum > 0  -- exclude included (INCLUDE clause) columns; for PG < 11 all are key cols
                -- For PG 11+ indnkeyatts distinguishes key vs included cols:
                AND col_pos <= ix.indnkeyatts
        ) key_cols
    ) ||
    ' )' ||
    -- INCLUDE columns (PostgreSQL 11+)
    COALESCE(
        (
            SELECT ' INCLUDE (' ||
                STRING_AGG(c.attname, ', ' ORDER BY col_pos) ||
            ')'
            FROM
                UNNEST(ix.indkey) WITH ORDINALITY AS u(attnum, col_pos)
                JOIN pg_attribute c
                    ON  c.attrelid = t.oid
                    AND c.attnum   = u.attnum
            WHERE
                u.attnum > 0
                AND col_pos > ix.indnkeyatts   -- only included columns
        ),
        ''
    ) ||
    -- Partial index WHERE clause
    COALESCE(' WHERE ' || pg_get_expr(ix.indpred, ix.indrelid), '') ||
    -- Storage parameters (WITH clause)
    COALESCE(
        (
            SELECT ' WITH (' || STRING_AGG(opt, ', ') || ')'
            FROM UNNEST(i.reloptions) AS opt
        ),
        ''
    ) ||
    -- Tablespace
    COALESCE(' TABLESPACE ' || ts.spcname, '') ||
    ';'
    AS create_index_script

FROM
    pg_index       ix
    JOIN pg_class  t   ON  t.oid = ix.indrelid
    JOIN pg_class  i   ON  i.oid = ix.indexrelid
    JOIN pg_am     am  ON  am.oid = i.relam
    JOIN pg_namespace n ON  n.oid = t.relnamespace
    LEFT JOIN pg_tablespace ts ON ts.oid = i.reltablespace

WHERE
    -- Exclude primary keys  (comment out to include them)
    --ix.indisprimary = true

    -- Exclude unique constraints created via CONSTRAINT syntax (comment to include)
     NOT EXISTS (
        SELECT 1 FROM pg_constraint con
        WHERE  con.conindid = ix.indexrelid
          AND  con.contype  = 'u'
    )

    -- Exclude system / catalog tables
    AND n.nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')

    -- Restrict to specific index types if needed (comment out to get ALL types)
    AND am.amname IN ('btree', 'gin', 'gist', 'brin', 'hash', 'spgist')
    -- Uncomment to filter by schema:
    -- AND n.nspname = 'public'

    -- Uncomment to filter by table:
    -- AND t.relname IN ('your_table1', 'your_table2')

    -- Uncomment to filter by specific index type:
    -- AND am.amname = 'gin'

ORDER BY
    n.nspname,
    t.relname,
    i.relname;
