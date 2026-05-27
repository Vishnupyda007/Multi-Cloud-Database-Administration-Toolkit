-- Step 1: Create temp table

IF OBJECT_ID('tempdb..#TempDBUsage') IS NOT NULL 

    DROP TABLE #TempDBUsage;
 
CREATE TABLE #TempDBUsage (

    DatabaseName            NVARCHAR(128),

    Interval_Start          DATETIME,

    Interval_End            DATETIME,

    QueryText               NVARCHAR(MAX),

    Query_ID                BIGINT,

    Count_Executions        BIGINT,

    Avg_TempDB_KB           BIGINT,

    Max_TempDB_KB           BIGINT,

    Total_TempDB_KB         BIGINT,

    Avg_Duration_MS         BIGINT,

    Avg_Logical_Reads       BIGINT,

    Avg_Logical_Writes      BIGINT

);
 
-- Step 2: Collect from ALL databases that have Query Store ON

EXEC sp_MSforeachdb '

USE [?];

IF (SELECT is_query_store_on FROM sys.databases WHERE name = ''?'') = 1

BEGIN

    INSERT INTO #TempDBUsage

    SELECT 

        DB_NAME()                                                   AS DatabaseName,

        qsi.start_time                                              AS Interval_Start,

        qsi.end_time                                                AS Interval_End,

        qst.query_sql_text                                          AS QueryText,

        qsq.query_id                                                AS Query_ID,

        qrs.count_executions,

        qrs.avg_tempdb_space_used * 8                               AS Avg_TempDB_KB,

        qrs.max_tempdb_space_used * 8                               AS Max_TempDB_KB,

        (qrs.avg_tempdb_space_used * qrs.count_executions) * 8      AS Total_TempDB_KB,

        qrs.avg_duration / 1000                                     AS Avg_Duration_MS,

        qrs.avg_logical_io_reads                                    AS Avg_Logical_Reads,

        qrs.avg_logical_io_writes                                   AS Avg_Logical_Writes

    FROM sys.query_store_query qsq

    JOIN sys.query_store_query_text qst 

        ON qsq.query_text_id = qst.query_text_id

    JOIN sys.query_store_plan qsp 

        ON qsq.query_id = qsp.query_id

    JOIN sys.query_store_runtime_stats qrs 

        ON qsp.plan_id = qrs.plan_id

    JOIN sys.query_store_runtime_stats_interval qsi 

        ON qrs.runtime_stats_interval_id = qsi.runtime_stats_interval_id

    WHERE qsi.start_time >= DATEADD(HOUR, -24, GETDATE())

      AND qrs.avg_tempdb_space_used > 0;

END

';
 
-- =====================================================

-- Result 1: TOP QUERIES ranked by total tempdb consumed

-- database + query + full metrics

-- =====================================================

SELECT 

    DatabaseName,

    Interval_Start,

    Interval_End,

    QueryText,

    Count_Executions,

    Avg_TempDB_KB,

    Max_TempDB_KB,

    Total_TempDB_KB                                             AS Total_TempDB_KB_Consumed,

    Avg_Duration_MS,

    Avg_Logical_Reads,

    Avg_Logical_Writes

FROM #TempDBUsage

ORDER BY Total_TempDB_KB_Consumed DESC;
 
-- =====================================================

-- Result 2: SUMMARY per database + top query per DB

-- =====================================================

WITH RankedByDB AS (

    SELECT 

        DatabaseName,

        QueryText,

        SUM(Total_TempDB_KB)            AS Total_TempDB_KB_Consumed,

        SUM(Count_Executions)           AS Total_Executions,

        MAX(Max_TempDB_KB)              AS Peak_TempDB_KB,

        AVG(Avg_TempDB_KB)              AS Avg_TempDB_KB,

        AVG(Avg_Duration_MS)            AS Avg_Duration_MS,

        AVG(Avg_Logical_Reads)          AS Avg_Logical_Reads,

        MIN(Interval_Start)             AS First_Seen,

        MAX(Interval_End)               AS Last_Seen,

        ROW_NUMBER() OVER (

            PARTITION BY DatabaseName 

            ORDER BY SUM(Total_TempDB_KB) DESC

        )                               AS QueryRank

    FROM #TempDBUsage

    GROUP BY DatabaseName, QueryText

)

SELECT 

    DatabaseName,

    QueryRank                           AS Rank_Within_DB,

    QueryText                           AS Top_Query,

    Total_Executions,

    Avg_TempDB_KB,

    Peak_TempDB_KB,

    Total_TempDB_KB_Consumed,

    Avg_Duration_MS,

    Avg_Logical_Reads,

    First_Seen,

    Last_Seen

FROM RankedByDB

WHERE QueryRank <= 5                    -- top 5 queries per database

ORDER BY Total_TempDB_KB_Consumed DESC;
 
-- =====================================================

-- Result 3: SPIKE DETECTION — which interval was worst

-- per database with the query that caused it

-- =====================================================

WITH IntervalTotals AS (

    SELECT 

        DatabaseName,

        Interval_Start,

        Interval_End,

        SUM(Total_TempDB_KB)            AS Interval_Total_KB,

        ROW_NUMBER() OVER (

            PARTITION BY DatabaseName 

            ORDER BY SUM(Total_TempDB_KB) DESC

        )                               AS IntervalRank

    FROM #TempDBUsage

    GROUP BY DatabaseName, Interval_Start, Interval_End

),

SpikeIntervals AS (

    SELECT * FROM IntervalTotals 

    WHERE IntervalRank = 1              -- worst interval per database

),

RankedQueriesInSpike AS (

    SELECT 

        t.DatabaseName,

        s.Interval_Start                AS Spike_Start,

        s.Interval_End                  AS Spike_End,

        s.Interval_Total_KB             AS Spike_Total_TempDB_KB,

        t.QueryText,

        t.Count_Executions,

        t.Avg_TempDB_KB,

        t.Max_TempDB_KB,

        t.Total_TempDB_KB               AS Query_TempDB_KB,

        t.Avg_Duration_MS,

        t.Avg_Logical_Reads,

        ROW_NUMBER() OVER (

            PARTITION BY t.DatabaseName 

            ORDER BY t.Total_TempDB_KB DESC

        )                               AS QueryRank

    FROM #TempDBUsage t

    JOIN SpikeIntervals s 

        ON t.DatabaseName  = s.DatabaseName

        AND t.Interval_Start = s.Interval_Start

)

SELECT 

    DatabaseName,

    Spike_Start,

    Spike_End,

    Spike_Total_TempDB_KB,

    QueryRank                           AS Rank_In_Spike,

    QueryText,

    Count_Executions,

    Avg_TempDB_KB,

    Max_TempDB_KB,

    Query_TempDB_KB,

    Avg_Duration_MS,

    Avg_Logical_Reads

FROM RankedQueriesInSpike

WHERE QueryRank <= 3                    -- top 3 queries during spike per DB

ORDER BY Spike_Total_TempDB_KB DESC, QueryRank ASC;
 
-- =====================================================

-- Result 4: HOUR BY HOUR timeline with top query

-- =====================================================

WITH HourlyRanked AS (

    SELECT 

        DatabaseName,

        Interval_Start,

        Interval_End,

        QueryText,

        Total_TempDB_KB,

        Count_Executions,

        Avg_TempDB_KB,

        Avg_Duration_MS,

        SUM(Total_TempDB_KB) OVER (

            PARTITION BY DatabaseName, Interval_Start

        )                               AS Interval_Total_KB,

        ROW_NUMBER() OVER (

            PARTITION BY DatabaseName, Interval_Start 

            ORDER BY Total_TempDB_KB DESC

        )                               AS RowRank

    FROM #TempDBUsage

)

SELECT 

    DatabaseName,

    Interval_Start,

    Interval_End,

    Interval_Total_KB                   AS Total_TempDB_KB_That_Hour,

    QueryText                           AS Top_Query_That_Hour,

    Count_Executions,

    Avg_TempDB_KB,

    Avg_Duration_MS,

    REPLICATE('|', Interval_Total_KB / 50000) AS TempDB_Bar   -- visual bar

FROM HourlyRanked

WHERE RowRank = 1

ORDER BY DatabaseName, Interval_Start ASC;
 
-- Cleanup

DROP TABLE #TempDBUsage;
 