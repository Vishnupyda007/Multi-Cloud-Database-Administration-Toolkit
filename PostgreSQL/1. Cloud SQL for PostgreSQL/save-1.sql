SELECT 'ACTIVE_SESSIONS' AS section,
       pid,
       usename AS username,
       datname AS database,
       client_addr AS client_ip,
       application_name,
       state,
       query,
       backend_start,
       now() - backend_start AS session_duration
FROM pg_stat_activity
--WHERE state = 'active'
ORDER BY session_duration DESC;



SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'template1'
  AND pid <> pg_backend_pid();


select * from pg_stat_activity limit 1




SELECT
    current_database(),
    n.nspname AS schemaname,
    c.relname AS tablename,
    ROUND((c.reltuples / (
        CASE
            WHEN c.relpages = 0 THEN 1
            ELSE c.relpages
        END
    ))::numeric, 2) AS tuples_per_page,
    ROUND(c.reltuples::numeric) AS row_count,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
    pg_size_pretty(pg_indexes_size(c.oid)) AS index_size,

    -- Bloat size calculation with the explicit ::bigint cast
    pg_size_pretty(
        (CASE
            WHEN c.relpages > 0 AND c.reltuples > 0 THEN
                (c.relpages - CEIL(c.reltuples / (
                    (c.relpages * 8192.0 - c.relpages * 24) /
                    (
                        SELECT avg_width
                        FROM pg_stats s
                        WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                        LIMIT 1
                    )
                ))) * 8192
            ELSE 0
        END)::bigint  -- <--- THE FIX IS HERE
    ) AS bloat_size,

    -- Bloat percentage calculation (this one is fine as it deals with percentages)
    ROUND(
        (CASE
            WHEN c.relpages > 0 AND c.reltuples > 0 THEN
                100 * (c.relpages - CEIL(c.reltuples / (
                    (c.relpages * 8192.0 - c.relpages * 24) /
                    (
                        SELECT avg_width
                        FROM pg_stats s
                        WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                        LIMIT 1
                    )
                ))) / c.relpages
            ELSE 0
        END)::numeric, 2
    ) AS bloat_percentage
FROM
    pg_class c
JOIN
    pg_namespace n ON n.oid = c.relnamespace
WHERE
    c.relkind = 'r'
    AND n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
ORDER BY
    -- The ORDER BY clause must also have the cast to sort correctly
    (CASE
        WHEN c.relpages > 0 AND c.reltuples > 0 THEN
            (c.relpages - CEIL(c.reltuples / (
                (c.relpages * 8192.0 - c.relpages * 24) /
                (
                    SELECT avg_width
                    FROM pg_stats s
                    WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                    LIMIT 1
                )
            ))) * 8192
        ELSE 0
    END) DESC;

