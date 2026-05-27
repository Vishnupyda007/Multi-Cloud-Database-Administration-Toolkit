    DECLARE @sql NVARCHAR(MAX)
    DECLARE @dbname NVARCHAR(128)


IF OBJECT_ID('#DatabaseFileStats') is not null
    DROP Table #DatabaseFileStats

    -- Create a temporary table to store results
    CREATE TABLE #DatabaseFileStats (
        ServerName NVARCHAR(128),
        DBName NVARCHAR(128),
        [Name] NVARCHAR(128),
        FileId INT,
        PhysicalName NVARCHAR(260),
        TotalSizeGB NVARCHAR(50),
        AvailableSpaceGB NVARCHAR(50),
        UsedSpaceGB NVARCHAR(50),
        PercentageUsed NVARCHAR(50),
        TotalDatabaseSizeGB NVARCHAR(50),
        PercentageOfTotalGBUsed NVARCHAR(10),
        TotalDataFileSizeGB NVARCHAR(50),
        TotalLogFileSizeGB NVARCHAR(50)
    )

    -- Loop through each database
    DECLARE db_cursor CURSOR FOR
    SELECT name FROM sys.databases WITH (NOLOCK) WHERE state_desc = 'ONLINE'

    OPEN db_cursor
    FETCH NEXT FROM db_cursor INTO @dbname

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Set up the dynamic SQL for each database
        SET @sql = N'
            USE ' + QUOTENAME(@dbname) + ';
            WITH FileStats AS (
                SELECT 
                    @@servername AS ServerName,
                    DB_NAME() AS DBName,
                    [name],
                    file_id,
                    physical_name,
                    [size] / 128.0 / 1024.0 AS TotalSizeGB,
                    (CAST(FILEPROPERTY(name, ''SpaceUsed'') AS int) / 128.0 / 1024.0) AS UsedSpaceGB,
                    ([size] / 128.0 / 1024.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS int) / 128.0 / 1024.0) AS AvailableSpaceGB,
                    (100.0 * (CAST(FILEPROPERTY(name, ''SpaceUsed'') AS int) / 128.0 / 1024.0) / ([size] / 128.0 / 1024.0)) AS PercentageUsed,
                    ROW_NUMBER() OVER (PARTITION BY DB_NAME() ORDER BY file_id) AS RowNum,
                    SUM([size] / 128.0 / 1024.0) OVER() AS TotalDatabaseSizeGB,
                    (100.0 * SUM(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS int) / 128.0 / 1024.0) OVER() / SUM([size] / 128.0 / 1024.0) OVER()) AS PercentageOfTotalGBUsed,
					 SUM(CASE WHEN [type_desc] = ''ROWS'' THEN [size] / 128.0 / 1024.0 ELSE 0 END) OVER() AS TotalDataFileSizeGB,
                SUM(CASE WHEN [type_desc] = ''LOG'' THEN [size] / 128.0 / 1024.0 ELSE 0 END) OVER() AS TotalLogFileSizeGB
                FROM sys.database_files WITH (NOLOCK)
                WHERE [type_desc] != ''XTP''
            )
            INSERT INTO #DatabaseFileStats
            SELECT 
                ServerName,
                DBName,
                [name],
                file_id,
                physical_name,
                TotalSizeGB,
                AvailableSpaceGB,
                UsedSpaceGB,
                PercentageUsed,
                CASE WHEN RowNum = 1 THEN CAST(TotalDatabaseSizeGB AS NVARCHAR(50)) ELSE '' '' END AS TotalDatabaseSizeGB,
                CASE WHEN RowNum = 1 THEN CAST(PercentageOfTotalGBUsed AS NVARCHAR(10)) ELSE '' '' END AS PercentageOfTotalGBUsed,
				CASE WHEN RowNum = 1 THEN CAST(TotalDataFileSizeGB AS NVARCHAR(50))  else '' '' END as TotalDataFileSizeGB,
            CASE WHEN RowNum = 1 THEN CAST(TotalLogFileSizeGB AS NVARCHAR(50))  else '' '' END AS TotalLogFileSizeGB
            FROM FileStats WITH (NOLOCK)
            WHERE [Name] != ''XTP''
        '

        -- Execute the dynamic SQL
        EXEC sp_executesql @sql

        FETCH NEXT FROM db_cursor INTO @dbname
    END

    CLOSE db_cursor
    DEALLOCATE db_cursor

    -- Select the results from the temporary table
    SELECT distinct  * FROM #DatabaseFileStats with(nolock) order by ServerName,DBName,FileId ASC

    -- Drop the temporary table
   DROP TABLE #DatabaseFileStats
