
SELECT 
  @@SERVERNAME AS ServerName,
  SUM(CASE WHEN df.type_desc='ROWS' THEN df.size END) * 8.0 / 1024 / 1024 AS AllocatedDataGB,
  SUM(CASE WHEN df.type_desc='ROWS' THEN FILEPROPERTY(df.name,'SpaceUsed') END) * 8.0 / 1024 / 1024 AS UsedDataGB,
  SUM(ls.total_log_size_in_bytes) / 1024.0 / 1024 / 1024 AS AllocatedLogGB,
  SUM(ls.used_log_space_in_bytes) / 1024.0 / 1024 / 1024 AS UsedLogGB,
  (
    SUM(CASE WHEN df.type_desc='ROWS' THEN df.size END) * 8.0 / 1024 / 1024
    + SUM(ls.total_log_size_in_bytes) / 1024.0 / 1024 / 1024
  ) AS TotalAllocatedGB,
  (
    SUM(CASE WHEN df.type_desc='ROWS' THEN FILEPROPERTY(df.name,'SpaceUsed') END) * 8.0 / 1024 / 1024
    + SUM(ls.used_log_space_in_bytes) / 1024.0 / 1024 / 1024
  ) AS TotalUsedGB,
  (
    (SUM(CASE WHEN df.type_desc='ROWS' THEN df.size END) * 8.0 / 1024 / 1024
     - SUM(CASE WHEN df.type_desc='ROWS' THEN FILEPROPERTY(df.name,'SpaceUsed') END) * 8.0 / 1024 / 1024)
    + (SUM(ls.total_log_size_in_bytes - ls.used_log_space_in_bytes) / 1024.0 / 1024 / 1024)
  ) AS FreeInsideFilesGB,
  MAX(CAST(DATABASEPROPERTYEX(DB_NAME(), 'MaxSizeInBytes') AS bigint)) / 1024.0 / 1024 / 1024 AS DatabaseMaxDataSizeGB,
  (
    MAX(CAST(DATABASEPROPERTYEX(DB_NAME(), 'MaxSizeInBytes') AS bigint)) / 1024.0 / 1024 / 1024
    - (SUM(CASE WHEN df.type_desc='ROWS' THEN FILEPROPERTY(df.name,'SpaceUsed') END) * 8.0 / 1024 / 1024)
  ) AS FreeToMaxGB
FROM sys.database_files AS df
CROSS APPLY (SELECT TOP 1 total_log_size_in_bytes, used_log_space_in_bytes FROM sys.dm_db_log_space_usage) AS ls
WHERE df.type_desc IN ('ROWS','LOG');
