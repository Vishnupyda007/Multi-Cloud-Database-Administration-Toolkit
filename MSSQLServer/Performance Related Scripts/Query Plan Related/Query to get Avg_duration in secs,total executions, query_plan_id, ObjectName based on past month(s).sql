----------------------best---------------------

DECLARE @MonthsBack INT = 1; -- Change to 1 for past 1 month
DECLARE @ObjectName NVARCHAR(128) = 'usp_GetUploaderValidRecord_BPSNSA'; -- Set to object name or leave NULL
DECLARE @QueryTextPattern NVARCHAR(MAX) =null; -- Set to part of the query text or leave NULL

SELECT 
    o.name AS object_name,
    qsqt.query_sql_text,
    qsp.plan_id AS query_plan_id,
	qsq.query_id as query_id,
    SUM(qsrs.count_executions) AS total_executions,
    SUM(qsrs.avg_duration * qsrs.count_executions) / 
        NULLIF(SUM(qsrs.count_executions), 0) / 1000000.0 AS avg_duration_seconds,
    MAX(qsrs.last_execution_time) AS last_execution_time
FROM 
    sys.query_store_query_text qsqt
JOIN 
    sys.query_store_query qsq ON qsqt.query_text_id = qsq.query_text_id
JOIN 
    sys.query_store_plan qsp ON qsq.query_id = qsp.query_id
JOIN 
    sys.query_store_runtime_stats qsrs ON qsp.plan_id = qsrs.plan_id
JOIN 
    sys.query_store_runtime_stats_interval qsrsi ON qsrs.runtime_stats_interval_id = qsrsi.runtime_stats_interval_id
LEFT JOIN 
    sys.objects o ON qsq.object_id = o.object_id
WHERE 
    qsrsi.start_time >= DATEADD(MONTH, -@MonthsBack, GETUTCDATE())
    AND (@ObjectName IS NULL OR o.name = @ObjectName)
    AND (@QueryTextPattern IS NULL OR qsqt.query_sql_text LIKE '%' + @QueryTextPattern + '%')
GROUP BY 
    o.name, qsq.query_id,qsqt.query_sql_text, qsp.plan_id
ORDER BY 
    last_execution_time desc, avg_duration_seconds DESC;




------------------------------------------------------


SELECT
    -- Key Performance Metrics
    qs.execution_count,
    (qs.total_elapsed_time / 1000000.0) / qs.execution_count AS avg_duration_seconds,
    (qs.total_worker_time / 1000000.0) / qs.execution_count AS avg_cpu_time_seconds,

    -- Query Text Identification
    SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1,
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(qt.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1) AS individual_query_text,

    -- Database and Object Information (from the query plan)
    DB_NAME(qp.dbid) AS database_name,
    OBJECT_SCHEMA_NAME(qp.objectid, qp.dbid) + '.' + OBJECT_NAME(qp.objectid, qp.dbid) AS object_name,

    -- Clickable Query Plan for Detailed Analysis
    qp.query_plan
FROM
    sys.dm_exec_query_stats AS qs
CROSS APPLY
    sys.dm_exec_sql_text(qs.sql_handle) AS qt
CROSS APPLY
    sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE
    -- Filter for queries with an average execution time greater than 2 seconds
    (qs.total_elapsed_time / 1000000.0) / qs.execution_count > 2 and DB_NAME(qp.dbid)='MSUTILITY'
ORDER BY
    -- Show the most expensive queries first
    avg_duration_seconds DESC;




------------------------------------------

-- =================================================================================
-- Find long-running queries within a specific database and timeframe
-- =================================================================================

-- Set the number of recent days to look back for query executions
DECLARE @LastNumberOfDays INT = 4;

-- =================================================================================

SELECT
    -- Core Performance Metrics
    qs.execution_count,
    (qs.total_elapsed_time / 1000000.0) / qs.execution_count AS avg_duration_seconds,
    (qs.total_worker_time / 1000000.0) / qs.execution_count AS avg_cpu_time_seconds,

    -- NEW: Query and Plan Identifiers
    qs.query_hash,
    qs.query_plan_hash,

    -- Query Text and Context
    SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1,
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(qt.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1) AS individual_query_text,

    -- Database and Object Information
    DB_NAME(qp.dbid) AS database_name,
    OBJECT_SCHEMA_NAME(qp.objectid, qp.dbid) + '.' + OBJECT_NAME(qp.objectid, qp.dbid) AS object_name,
    qs.last_execution_time,

    -- Clickable Query Plan for Detailed Analysis
    qp.query_plan
FROM
    sys.dm_exec_query_stats AS qs
CROSS APPLY
    sys.dm_exec_sql_text(qs.sql_handle) AS qt
CROSS APPLY
    sys.dm_exec_query_plan(qs.plan_handle) AS qp
WHERE
    -- 1. Filter for average execution time greater than 2 seconds
    (qs.total_elapsed_time / 1000000.0) / qs.execution_count > 2

    -- 2. Filter for the specific database you are interested in
    AND DB_NAME(qp.dbid) = 'MSUTILITY'

    -- 3. NEW: Filter for queries that have executed recently
    AND qs.last_execution_time >= DATEADD(day, -@LastNumberOfDays, GETDATE())
ORDER BY
    -- Show the most expensive queries first
    avg_duration_seconds DESC;



