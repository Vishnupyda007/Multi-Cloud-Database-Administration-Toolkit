-- to-get-execution-plan-parameterized.sql
-- Purpose: Parameterized version of the "to get execution plan for query hash" script.
-- Usage: Set @queryhash to a varbinary query_hash to filter a single query, or set to NULL to list none (no filter).
-- Run in SSMS or sqlcmd. Requires Query Store enabled.

SET NOCOUNT ON;

DECLARE @queryhash VARBINARY(64) = NULL; -- set to specific value to filter; NULL to list all / disable filter

SELECT
  qt.query_sql_text,
  TRY_CAST(p.query_plan AS XML) AS [ExecutionPlan],
  rs.last_execution_time
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats AS rs ON p.plan_id = rs.plan_id
WHERE (@queryhash IS NULL OR q.query_hash = @queryhash)
ORDER BY rs.last_execution_time DESC;
