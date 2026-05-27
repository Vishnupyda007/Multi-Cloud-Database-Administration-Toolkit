
-- MAXSIZE at the database level (GB)
SELECT 
  CAST(DATABASEPROPERTYEX(DB_NAME(), 'MaxSizeInBytes') AS bigint)/1024.0/1024/1024 AS maxsize_gb;

-- Current storage vs. allocated (from master)
-- Run in master:
-- SELECT MAX(start_time) AS LastCollectionTime, database_name,
--        MAX(storage_in_megabytes) AS current_size_mb,
--        MAX(allocated_storage_in_megabytes) AS allocated_mb
-- FROM sys.resource_stats
-- GROUP BY database_name;

select

MAX(CAST(DATABASEPROPERTYEX(DB_NAME(), 'MaxSizeInBytes') AS bigint)) / 1024.0 / 1024 / 1024


-- "Space Available" like SSMS = MAXSIZE - current_size
-- (Use the latest storage_in_megabytes per sys.resource_stats or compute from data+log)
