-- ============================================
-- VIEWS AND THEIR UNDERLYING BASE TABLES
-- ACROSS ALL USER DATABASES
-- ============================================

CREATE TABLE #ViewTableMapping
(
    DatabaseName     NVARCHAR(128),
    ViewSchema       NVARCHAR(128),
    ViewName         NVARCHAR(128),
    ReferencedSchema NVARCHAR(128),
    ReferencedTable  NVARCHAR(128)
);

EXEC sp_MSforeachdb '
USE [?];
IF DB_NAME() NOT IN (''master'',''tempdb'',''model'',''msdb'',''centralrepository'')
BEGIN
    INSERT INTO #ViewTableMapping
    SELECT DISTINCT
        DB_NAME()                          AS DatabaseName,
        vs.name                            AS ViewSchema,
        v.name                             AS ViewName,
        ts.name                            AS ReferencedSchema,
        t.name                             AS ReferencedTable
    FROM sys.views v
    JOIN sys.schemas vs                    ON v.schema_id        = vs.schema_id
    JOIN sys.sql_expression_dependencies d ON d.referencing_id   = v.object_id
    JOIN sys.tables t                      ON d.referenced_id    = t.object_id
    JOIN sys.schemas ts                    ON t.schema_id        = ts.schema_id
    WHERE v.is_ms_shipped = 0
      AND v.name NOT LIKE ''%EDS%''
END'

SELECT 
    DatabaseName,
    ViewSchema       AS ViewSchemaName,
    ViewName,
    ReferencedSchema AS TableSchemaName,
    ReferencedTable  AS TableName
FROM #ViewTableMapping
ORDER BY DatabaseName, ViewSchema, ViewName, ReferencedSchema, ReferencedTable;

DROP TABLE #ViewTableMapping;