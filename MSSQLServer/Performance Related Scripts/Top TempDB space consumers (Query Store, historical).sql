
/* ================= PARAMETERS ================= */
DECLARE 
    @interval_start_time DATETIME2 = DATEADD(HOUR, -24, SYSUTCDATETIME()), -- last 24h
    @interval_end_time   DATETIME2 = SYSUTCDATETIME(),
    @results_row_count   INT = 50,
    @min_execs           INT = 5,
    @include_internal    BIT = 0,   -- exclude internal by default
    @include_aborted     BIT = 0;   -- regular executions only by default

/* ================= TOP TEMPDB SPACE USED ================= */
SELECT TOP (@results_row_count)
    p.query_id,
    q.object_id,
    ISNULL(OBJECT_NAME(q.object_id),'') AS object_name,
    qt.query_sql_text,

    /* Totals over window (Query Store reports pages; convert to KB with *8) */
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_tempdb_space_used,0) * COALESCE(rs.count_executions,0))) * 8, 2) AS total_tempdb_space_used_kb,
    ROUND(CONVERT(float, MAX(COALESCE(rs.max_tempdb_space_used,0))) * 8, 2) AS max_tempdb_space_used_kb,
    /* Per-execution average over window */
    ROUND(CONVERT(float, 
          NULLIF(SUM(COALESCE(rs.avg_tempdb_space_used,0) * COALESCE(rs.count_executions,0)),0)
          / NULLIF(SUM(COALESCE(rs.count_executions,0)),0), 2) * 8, 2) AS avg_tempdb_space_used_kb_per_exec,

    /* Useful supporting metrics */
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_duration,0) * COALESCE(rs.count_executions,0))) * 0.001, 2) AS total_duration_sec,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_cpu_time,0) * COALESCE(rs.count_executions,0))) * 0.001, 2) AS total_cpu_time_sec,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_logical_io_reads,0) * COALESCE(rs.count_executions,0))) * 8, 2) AS total_logical_reads_kb,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_logical_io_writes,0) * COALESCE(rs.count_executions,0))) * 8, 2) AS total_logical_writes_kb,

    SUM(COALESCE(rs.count_executions,0)) AS count_executions,
    COUNT(DISTINCT p.plan_id)            AS num_plans
FROM sys.query_store_runtime_stats AS rs
JOIN sys.query_store_plan AS p   ON p.plan_id = rs.plan_id
JOIN sys.query_store_query AS q  ON q.query_id = p.query_id
JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_runtime_stats_interval AS itvl 
     ON itvl.runtime_stats_interval_id = rs.runtime_stats_interval_id
WHERE NOT (itvl.start_time > @interval_end_time OR itvl.end_time < @interval_start_time)
  AND (@include_internal = 1 OR q.is_internal_query = 0)
  AND (@include_aborted  = 1 OR rs.execution_type = 0)
GROUP BY p.query_id, q.object_id, qt.query_sql_text
HAVING SUM(COALESCE(rs.count_executions,0)) >= @min_execs
ORDER BY total_tempdb_space_used_kb DESC;
