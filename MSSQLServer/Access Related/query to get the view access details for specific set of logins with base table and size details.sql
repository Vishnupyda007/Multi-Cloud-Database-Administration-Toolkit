-- CTE to get base tables for each view
WITH ViewBaseTables AS (
    SELECT
        referencing.name AS ViewName,
        referenced.name AS BaseTableName,
        OBJECT_SCHEMA_NAME(referenced.object_id) + '.' + referenced.name AS BaseTableFullName,
        referenced.object_id AS BaseTableObjectID
    FROM 
        sys.sql_expression_dependencies AS dependencies
    INNER JOIN 
        sys.objects AS referencing 
        ON dependencies.referencing_id = referencing.object_id
    INNER JOIN 
        sys.objects AS referenced
        ON dependencies.referenced_id = referenced.object_id
    WHERE 
        referencing.type = 'V'
),

-- CTE to get table size and row count
TableSizeStats AS (
    SELECT 
        ps.object_id,
        SUM(ps.row_count) AS TotalRows,
        SUM(a.total_pages) * 8.0 / 1024 AS SizeMB
    FROM 
        sys.dm_db_partition_stats AS ps
    JOIN 
        sys.allocation_units AS a ON ps.partition_id = a.container_id
    GROUP BY 
        ps.object_id
)

-- Main query
SELECT DISTINCT
    dp.type_desc AS LoginType,
    dp.name AS LoginName,
    o.name AS ObjectName,
    o.type_desc AS ObjectType,
    p.permission_name AS PermissionType,
    OBJECT_SCHEMA_NAME(o.object_id) + '.' + o.name AS ViewName,
    vbt.BaseTableFullName AS BaseTable,
    ts.SizeMB,
    ts.TotalRows
FROM 
    sys.database_permissions p
JOIN 
    sys.objects o ON p.major_id = o.object_id
JOIN 
    sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
LEFT JOIN 
    ViewBaseTables vbt ON o.name = vbt.ViewName
LEFT JOIN 
    TableSizeStats ts ON vbt.BaseTableObjectID = ts.object_id
WHERE 
    o.type_desc = 'VIEW'
    AND dp.name in  ('988-APP-P',
'2381-APP-P',
'1429-APP-P',
'2787-APP-P',
'2774-APP-P',
'3657-APP-P',
'757-APP-P',
'3414-APP-P'
)
