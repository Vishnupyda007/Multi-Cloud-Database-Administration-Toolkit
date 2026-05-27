WITH ReferencedTables AS (
    SELECT 
        v.name AS ViewName,
        t.name AS TableName,
        s.name AS SchemaName,
        t.object_id AS TableObjectID
    FROM 
        sys.views v
    JOIN 
        sys.sql_expression_dependencies d ON v.object_id = d.referencing_id
    JOIN 
        sys.tables t ON d.referenced_id = t.object_id
    JOIN 
        sys.schemas s ON t.schema_id = s.schema_id
),
TableSizes AS (
    SELECT 
        t.object_id,
        SUM(a.total_pages) * 8 AS TotalSizeKB
    FROM 
        sys.tables t
    JOIN 
        sys.indexes i ON t.object_id = i.object_id
    JOIN 
        sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    JOIN 
        sys.allocation_units a ON p.partition_id = a.container_id
    GROUP BY 
        t.object_id
)
SELECT 
    rt.ViewName,
    rt.SchemaName + '.' + rt.TableName AS ReferencedTable,
    ts.TotalSizeKB / 1024.0 AS TotalSizeMB
FROM 
    ReferencedTables rt
JOIN 
    TableSizes ts ON rt.TableObjectID = ts.object_id
ORDER BY 
    rt.ViewName, TotalSizeMB DESC;
