       SELECT 
            a.ServerName,
            a.DBName,
            a.FileId,
            ROUND(CAST(a.TotalDatabaseSizeGB AS FLOAT), 4) AS TotalDatabaseSizeGB,
            ROUND(CAST(a.TotalDataFileSizeGB AS FLOAT), 4) AS TotalDataFileSizeGB,
			ROUND(CAST(b.TotalDataFileSizeGB AS FLOAT), 4) AS TotalDataFileSizeGB_OneWeekAgo,
            FORMAT(ROUND(CAST(a.TotalDatabaseSizeGB AS FLOAT), 4) - ROUND(CAST(b.TotalDataFileSizeGB AS FLOAT), 4), 'N4') AS TotalDataFileSizeChange,
            ROUND(CAST(a.PercentageOfTotalGBUsed AS FLOAT), 4) AS PercentageOfTotalGBUsed,
            ROUND(CAST(b.PercentageOfTotalGBUsed AS FLOAT), 4) AS PercentageOfTotalGBUsed_OneWeekAgo,
            FORMAT(ROUND(CAST(a.PercentageOfTotalGBUsed AS FLOAT), 4) - ROUND(CAST(b.PercentageOfTotalGBUsed AS FLOAT), 4), 'N4') AS PercentageOfTotalGBUsedChange,
            FORMAT(a.Datetime, 'dd-MM-yyyy') AS FormattedDate,
            ROW_NUMBER() OVER (PARTITION BY a.ServerName, a.DBName, a.FileId ORDER BY (SELECT NULL)) AS RowNum
        FROM 
            [MI_Prod_DB_Capacity_Report] a with(nolock) 
        LEFT JOIN 
            (SELECT 
                ServerName, DBName, Name, TotalDataFileSizeGB, PercentageOfTotalGBUsed, Datetime
             FROM 
                [MI_Prod_DB_Capacity_Daily_STG] with(nolock) 
             WHERE 
                CAST(Datetime AS DATE) = DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
            ) b
        ON 
            a.DBName = b.DBName 
            AND a.ServerName = b.ServerName 
            AND a.Name = b.Name
        WHERE 
            (a.PercentageOfTotalGBUsed <> '' OR a.TotalDatabaseSizeGB <> '')
and a.Datetime >= CAST(GETDATE() AS DATE) and a.DBName not in ('master','model','msdb','tempdb')