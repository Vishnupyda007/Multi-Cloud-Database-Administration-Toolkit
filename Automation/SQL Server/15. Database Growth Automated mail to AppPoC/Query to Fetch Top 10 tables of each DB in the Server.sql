IF OBJECT_ID('tempdb..#TableSizes') IS NOT NULL DROP TABLE #TableSizes;

CREATE TABLE #TableSizes (
    ServerName NVARCHAR(128),
    DatabaseName NVARCHAR(128),
    TableName NVARCHAR(256),
    TotalRows BIGINT,
    TableSizeGB DECIMAL(18,2),
    CaptureDate DATETIME
);

EXEC sp_MSforeachdb N'
IF ''?'' NOT IN (''master'', ''model'', ''msdb'', ''tempdb'')
BEGIN
    DECLARE @sql NVARCHAR(MAX) = ''
    USE [?];
    INSERT INTO #TableSizes
    SELECT 
        @@ServerName AS ServerName,
        DB_NAME() AS DatabaseName,
        t.name AS TableName,
        SUM(p.rows) AS TotalRows,
        CAST(SUM(a.total_pages) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS TableSizeGB,
        GETDATE() AS CaptureDate
    FROM 
        sys.tables t
    INNER JOIN 
        sys.indexes i ON t.object_id = i.object_id
    INNER JOIN 
        sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    INNER JOIN 
        sys.allocation_units a ON p.partition_id = a.container_id
    GROUP BY 
        t.name
    HAVING 
        SUM(a.total_pages) > 0
    ORDER BY 
        TableSizeGB DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
    '';
    EXEC sp_executesql @sql;
END
';

-- Final result
SELECT * FROM #TableSizes
ORDER BY DatabaseName, TableSizeGB DESC;


