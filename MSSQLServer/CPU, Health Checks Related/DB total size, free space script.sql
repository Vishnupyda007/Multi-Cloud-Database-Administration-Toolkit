SELECT
    DB_NAME(database_id) AS DatabaseName,
    SUM(size * 8.0 / 1024 / 1024) AS TotalSize_GB,
    SUM(size * 8.0 / 1024 / 1024)
    - SUM(FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 / 1024) AS ConsumedSize_GB,
    SUM(size * 8.0 / 1024 / 1024)
    - SUM(FILEPROPERTY(name, 'SpaceUsed') * 8.0 / 1024 / 1024) AS AvailableFreeSize_GB
FROM
    sys.master_files
GROUP BY
    database_id;

---------------- query in MB-----------

SELECT
    DB_NAME(database_id) AS DatabaseName,
    SUM(size) / 128.0 AS TotalSize_MB,
    SUM(size) / 128.0 - SUM(FILEPROPERTY(name, 'SpaceUsed')) / 128.0 AS ConsumedSize_MB,
    SUM(size) / 128.0 - SUM(FILEPROPERTY(name, 'SpaceUsed')) / 128.0 AS AvailableFreeSize_MB
FROM
    sys.master_files
GROUP BY
    database_id;

-------------------------------------

-- Query to check space of a database in sql server
SELECT
  [database_name] = DB_NAME([database_id]),
  [log_size_mb] = CAST(SUM(CASE
        WHEN [type_desc] = 'LOG' THEN [size]
        ELSE 0
    END
      ) * 8.0 / 1024 AS DECIMAL(8,
      2)),
  [data_size_mb] = CAST(SUM(CASE
        WHEN [type_desc] = 'ROWS' THEN [size]
        ELSE 0
    END
      ) * 8.0 / 1024 AS DECIMAL(8,
      2)),
  [total_size_mb] = CAST(SUM([size]) * 8.0 / 1024 AS DECIMAL(8,
      2))
FROM
  sys.master_files
--WHERE
  --[database_id] = DB_ID()
GROUP BY
  [database_id];