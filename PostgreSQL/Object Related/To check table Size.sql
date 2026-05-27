Script 2: Detailed Size in GB and MB:

SELECT
    schemaname AS "Schema",
    tablename AS "Table",
    ROUND(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename)) / 1024.0 / 1024.0, 2) AS "Size (MB)",
    ROUND(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename)) / 1024.0 / 1024.0 / 1024.0, 2) AS "Size (GB)"
FROM
    pg_catalog.pg_tables
WHERE
    schemaname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY
    pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename)) DESC;



Script 3: Comprehensive Breakdown (Table vs. Index Size)

SELECT
    n.nspname AS "Schema",
    c.relname AS "Table",
    pg_size_pretty(pg_total_relation_size(c.oid)) AS "Total Size",
    pg_size_pretty(pg_relation_size(c.oid)) AS "Table Data",
    pg_size_pretty(pg_indexes_size(c.oid)) AS "Indexes"
FROM
    pg_class c
LEFT JOIN
    pg_namespace n ON (n.oid = c.relnamespace)
WHERE
    c.relkind = 'r' -- 'r' = ordinary table
    AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY
    pg_total_relation_size(c.oid) DESC;


What it does:

pg_total_relation_size: The combined size of everything.

pg_relation_size: The size of just the table's data (the "heap").

pg_indexes_size: The combined size of all indexes attached to the table.

This query uses pg_class, which is the fundamental catalog for database objects, making it very efficient.



Script 1: The Simple Human-Readable Version

SELECT
    schemaname AS "Schema",
    tablename AS "Table",
    pg_size_pretty(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename))) AS "Total Size"
FROM
    pg_catalog.pg_tables
WHERE
    schemaname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
ORDER BY
    pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename)) DESC;
