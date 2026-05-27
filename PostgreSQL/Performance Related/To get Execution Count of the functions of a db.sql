set time zone 'Asia/Kolkata';
WITH funcs_onec AS (
    SELECT *
    FROM dblink(
        'host=10.80.220.18 port=5432 dbname=OneC_4681 user=postgres password=Gcpadmin@2025',
        $$
        SELECT
            p.proname   AS object_name,
            n.nspname   AS schema_name,
            p.prokind   AS object_kind
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE p.prokind IN ('f','p')
          AND n.nspname NOT LIKE 'pg_%'
          AND n.nspname <> 'information_schema'
        $$
    ) AS f(
        object_name text,
        schema_name text,
        object_kind text
    )
),
stats_pg AS (
    SELECT
        d.datname,
        s.query,
        s.calls,
        s.total_exec_time,
        s.max_exec_time,
        s.stats_since
    FROM pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid
    WHERE d.datname = 'OneC_4681'
)
SELECT
    f.schema_name,
    f.object_name,
    CASE f.object_kind
        WHEN 'f' THEN 'FUNCTION'
        WHEN 'p' THEN 'PROCEDURE'
    END AS object_type,
    s.calls,
    round(s.total_exec_time::numeric, 2) AS total_exec_time_ms,
    round(s.max_exec_time::numeric, 2)   AS max_exec_time_ms,
    s.stats_since
FROM funcs_onec f
JOIN stats_pg s
  ON s.query ILIKE '%' || f.object_name || '%'
ORDER BY s.calls DESC;



-----------------------------------------------


SELECT
    n.nspname      AS schema_name,
    p.proname      AS function_name,
    f.calls,
    f.total_time,
    f.self_time
FROM pg_stat_user_functions f
JOIN pg_proc p       ON p.oid = f.funcid
JOIN pg_namespace n  ON n.oid = p.pronamespace
ORDER BY f.calls DESC;
``