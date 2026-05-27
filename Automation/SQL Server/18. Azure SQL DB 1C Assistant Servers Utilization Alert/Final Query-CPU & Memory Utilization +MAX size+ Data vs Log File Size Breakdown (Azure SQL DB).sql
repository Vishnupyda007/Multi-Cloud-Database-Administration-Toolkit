
SELECT 
  @@SERVERNAME AS ServerName,

  -- Resource utilization (relative to current compute limits)
  r.avg_cpu_percent,
  r.avg_log_write_percent,
  r.avg_memory_usage_percent,
  r.max_worker_percent,
  r.avg_instance_cpu_percent,
  r.avg_instance_memory_percent,

  -- Storage breakdown (data vs. log)
  d.AllocatedDataGB,
  d.UsedDataGB,
  l.AllocatedLogGB,
  l.UsedLogGB,

  -- Totals and free inside currently allocated files (data + log)
  CAST(d.AllocatedDataGB + l.AllocatedLogGB AS DECIMAL(18,2)) AS TotalAllocatedGB,
  CAST(d.UsedDataGB + l.UsedLogGB         AS DECIMAL(18,2))   AS TotalUsedGB,
  CAST((d.AllocatedDataGB - d.UsedDataGB) + (l.AllocatedLogGB - l.UsedLogGB) AS DECIMAL(18,2)) AS FreeInsideFilesGB,

  -- MAX data size and free-to-max (DATA ONLY)
 cast (m.MaxDataSizeGB AS DECIMAL(18,2))    AS DatabaseMaxDataSizeGB,
  CAST(m.MaxDataSizeGB - d.UsedDataGB AS DECIMAL(18,2)) AS FreeToMaxGB,

  -- Percentages for alerting
  CAST(100.0 * ((d.AllocatedDataGB - d.UsedDataGB) + (l.AllocatedLogGB - l.UsedLogGB)) 
       / NULLIF(d.AllocatedDataGB + l.AllocatedLogGB,0) AS DECIMAL(5,2)) AS FreeInsideFilesPct,
  CAST(100.0 * (m.MaxDataSizeGB - d.UsedDataGB) / NULLIF(m.MaxDataSizeGB,0) AS DECIMAL(5,2)) AS FreeToMaxPct,
  CAST(100.0 * d.UsedDataGB / NULLIF(m.MaxDataSizeGB,0) AS DECIMAL(5,2)) AS DataUsedPctOfMax,
  CAST(100.0 * l.UsedLogGB / NULLIF(l.AllocatedLogGB,0) AS DECIMAL(5,2)) AS LogUsedPctOfAllocated,

  -- Local IST time
  r.Captured_time
FROM
  -- Data files: allocated vs. used (ROWS only via CASE)
  (SELECT 
      CAST(SUM(CASE WHEN type_desc='ROWS' THEN size END) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS AllocatedDataGB,
      CAST(SUM(CASE WHEN type_desc='ROWS' THEN FILEPROPERTY(name,'SpaceUsed') END) * 8.0 / 1024 / 1024 AS DECIMAL(18,2)) AS UsedDataGB
   FROM sys.database_files) AS d
CROSS APPLY
  -- Log usage from DMV (correct source for Azure SQL)
  (SELECT 
      CAST(total_log_size_in_bytes/1024.0/1024/1024 AS DECIMAL(18,2)) AS AllocatedLogGB,
      CAST(used_log_space_in_bytes/1024.0/1024/1024 AS DECIMAL(18,2))  AS UsedLogGB
   FROM sys.dm_db_log_space_usage) AS l
CROSS APPLY
  -- Azure SQL DB: MaxSizeInBytes = MAX **DATA** size (log separate)
  (SELECT CAST(DATABASEPROPERTYEX(DB_NAME(), 'MaxSizeInBytes') AS DECIMAL(18,2))/1024.0/1024/1024 AS MaxDataSizeGB) AS m
CROSS APPLY
  -- Latest resource sample (~15-second intervals; ~1-hour history)
  (SELECT TOP(1)
      avg_cpu_percent,
      avg_log_write_percent,
      avg_memory_usage_percent,
      max_worker_percent,
      avg_instance_cpu_percent,
      avg_instance_memory_percent,
      DATEADD(MINUTE, 330, end_time) AS Captured_time
   FROM sys.dm_db_resource_stats
   ORDER BY end_time DESC) AS r;
