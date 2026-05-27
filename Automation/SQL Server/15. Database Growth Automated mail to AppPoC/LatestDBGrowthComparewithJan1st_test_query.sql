;WITH LatestMonthData AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY ServerName, DBName, Name 
                              ORDER BY Datetime DESC) AS rn
    FROM [MI_Prod_DB_Capacity_Report] WITH (NOLOCK)
    WHERE 
        DATENAME(MONTH, Datetime) = DATENAME(MONTH, GETDATE()) AND
        YEAR(Datetime) = YEAR(GETDATE())
)

SELECT DISTINCT
    a.ServerName,
    a.DBName,
    a.FileId,
    ROUND(CAST(a.TotalDatabaseSizeGB AS FLOAT), 4) AS TotalDatabaseSizeGB,
    ROUND(CAST(a.TotalDataFileSizeGB AS FLOAT), 4) AS TotalDataFileSizeGB,
    ROUND(CAST(b.TotalDataFileSizeGB AS FLOAT), 4) AS TotalDataFileSizeGB_Jan1,
    FORMAT(ROUND(CAST(a.TotalDataFileSizeGB AS FLOAT), 4) - ROUND(CAST(b.TotalDataFileSizeGB AS FLOAT), 4), 'N4') AS TotalDataFileSizeChange,
    ROUND(CAST(a.PercentageOfTotalGBUsed AS FLOAT), 4) AS PercentageOfTotalGBUsed,
    FORMAT(
        CASE 
            WHEN ISNUMERIC(b.TotalDataFileSizeGB) = 1 AND CAST(b.TotalDataFileSizeGB AS FLOAT) <> 0 
            THEN ((CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT)) / CAST(b.TotalDataFileSizeGB AS FLOAT)) * 100 
            ELSE NULL 
        END, 'N2'
    ) AS TotalDataFileSizeGB_PercentChange,
    FORMAT(a.Datetime, 'dd-MM-yyyy') AS FormattedDate,
    CASE 
        WHEN CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT) > 0 THEN 'Increased'
        WHEN CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT) < 0 THEN 'Decreased'
        ELSE 'No Change'
    END AS DatabaseSizeStatus
FROM 
    LatestMonthData a
JOIN 
    [MI_Prod_DB_Capacity_Daily_STG] b WITH (NOLOCK)
ON 
    a.DBName = b.DBName 
    AND a.ServerName = b.ServerName 
    AND a.Name = b.Name

WHERE 
    CAST(b.Datetime AS DATE) = '2025-05-27'
 AND
    a.rn = 1 AND
    a.DBName NOT IN ('master','model','msdb','tempdb') and (a.PercentageOfTotalGBUsed <> '' OR a.TotalDatabaseSizeGB <> '')


--select distinct Datetime from  MI_Prod_DB_Capacity_Daily_STG order by datetime asc
