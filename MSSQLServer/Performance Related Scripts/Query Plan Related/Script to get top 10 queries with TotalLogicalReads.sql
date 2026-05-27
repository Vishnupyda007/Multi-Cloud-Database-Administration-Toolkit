SELECT TOP 10

    qt.query_sql_text,

    q.query_id,

    SUM(rs.count_executions) AS TotalExecutions,

    SUM(rs.avg_logical_io_reads * rs.count_executions) AS TotalLogicalReads,

    AVG(rs.avg_logical_io_reads) AS AvgLogicalReads

FROM sys.query_store_runtime_stats AS rs

JOIN sys.query_store_plan AS p ON rs.plan_id = p.plan_id

JOIN sys.query_store_query AS q ON p.query_id = q.query_id

JOIN sys.query_store_query_text AS qt ON q.query_text_id = qt.query_text_id

WHERE rs.last_execution_time >= DATEADD(DAY, -30, GETUTCDATE())

GROUP BY qt.query_sql_text, q.query_id

ORDER BY TotalLogicalReads DESC;

 