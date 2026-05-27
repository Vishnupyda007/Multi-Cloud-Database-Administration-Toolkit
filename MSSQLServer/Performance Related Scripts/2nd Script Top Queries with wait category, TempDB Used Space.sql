
DECLARE 
    @interval_start_time DATETIME2 = DATEADD(HOUR, -24, SYSUTCDATETIME()),
    @interval_end_time   DATETIME2 = SYSUTCDATETIME(),
    @results_row_count   INT = 50;

WITH wait_stats AS
(
    SELECT
        ws.plan_id,
        ws.wait_category,
        ROUND(CONVERT(float, SUM(ws.total_query_wait_time_ms) 
             / SUM(ws.total_query_wait_time_ms / NULLIF(ws.avg_query_wait_time_ms,0))), 2) AS avg_query_wait_time,
        ROUND(CONVERT(float, SQRT(
             SUM(ws.stdev_query_wait_time_ms * ws.stdev_query_wait_time_ms 
                 * (ws.total_query_wait_time_ms / NULLIF(ws.avg_query_wait_time_ms,0)))
             / NULLIF(SUM(ws.total_query_wait_time_ms / NULLIF(ws.avg_query_wait_time_ms,0)),0)
        )), 2) AS stdev_query_wait_time,
        CAST(ROUND(SUM(ws.total_query_wait_time_ms / NULLIF(ws.avg_query_wait_time_ms,0)),0) AS BIGINT) AS count_executions,
        MAX(itvl.end_time) AS last_execution_time,
        MIN(itvl.start_time) AS first_execution_time
    FROM sys.query_store_wait_stats ws
    JOIN sys.query_store_runtime_stats_interval itvl 
        ON itvl.runtime_stats_interval_id = ws.runtime_stats_interval_id
    WHERE NOT (itvl.start_time > @interval_end_time OR itvl.end_time < @interval_start_time)
    GROUP BY ws.plan_id, ws.runtime_stats_interval_id, ws.wait_category
),
top_wait_stats AS
(
    SELECT 
        p.query_id,
        q.object_id,
        ISNULL(OBJECT_NAME(q.object_id),'') AS object_name,
        qt.query_sql_text,
        ROUND(CONVERT(float, SUM(ws.avg_query_wait_time * ws.count_executions)), 2) AS total_query_wait_time,
        MAX(ws.count_executions) AS count_executions,
        COUNT(DISTINCT p.plan_id) AS num_plans
    FROM wait_stats ws
    JOIN sys.query_store_plan p ON p.plan_id = ws.plan_id
    JOIN sys.query_store_query q ON q.query_id = p.query_id
    JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
    WHERE NOT (ws.first_execution_time > @interval_end_time OR ws.last_execution_time < @interval_start_time)
    GROUP BY p.query_id, qt.query_sql_text, q.object_id
),
top_other_stats AS
(
    SELECT 
        p.query_id,
        q.object_id,
        ISNULL(OBJECT_NAME(q.object_id),'') AS object_name,
        qt.query_sql_text,
        ROUND(CONVERT(float, SUM(rs.avg_duration * rs.count_executions)) * 0.001, 2) AS total_duration,
        ROUND(CONVERT(float, SUM(rs.avg_cpu_time * rs.count_executions)) * 0.001, 2) AS total_cpu_time,
        ROUND(CONVERT(float, SUM(rs.avg_logical_io_reads * rs.count_executions)) * 8, 2) AS total_logical_io_reads,
        ROUND(CONVERT(float, SUM(rs.avg_logical_io_writes * rs.count_executions)) * 8, 2) AS total_logical_io_writes,
        ROUND(CONVERT(float, SUM(rs.avg_physical_io_reads * rs.count_executions)) * 8, 2) AS total_physical_io_reads,
        ROUND(CONVERT(float, SUM(rs.avg_clr_time * rs.count_executions)) * 0.001, 2) AS total_clr_time,
        ROUND(CONVERT(float, SUM(rs.avg_dop * rs.count_executions)) * 1, 0) AS total_dop,
        ROUND(CONVERT(float, SUM(rs.avg_query_max_used_memory * rs.count_executions)) * 8, 2) AS total_query_max_used_memory,
        ROUND(CONVERT(float, SUM(rs.avg_rowcount * rs.count_executions)) * 1, 0) AS total_rowcount,
        ROUND(CONVERT(float, SUM(rs.avg_log_bytes_used * rs.count_executions)) * 0.0009765625, 2) AS total_log_bytes_used,
        ROUND(CONVERT(float, SUM(rs.avg_tempdb_space_used * rs.count_executions)) * 8, 2) AS total_tempdb_space_used,
        SUM(rs.count_executions) AS count_executions,
        COUNT(DISTINCT p.plan_id) AS num_plans
    FROM sys.query_store_runtime_stats rs
    JOIN sys.query_store_plan p ON p.plan_id = rs.plan_id
    JOIN sys.query_store_query q ON q.query_id = p.query_id
    JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
    WHERE NOT (rs.first_execution_time > @interval_end_time OR rs.last_execution_time < @interval_start_time)
    GROUP BY p.query_id, qt.query_sql_text, q.object_id
)
SELECT TOP (@results_row_count)
    A.query_id,
    A.object_id,
    A.object_name,
    A.query_sql_text,
    A.total_duration,
    A.total_cpu_time,
    A.total_logical_io_reads,
    A.total_logical_io_writes,
    A.total_physical_io_reads,
    A.total_clr_time,
    A.total_dop,
    A.total_query_max_used_memory,
    A.total_rowcount,
    A.total_log_bytes_used,
    A.total_tempdb_space_used,
    ISNULL(B.total_query_wait_time, 0) AS total_query_wait_time,
    A.count_executions,
    A.num_plans
FROM top_other_stats A
LEFT JOIN top_wait_stats B 
  ON A.query_id = B.query_id 
 AND A.query_sql_text = B.query_sql_text 
 AND A.object_id = B.object_id
WHERE A.num_plans >= 1
ORDER BY total_duration DESC;
