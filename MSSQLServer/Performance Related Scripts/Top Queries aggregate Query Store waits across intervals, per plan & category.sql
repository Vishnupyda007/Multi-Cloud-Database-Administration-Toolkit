
/* ================= PARAMETERS ================= */
DECLARE 
    @interval_start_time DATETIME2 = DATEADD(HOUR, -24, SYSUTCDATETIME()),
    @interval_end_time   DATETIME2 = SYSUTCDATETIME(),
    @results_row_count   INT = 50,
    @min_execs           INT = 5,
    @include_internal    BIT = 0,   -- 0: exclude internal queries
    @include_aborted     BIT = 0;   -- 0: include regular executions only

/* ================= STAGING: WAIT STATS ================= */
/* Aggregate Query Store waits across intervals, per plan & category */
IF OBJECT_ID('tempdb..#wait_stats') IS NOT NULL DROP TABLE #wait_stats;
CREATE TABLE #wait_stats
(
    plan_id BIGINT NOT NULL,
    wait_category TINYINT NOT NULL,
    wait_category_desc NVARCHAR(128) NOT NULL,
    avg_query_wait_time FLOAT NULL,
    stdev_query_wait_time FLOAT NULL,
    count_executions BIGINT NOT NULL,
    first_execution_time DATETIME2 NOT NULL,
    last_execution_time DATETIME2 NOT NULL
);

INSERT INTO #wait_stats
SELECT
    ws.plan_id,
    ws.wait_category,
    ws.wait_category_desc,
    /* Weighted average across intervals: sum(total) / sum(total/avg) */
    ROUND(
      CONVERT(float, 
        COALESCE(SUM(ws.total_query_wait_time_ms),0)
        / NULLIF(COALESCE(SUM(ws.total_query_wait_time_ms / NULLIF(ws.avg_query_wait_time_ms,0)),0),0)
      ), 2
    ) AS avg_query_wait_time,
    /* Weighted stdev */
    ROUND(CONVERT(float, SQRT(
        COALESCE(SUM(
          COALESCE(ws.stdev_query_wait_time_ms,0) * COALESCE(ws.stdev_query_wait_time_ms,0)
          * COALESCE(ws.total_query_wait_time_ms / NULLIF(ws.avg_query_wait_time_ms,0),0)
        ),0)
        / NULLIF(COALESCE(SUM(ws.total_query_wait_time_ms / NULLIF(ws.avg_query_wait_time_ms,0)),0),0)
    )), 2) AS stdev_query_wait_time,
    CAST(ROUND(COALESCE(SUM(ws.total_query_wait_time_ms / NULLIF(ws.avg_query_wait_time_ms,0)),0),0) AS BIGINT) AS count_executions,
    MIN(itvl.start_time) AS first_execution_time,
    MAX(itvl.end_time)   AS last_execution_time
FROM sys.query_store_wait_stats AS ws
JOIN sys.query_store_runtime_stats_interval AS itvl 
  ON itvl.runtime_stats_interval_id = ws.runtime_stats_interval_id
WHERE NOT (itvl.start_time > @interval_end_time OR itvl.end_time < @interval_start_time)
  AND (@include_aborted = 1 OR ws.execution_type = 0) -- regular executions only by default
GROUP BY ws.plan_id, ws.wait_category, ws.wait_category_desc;

/* ================= PER-QUERY WAIT CATEGORY ================= */
IF OBJECT_ID('tempdb..#wait_by_query_category') IS NOT NULL DROP TABLE #wait_by_query_category;
CREATE TABLE #wait_by_query_category
(
    query_id BIGINT NOT NULL,
    object_id INT NULL,
    object_name SYSNAME NULL,
    query_sql_text NVARCHAR(MAX) NULL,
    wait_category TINYINT NOT NULL,
    wait_category_desc NVARCHAR(128) NOT NULL,
    total_wait_ms FLOAT NOT NULL,
    execs_with_wait BIGINT NOT NULL
);

INSERT INTO #wait_by_query_category
SELECT 
    p.query_id,
    q.object_id,
    ISNULL(OBJECT_NAME(q.object_id),'') AS object_name,
    qt.query_sql_text,
    ws.wait_category,
    ws.wait_category_desc,
    /* Total wait time per category: avg_wait * exec_count */
    ROUND(CONVERT(float, SUM(COALESCE(ws.avg_query_wait_time,0) * COALESCE(ws.count_executions,0))), 2) AS total_wait_ms,
    SUM(COALESCE(ws.count_executions,0)) AS execs_with_wait
FROM #wait_stats AS ws
JOIN sys.query_store_plan AS p ON p.plan_id = ws.plan_id
JOIN sys.query_store_query AS q ON q.query_id = p.query_id
JOIN sys.query_store_query_text AS qt ON q.query_text_id = qt.query_text_id
WHERE NOT (ws.first_execution_time > @interval_end_time OR ws.last_execution_time < @interval_start_time)
  AND (@include_internal = 1 OR q.is_internal_query = 0)
GROUP BY p.query_id, q.object_id, qt.query_sql_text, ws.wait_category, ws.wait_category_desc;

IF OBJECT_ID('tempdb..#wait_totals') IS NOT NULL DROP TABLE #wait_totals;
CREATE TABLE #wait_totals
(
    query_id BIGINT PRIMARY KEY,
    query_total_wait_ms FLOAT NOT NULL
);

INSERT INTO #wait_totals
SELECT query_id, SUM(total_wait_ms) AS query_total_wait_ms
FROM #wait_by_query_category
GROUP BY query_id;

IF OBJECT_ID('tempdb..#wait_breakdown') IS NOT NULL DROP TABLE #wait_breakdown;
CREATE TABLE #wait_breakdown
(
    query_id BIGINT NOT NULL,
    object_id INT NULL,
    object_name SYSNAME NULL,
    query_sql_text NVARCHAR(MAX) NULL,
    wait_category TINYINT NOT NULL,
    wait_category_desc NVARCHAR(128) NOT NULL,
    total_wait_ms FLOAT NOT NULL,
    query_total_wait_ms FLOAT NOT NULL,
    pct_of_query_waits FLOAT NOT NULL
);

INSERT INTO #wait_breakdown
SELECT 
    w.query_id,
    w.object_id,
    w.object_name,
    w.query_sql_text,
    w.wait_category,
    w.wait_category_desc,
    w.total_wait_ms,
    t.query_total_wait_ms,
    CASE WHEN t.query_total_wait_ms > 0 
         THEN ROUND(100.0 * w.total_wait_ms / t.query_total_wait_ms, 2)
         ELSE 0 END AS pct_of_query_waits
FROM #wait_by_query_category AS w
JOIN #wait_totals AS t ON t.query_id = w.query_id;

/* Top-3 waits per query using ranking */
IF OBJECT_ID('tempdb..#top3_waits') IS NOT NULL DROP TABLE #top3_waits;
CREATE TABLE #top3_waits
(
    query_id BIGINT NOT NULL PRIMARY KEY,
    top_wait_category_desc NVARCHAR(128) NULL,
    top_wait_ms FLOAT NULL,
    top_wait_pct FLOAT NULL,
    second_wait_category_desc NVARCHAR(128) NULL,
    second_wait_ms FLOAT NULL,
    second_wait_pct FLOAT NULL,
    third_wait_category_desc NVARCHAR(128) NULL,
    third_wait_ms FLOAT NULL,
    third_wait_pct FLOAT NULL
);

WITH ranked AS
(
    SELECT 
        wb.*,
        ROW_NUMBER() OVER (PARTITION BY wb.query_id ORDER BY wb.total_wait_ms DESC) AS rn
    FROM #wait_breakdown AS wb
)
INSERT INTO #top3_waits
SELECT 
    query_id,
    MAX(CASE WHEN rn = 1 THEN wait_category_desc END),
    MAX(CASE WHEN rn = 1 THEN total_wait_ms END),
    MAX(CASE WHEN rn = 1 THEN pct_of_query_waits END),

    MAX(CASE WHEN rn = 2 THEN wait_category_desc END),
    MAX(CASE WHEN rn = 2 THEN total_wait_ms END),
    MAX(CASE WHEN rn = 2 THEN pct_of_query_waits END),

    MAX(CASE WHEN rn = 3 THEN wait_category_desc END),
    MAX(CASE WHEN rn = 3 THEN total_wait_ms END),
    MAX(CASE WHEN rn = 3 THEN pct_of_query_waits END)
FROM ranked
GROUP BY query_id;

/* ================= STAGING: RUNTIME TOTALS ================= */
IF OBJECT_ID('tempdb..#top_other_stats') IS NOT NULL DROP TABLE #top_other_stats;
CREATE TABLE #top_other_stats
(
    query_id BIGINT NOT NULL PRIMARY KEY,
    object_id INT NULL,
    object_name SYSNAME NULL,
    query_sql_text NVARCHAR(MAX) NULL,

    total_duration_sec FLOAT NULL,
    total_cpu_time_sec FLOAT NULL,
    total_logical_io_reads_kb FLOAT NULL,
    total_logical_io_writes_kb FLOAT NULL,
    total_physical_io_reads_kb FLOAT NULL,
    total_clr_time_sec FLOAT NULL,
    total_dop FLOAT NULL,
    total_query_max_used_memory_kb FLOAT NULL,
    total_rowcount FLOAT NULL,
    total_log_bytes_used_mb FLOAT NULL,
    total_tempdb_space_used_kb FLOAT NULL,

    count_executions BIGINT NOT NULL,
    num_plans INT NOT NULL
);

INSERT INTO #top_other_stats
SELECT 
    p.query_id,
    q.object_id,
    ISNULL(OBJECT_NAME(q.object_id),'') AS object_name,
    qt.query_sql_text,

    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_duration,0)           * COALESCE(rs.count_executions,0))) * 0.001, 2) AS total_duration_sec,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_cpu_time,0)           * COALESCE(rs.count_executions,0))) * 0.001, 2) AS total_cpu_time_sec,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_logical_io_reads,0)   * COALESCE(rs.count_executions,0))) * 8, 2)    AS total_logical_io_reads_kb,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_logical_io_writes,0)  * COALESCE(rs.count_executions,0))) * 8, 2)    AS total_logical_io_writes_kb,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_physical_io_reads,0)  * COALESCE(rs.count_executions,0))) * 8, 2)    AS total_physical_io_reads_kb,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_clr_time,0)           * COALESCE(rs.count_executions,0))) * 0.001, 2)AS total_clr_time_sec,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_dop,0)                * COALESCE(rs.count_executions,0))), 0)        AS total_dop,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_query_max_used_memory,0) * COALESCE(rs.count_executions,0))) * 8, 2) AS total_query_max_used_memory_kb,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_rowcount,0)           * COALESCE(rs.count_executions,0))), 0)        AS total_rowcount,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_log_bytes_used,0)     * COALESCE(rs.count_executions,0))) * 0.0009765625, 2) AS total_log_bytes_used_mb,
    ROUND(CONVERT(float, SUM(COALESCE(rs.avg_tempdb_space_used,0)  * COALESCE(rs.count_executions,0))) * 8, 2)    AS total_tempdb_space_used_kb,

    SUM(COALESCE(rs.count_executions,0)) AS count_executions,
    COUNT(DISTINCT p.plan_id)            AS num_plans
FROM sys.query_store_runtime_stats AS rs
JOIN sys.query_store_plan AS p ON p.plan_id = rs.plan_id
JOIN sys.query_store_query AS q ON q.query_id = p.query_id
JOIN sys.query_store_query_text AS qt ON q.query_text_id = qt.query_text_id
WHERE NOT (rs.first_execution_time > @interval_end_time OR rs.last_execution_time < @interval_start_time)
  AND (@include_internal = 1 OR q.is_internal_query = 0)
  AND (@include_aborted = 1 OR rs.execution_type = 0) -- regular executions only by default
GROUP BY p.query_id, q.object_id, qt.query_sql_text;

/* ================= COMBINE + RECOMMENDATIONS ================= */
IF OBJECT_ID('tempdb..#combined') IS NOT NULL DROP TABLE #combined;
CREATE TABLE #combined
(
    query_id BIGINT NOT NULL PRIMARY KEY,
    object_id INT NULL,
    object_name SYSNAME NULL,
    query_sql_text NVARCHAR(MAX) NULL,

    total_duration_sec FLOAT NULL,
    total_cpu_time_sec FLOAT NULL,
    total_logical_io_reads_kb FLOAT NULL,
    total_logical_io_writes_kb FLOAT NULL,
    total_physical_io_reads_kb FLOAT NULL,
    total_query_max_used_memory_kb FLOAT NULL,
    total_tempdb_space_used_kb FLOAT NULL,
    total_log_bytes_used_mb FLOAT NULL,
    total_rowcount FLOAT NULL,
    count_executions BIGINT NOT NULL,
    num_plans INT NOT NULL,

    total_query_wait_time_ms FLOAT NULL,

    top_wait_category_desc NVARCHAR(128) NULL,
    top_wait_ms FLOAT NULL,
    top_wait_pct FLOAT NULL,
    second_wait_category_desc NVARCHAR(128) NULL,
    second_wait_ms FLOAT NULL,
    second_wait_pct FLOAT NULL,
    third_wait_category_desc NVARCHAR(128) NULL,
    third_wait_ms FLOAT NULL,
    third_wait_pct FLOAT NULL,

    diagnostic_recommendation NVARCHAR(MAX) NULL
);

INSERT INTO #combined
SELECT 
    A.query_id,
    A.object_id,
    A.object_name,
    A.query_sql_text,

    A.total_duration_sec,
    A.total_cpu_time_sec,
    A.total_logical_io_reads_kb,
    A.total_logical_io_writes_kb,
    A.total_physical_io_reads_kb,
    A.total_query_max_used_memory_kb,
    A.total_tempdb_space_used_kb,
    A.total_log_bytes_used_mb,
    A.total_rowcount,
    A.count_executions,
    A.num_plans,

    ISNULL(T.query_total_wait_ms, 0) AS total_query_wait_time_ms,

    W.top_wait_category_desc,
    W.top_wait_ms,
    W.top_wait_pct,
    W.second_wait_category_desc,
    W.second_wait_ms,
    W.second_wait_pct,
    W.third_wait_category_desc,
    W.third_wait_ms,
    W.third_wait_pct,

    /* Diagnostic recommendation mapped to dominant category + supporting totals */
    CASE
        WHEN W.top_wait_category_desc LIKE '%Lock%' OR W.top_wait_category_desc LIKE 'LCK%' THEN
            'Blocking/locks dominant. Actions: identify blockers; add indexes to shorten transactions; consider RCSI/Snapshot Isolation; review transaction scope.'
        WHEN W.top_wait_category_desc LIKE '%Latch%' THEN
            'Latch contention. Actions: check hot pages/identity hotspots; spread writes (partitioning/reverse keys); validate tempdb allocation contention.'
        WHEN W.top_wait_category_desc LIKE '%I/O%' AND A.total_logical_io_reads_kb > 1024*1024 THEN
            'I/O-bound with heavy logical reads. Actions: add/selective/covering indexes; update stats; consider filtered/materialized results; validate storage throughput.'
        WHEN W.top_wait_category_desc LIKE '%Log%' OR W.top_wait_category_desc LIKE '%WRITELOG%' THEN
            'Log bottleneck. Actions: batch writes; ensure fast log disk & adequate IOPS; pre-size log; review AG commit mode.'
        WHEN W.top_wait_category_desc LIKE '%Parallel%' OR W.top_wait_category_desc LIKE '%CX%' THEN
            'Parallelism waits. Actions: validate MAXDOP & Cost Threshold; fix skew/cardinality (stats/predicates/joins); consider hints only after plan-quality fixes.'
        WHEN W.top_wait_category_desc LIKE '%CPU%' OR W.top_wait_category_desc LIKE '%SOS_SCHEDULER_YIELD%' THEN
            'CPU-bound. Actions: improve SARGability & indexing; remove scalar UDF bottlenecks; reduce scanned columns; review concurrency/MAXDOP.'
        WHEN W.top_wait_category_desc LIKE '%Memory%' OR W.top_wait_category_desc LIKE '%RESOURCE_SEMAPHORE%' THEN
            'Memory grant pressure. Actions: reduce sort/hash spills with indexes; improve cardinality; leverage Memory Grant Feedback; tune concurrency.'
        WHEN W.top_wait_category_desc LIKE '%Network%' OR W.top_wait_category_desc LIKE '%ASYNC_NETWORK_IO%' THEN
            'Network/client bottleneck. Actions: fetch rows in sets; reduce chatty APIs & SELECT *; tune driver fetch size; consider pagination.'
        WHEN A.total_tempdb_space_used_kb > 512*1024 THEN
            'High tempdb usage. Actions: reduce spills via indexes & stats; avoid wide sorts/hashes; validate memory grants; ensure tempdb files & fast storage.'
        ELSE
            'Review plan & wait breakdown; tune indexes/stats/parameterization; verify isolation; validate resource configuration.'
    END AS diagnostic_recommendation
FROM #top_other_stats AS A
LEFT JOIN #top3_waits AS W ON W.query_id = A.query_id
LEFT JOIN #wait_totals AS T ON T.query_id = A.query_id
WHERE A.count_executions >= @min_execs;

/* ================= RESULT SET 1: TOP QUERIES ================= */
SELECT TOP (@results_row_count)
    query_id,
    object_id,
    object_name,
    query_sql_text,

    total_duration_sec,
    total_cpu_time_sec,
    total_logical_io_reads_kb,
    total_logical_io_writes_kb,
    total_physical_io_reads_kb,
    total_query_max_used_memory_kb,
    total_tempdb_space_used_kb,
    total_log_bytes_used_mb,
    total_rowcount,
    count_executions,
    num_plans,

    total_query_wait_time_ms,
    top_wait_category_desc AS top_wait_category,
    top_wait_ms,
    top_wait_pct,
    second_wait_category_desc AS second_wait_category,
    second_wait_ms,
    second_wait_pct,
    third_wait_category_desc AS third_wait_category,
    third_wait_ms,
    third_wait_pct,

    diagnostic_recommendation
FROM #combined
ORDER BY total_duration_sec DESC;

/* ================= RESULT SET 2: DETAILED BREAKDOWN ================= */
SELECT 
    b.query_id,
    b.object_id,
    b.object_name,
    b.wait_category_desc AS wait_category,  -- Query Store “wait type name”
    b.total_wait_ms,
    b.query_total_wait_ms,
    b.pct_of_query_waits
FROM #wait_breakdown AS b
ORDER BY b.query_id, b.total_wait_ms DESC;
