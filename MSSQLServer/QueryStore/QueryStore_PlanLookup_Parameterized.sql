-- QueryStore_PlanLookup_Parameterized.sql
-- Purpose: Parameterized example to lookup Query Store plans by query_hash.
-- Usage:
-- 1) Edit the DECLARE below and set @queryhash to a varbinary query_hash to filter.
-- 2) Or set @queryhash = NULL to list recent plans (no filter).
-- 3) Run in SSMS or via sqlcmd. Requires Query Store enabled (SQL Server 2016+).

/* Example:
   -- specific filter
   DECLARE @queryhash VARBINARY(64) = 0x2D8506AE3E46D084;

   -- or list recent plans
   DECLARE @queryhash VARBINARY(64) = NULL;
*/

SET NOCOUNT ON;

DECLARE @queryhash VARBINARY(64) = NULL; -- set to specific value to filter; set to NULL to list recent plans

SELECT TOP 100
  p.query_id,
  p.query_plan_hash,
  q.query_hash,
  ISNULL(o.[name], '<module>') AS object_name,
  ISNULL(o.[type_desc], '<type>') AS object_type_desc,
  qt.query_sql_text,
  p.last_execution_time,
  CAST(p.query_plan AS XML) AS QueryPlan
FROM sys.query_store_plan AS p
LEFT JOIN sys.query_store_query AS q ON q.query_id = p.query_id
LEFT JOIN sys.query_store_query_text AS qt ON qt.query_text_id = q.query_text_id
LEFT JOIN sys.all_objects o ON o.object_id = q.object_id
WHERE (@queryhash IS NULL OR q.query_hash = @queryhash)
ORDER BY p.last_execution_time DESC;
