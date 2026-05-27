CREATE VIEW dbo.vw_DatabaseGrowthDashboard AS
SELECT
    a.ServerName,
    a.DBName AS DatabaseName,
    ROUND(CAST(a.TotalDatabaseSizeGB AS FLOAT), 4) AS TotalDatabaseSizeGB,
    ROUND(CAST(a.TotalDataFileSizeGB AS FLOAT), 4) AS TotalDataFileSizeGB,
    ROUND(CAST(b.TotalDataFileSizeGB AS FLOAT), 4) AS TotalDataFileSizeGB_Jan1,
    ROUND(CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT), 4) AS TotalDataFileSizeChange,
    ROUND(CAST(a.PercentageOfTotalGBUsed AS FLOAT), 4) AS PercentageOfTotalGBUsed,
    ROUND(
        CASE
            WHEN ISNUMERIC(b.TotalDataFileSizeGB) = 1 AND CAST(b.TotalDataFileSizeGB AS FLOAT) <> 0
            THEN ((CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT)) / CAST(b.TotalDataFileSizeGB AS FLOAT)) * 100
            ELSE NULL
        END, 2
    ) AS TotalDataFileSizeGB_PercentChange,
    FORMAT(a.Datetime, 'dd-MM-yyyy') AS FormattedDate,
    CASE
        WHEN CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT) > 0 THEN 'Increased'
        WHEN CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT) < 0 THEN 'Decreased'
        ELSE 'No Change'
    END AS DatabaseSizeStatus
FROM
    [MI_Prod_DB_Capacity_Report] a
JOIN
    [MI_Prod_DB_Capacity_Daily_STG] b
ON
    a.DBName = b.DBName
    AND a.ServerName = b.ServerName
    AND a.Name = b.Name
WHERE
    CAST(b.Datetime AS DATE) = '2025-05-27'
    AND YEAR(a.Datetime) = YEAR(GETDATE())
    AND DATENAME(MONTH, a.Datetime) = DATENAME(MONTH, GETDATE())
    AND a.DBName NOT IN ('master','model','msdb','tempdb')
    AND (a.PercentageOfTotalGBUsed <> '' OR a.TotalDatabaseSizeGB <> '');