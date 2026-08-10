/* Demo: Parameterized Query Store lookup (safe example)
   - Start the demo container (demos/mssql/docker-compose.yml)
   - Edit the SA password in docker-compose.yml before use if required
   - Connect using: docker exec -it mssql-demo /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'YourStrong!Passw0rd' -i /scripts/demo_querystore_lookup.sql
*/

SET NOCOUNT ON;

-- Parameter: set to a specific query_hash to filter, or leave NULL to list recent plans
DECLARE @queryhash VARBINARY(64) = NULL; -- Example: 0x61FB24F1FC63ADB4

-- Example: show top plans with their last execution time and plan XML
SELECT TOP 100
    p.query_id,
    p.plan_id,
    q.query_hash,
    qt.query_sql_text,
    p.last_execution_time,
    TRY_CAST(p.query_plan AS XML) AS query_plan
FROM sys.query_store_plan p
LEFT JOIN sys.query_store_query q ON q.query_id = p.query_id
LEFT JOIN sys.query_store_query_text qt ON qt.query_text_id = q.query_text_id
WHERE (@queryhash IS NULL OR q.query_hash = @queryhash)
ORDER BY p.last_execution_time DESC;

-- Tip: set @queryhash to a known value to filter a single query
-- Example: uncomment and replace with a known hash
-- SET @queryhash = 0x61FB24F1FC63ADB4;
