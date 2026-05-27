DECLARE @query_hash BINARY(8);

SET @query_hash = 0x598C5FAD95B55534;
 
WITH query_ids AS (

    SELECT

        q.query_hash,

        q.query_id,

        p.query_plan_hash,

        SUM(qrs.count_executions) * AVG(qrs.avg_cpu_time) / 1000.0 AS total_cpu_time_ms,

        SUM(qrs.count_executions) AS sum_executions,

        AVG(qrs.avg_cpu_time) / 1000.0 AS avg_cpu_time_ms

    FROM sys.query_store_query q

    JOIN sys.query_store_plan p ON q.query_id = p.query_id

    JOIN sys.query_store_runtime_stats qrs ON p.plan_id = qrs.plan_id

    WHERE q.query_hash = @query_hash

    GROUP BY q.query_id, q.query_hash, p.query_plan_hash

)

SELECT 

    qid.*,

    qt.query_sql_text,

    p.count_compiles,

    TRY_CAST(p.query_plan AS XML) AS query_plan

FROM query_ids AS qid

JOIN sys.query_store_query AS q ON qid.query_id = q.query_id

JOIN sys.query_store_query_text AS qt ON q.query_text_id = qt.query_text_id

JOIN sys.query_store_plan AS p 

    ON qid.query_id = p.query_id 

   AND qid.query_plan_hash = p.query_plan_hash

ORDER BY total_cpu_time_ms DESC;

 