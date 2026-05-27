
EXEC sp_msforeachdb 
N'
USE [?];
IF EXISTS (SELECT * FROM sys.objects WHERE name = ''usp_GetQuickActions'')
BEGIN
    PRINT ''Object found in database: [?]'';
END
';

--------------OR---------------

EXEC sp_msforeachdb 
N'
USE [?];
SELECT 
    ''[?]'' AS DatabaseName,
    s.name AS SchemaName,
    o.name AS ObjectName,
    o.type_desc AS ObjectType
FROM 
    sys.objects o
JOIN 
    sys.schemas s ON o.schema_id = s.schema_id
WHERE 
    o.name = ''usp_GetQuickActions'';
';
