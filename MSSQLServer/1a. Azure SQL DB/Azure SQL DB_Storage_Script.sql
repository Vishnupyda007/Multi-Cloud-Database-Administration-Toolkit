SELECT
    DB_NAME() AS DatabaseName,
    CAST(SUM(CAST(size AS BIGINT)) * 8 / 1024.0 AS DECIMAL(18,2)) AS TotalSizeMB,
    CAST(SUM(CASE WHEN type = 0 THEN CAST(size AS BIGINT) * 8 / 1024.0 ELSE 0 END) AS DECIMAL(18,2)) AS DataSizeMB,
    CAST(SUM(CASE WHEN type = 1 THEN CAST(size AS BIGINT) * 8 / 1024.0 ELSE 0 END) AS DECIMAL(18,2)) AS LogSizeMB,
    CAST(SUM(CAST(max_size AS BIGINT)) * 8 / 1024.0 AS DECIMAL(18,2)) AS MaxSizeMB
FROM
    sys.database_files
WHERE
    type IN (0, 1) -- 0 = Data files, 1 = Log files


