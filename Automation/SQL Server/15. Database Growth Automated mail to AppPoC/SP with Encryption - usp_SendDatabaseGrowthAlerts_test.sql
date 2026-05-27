
ALTER PROCEDURE usp_SendDatabaseGrowthAlerts_test --another consider
with ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#GrowthData') IS NOT NULL DROP TABLE #GrowthData;

    WITH LatestMonthData AS (
        SELECT *, 
               ROW_NUMBER() OVER (PARTITION BY ServerName, DBName, Name 
                                  ORDER BY Datetime DESC) AS rn
        FROM [MI_Prod_DB_Capacity_Report] WITH (NOLOCK)
        WHERE 
            DATENAME(MONTH, Datetime) = DATENAME(MONTH, GETDATE()) AND
            YEAR(Datetime) = YEAR(GETDATE())
    )
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
        CASE 
            WHEN CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT) > 0 THEN 'Increased'
            WHEN CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT) < 0 THEN 'Decreased'
            ELSE 'No Change'
        END AS DatabaseSizeStatus,
        CASE 
            WHEN CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT) > 0 THEN 'red'
            ELSE 'green'
        END AS StatusColor,
        FORMAT(a.Datetime, 'dd-MM-yyyy') AS FormattedDate
    INTO #GrowthData
    FROM 
        LatestMonthData a
    JOIN 
        [MI_Prod_DB_Capacity_Daily_STG] b WITH (NOLOCK)
    ON 
        a.DBName = b.DBName 
        AND a.ServerName = b.ServerName 
        AND a.Name = b.Name
    WHERE 
        CAST(b.Datetime AS DATE) = '2025-05-27' --as of now baseline
        --CAST(b.Datetime AS DATE) = DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
        AND a.rn = 1
        AND a.DBName NOT IN ('master','model','msdb','tempdb')
        AND (a.PercentageOfTotalGBUsed <> '' OR a.TotalDatabaseSizeGB <> '');

    DECLARE @AppPoC NVARCHAR(300)
    DECLARE @EmailBody NVARCHAR(MAX)

    DECLARE AppPoC_Cursor CURSOR FOR
    SELECT DISTINCT ai.AppPoC
    FROM #GrowthData gd
    JOIN ApplicationInventory ai
        ON gd.ServerName = ai.ServerName AND gd.DatabaseName = ai.DatabaseName
    WHERE gd.TotalDataFileSizeGB_PercentChange > 10

    OPEN AppPoC_Cursor
    FETCH NEXT FROM AppPoC_Cursor INTO @AppPoC

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @EmailBody = (
            SELECT 
                '<h4>Server Name: ' + gd.ServerName + '</h4>' +
                '<table border="1" cellpadding="5" cellspacing="0">' +
                '<tr><th>DatabaseName</th><th>TotalDatabaseSizeGB</th>' +
                '<th>TotalDataFileSizeGB</th><th>TotalDataFileSizeGB_Jan1</th>' +
                '<th>TotalDataFileSizeChange</th><th>PercentageOfTotalGBUsed</th>' +
                '<th>TotalDataFileSizeGB_PercentChange</th><th>DatabaseSizeStatus</th><th>FormattedDate</th></tr>' +
                (
                    SELECT 
                        '<tr><td>' + gd.DatabaseName + '</td><td>' +
                        CAST(gd.TotalDatabaseSizeGB AS NVARCHAR) + '</td><td>' +
                        CAST(gd.TotalDataFileSizeGB AS NVARCHAR) + '</td><td>' +
                        CAST(gd.TotalDataFileSizeGB_Jan1 AS NVARCHAR) + '</td><td>' +
                        CAST(gd.TotalDataFileSizeChange AS NVARCHAR) + '</td><td>' +
                        CAST(gd.PercentageOfTotalGBUsed AS NVARCHAR) + '</td><td>' +
                        CAST(gd.TotalDataFileSizeGB_PercentChange AS NVARCHAR) + '%</td><td style="color:' +
                        CASE 
                            WHEN CAST(gd.TotalDataFileSizeChange AS FLOAT) > 0 THEN 'red'
                            ELSE 'green'
                        END + ';">' + gd.DatabaseSizeStatus + '</td><td>' +
                        gd.FormattedDate + '</td></tr>'
                    FROM #GrowthData gd
                    JOIN ApplicationInventory ai
                        ON gd.ServerName = ai.ServerName AND gd.DatabaseName = ai.DatabaseName
                    WHERE ai.AppPoC = @AppPoC AND gd.TotalDataFileSizeGB_PercentChange > 10
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)') +
                '</table>'
            FROM #GrowthData gd
            JOIN ApplicationInventory ai
                ON gd.ServerName = ai.ServerName AND gd.DatabaseName = ai.DatabaseName
            WHERE ai.AppPoC = @AppPoC AND gd.TotalDataFileSizeGB_PercentChange > 10
            GROUP BY gd.ServerName
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)')

        SET @EmailBody = 
            '<html><body><h3>Database Growth Alert</h3>' + @EmailBody + 
            '<br/><br/>Thanks &amp; Regards,<br/>1C DBA Team</body></html>'

        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ITOps1CDBA',
            @recipients = @AppPoC,
            @subject = 'Database Growth Alert - Over 10%',
            @body = @EmailBody,
            @body_format = 'HTML'

        FETCH NEXT FROM AppPoC_Cursor INTO @AppPoC
    END

    CLOSE AppPoC_Cursor
    DEALLOCATE AppPoC_Cursor
END
GO
