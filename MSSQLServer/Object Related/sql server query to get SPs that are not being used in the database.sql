------------
--Identifying stored procedures (SPs) that are not being used in a SQL Server database is a bit tricky because SQL Server does not automatically track usage of stored procedures unless you have:

--Query Store enabled
--Extended Events or SQL Server Profiler running
--Custom logging in place

--✅ Option 1: Use sys.dm_exec_procedure_stats

SELECT 
    p.name AS ProcedureName,
    ps.execution_count,
	ps.last_execution_time,
	ps.total_worker_time
FROM sys.procedures p
LEFT JOIN sys.dm_exec_procedure_stats ps ON p.object_id = ps.object_id
WHERE ps.execution_count IS NULL;


--------------------

--✅ Option 3: Manual Audit (if no telemetry is available)
--If none of the above are available, you can:

--List all stored procedures.
--Search for references in:
--Views
--Other procedures
--Jobs
--Application logs. To find stored procedures (SPs) that are not being referenced by other objects in SQL Server, you can use the sys.sql_expression_dependencies system view


SELECT p.name AS ProcedureName,
       SCHEMA_NAME(p.schema_id) AS SchemaName
FROM sys.procedures p
WHERE p.is_ms_shipped = 0
  AND NOT EXISTS (
      SELECT 1
      FROM sys.sql_expression_dependencies d
      WHERE d.referenced_id = p.object_id
  )
ORDER BY SchemaName, ProcedureName;

-----------OR---------------

SELECT name 
FROM sys.procedures
WHERE name NOT IN (
    SELECT DISTINCT OBJECT_NAME(referencing_id)
    FROM sys.sql_expression_dependencies
    WHERE referenced_entity_name IS NOT NULL
);



----------------------------

--✅ Option 2: Use Query Store (if enabled)

SELECT 
    o.name AS ProcedureName
FROM sys.objects o
LEFT JOIN sys.query_store_query qsq ON OBJECT_ID(o.name) = qsq.object_id
WHERE o.type = 'P' AND qsq.query_id IS NULL;