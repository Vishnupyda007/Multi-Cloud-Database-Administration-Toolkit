-- CPU & Memory Utilization + Data vs Log File Size Breakdown (Azure SQL DB)
WITH FileStats AS
(
    SELECT 
        type_desc,
        CAST(SUM(size) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS AllocatedGB,
        CAST(SUM(FILEPROPERTY(name, 'SpaceUsed')) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS UsedGB
    FROM sys.database_files
    GROUP BY type_desc
),
Summary AS
(
    SELECT
        MAX(CASE WHEN type_desc = 'ROWS' THEN AllocatedGB ELSE 0 END) AS DataFileSizeGB,
        MAX(CASE WHEN type_desc = 'ROWS' THEN UsedGB ELSE 0 END) AS DataUsedGB,
        MAX(CASE WHEN type_desc = 'LOG' THEN AllocatedGB ELSE 0 END) AS LogFileSizeGB,
        MAX(CASE WHEN type_desc = 'LOG' THEN UsedGB ELSE 0 END) AS LogUsedGB
    FROM FileStats
)
SELECT TOP 1 
    @@SERVERNAME AS ServerName,
    rs.avg_cpu_percent,
    rs.avg_log_write_percent,
    rs.avg_memory_usage_percent,
    rs.max_worker_percent,
    rs.avg_instance_cpu_percent,
    rs.avg_instance_memory_percent,
    s.DataFileSizeGB,
    s.DataUsedGB,
    s.LogFileSizeGB,
    s.LogUsedGB,
    CAST((s.DataFileSizeGB + s.LogFileSizeGB) AS DECIMAL(10,2)) AS TotalSizeGB,
    CAST((s.DataUsedGB + s.LogUsedGB) AS DECIMAL(10,2)) AS TotalUsedGB,
    CAST((s.DataFileSizeGB + s.LogFileSizeGB - s.DataUsedGB - s.LogUsedGB) AS DECIMAL(10,2)) AS TotalFreeGB,
    CAST(((s.DataFileSizeGB + s.LogFileSizeGB - s.DataUsedGB - s.LogUsedGB) * 100.0 / (s.DataFileSizeGB + s.LogFileSizeGB)) AS DECIMAL(5,2)) AS FreePct,
	DATEADD(MINUTE, 330, rs.end_time) AS Captured_time
FROM sys.dm_db_resource_stats rs
CROSS JOIN Summary s
ORDER BY rs.end_time DESC;
