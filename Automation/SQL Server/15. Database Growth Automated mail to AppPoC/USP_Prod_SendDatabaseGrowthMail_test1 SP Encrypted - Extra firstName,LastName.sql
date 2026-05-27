alter PROCEDURE USP_Prod_SendDatabaseGrowthMail_test2
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    -- Drop the temporary table if it already exists to ensure a clean run
    IF OBJECT_ID('tempdb..#GrowthData') IS NOT NULL DROP TABLE #GrowthData;

    -- CTE to get the latest database capacity data for the current month and year
    WITH LatestMonthData AS (
        SELECT
            *,
            -- Assign a row number to pick the latest entry for each Server, DB, and Name combination
            ROW_NUMBER() OVER (PARTITION BY ServerName, DBName, Name
                                ORDER BY Datetime DESC) AS rn
        FROM [MI_Prod_DB_Capacity_Report] WITH (NOLOCK)
        WHERE
            -- Filter for data belonging to the current month and year
            DATENAME(MONTH, Datetime) = DATENAME(MONTH, GETDATE()) AND
            YEAR(Datetime) = YEAR(GETDATE())
    )
    -- Populate the #GrowthData temporary table with calculated growth metrics
    SELECT
        a.ServerName,
        a.DBName AS DatabaseName,
        ROUND(CAST(a.TotalDatabaseSizeGB AS FLOAT), 4) AS TotalDatabaseSizeGB,
        ROUND(CAST(a.TotalDataFileSizeGB AS FLOAT), 4) AS TotalDataFileSizeGB,
        -- Baseline data size from MI_Prod_DB_Capacity_Daily_STG
        ROUND(CAST(b.TotalDataFileSizeGB AS FLOAT), 4) AS TotalDataFileSizeGB_Jan1,
        -- Calculate the absolute change in data file size
        ROUND(CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT), 4) AS TotalDataFileSizeChange,
        ROUND(CAST(a.PercentageOfTotalGBUsed AS FLOAT), 4) AS PercentageOfTotalGBUsed,
        -- Calculate the percentage change in data file size
        ROUND(
            CASE
                WHEN ISNUMERIC(b.TotalDataFileSizeGB) = 1 AND CAST(b.TotalDataFileSizeGB AS FLOAT) <> 0
                THEN ((CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT)) / CAST(b.TotalDataFileSizeGB AS FLOAT)) * 100
                ELSE NULL
            END, 2
        ) AS TotalDataFileSizeGB_PercentChange,
        FORMAT(a.Datetime, 'dd-MM-yyyy') AS FormattedDate,
        -- Determine database size status (Increased, Decreased, No Change)
        CASE
            WHEN CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT) > 0 THEN 'Increased'
            WHEN CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT) < 0 THEN 'Decreased'
            ELSE 'No Change'
        END AS DatabaseSizeStatus,
        -- Assign a color for status display in HTML email
        CASE
            WHEN CAST(a.TotalDataFileSizeGB AS FLOAT) - CAST(b.TotalDataFileSizeGB AS FLOAT) > 0 THEN 'red'
            ELSE 'green'
        END AS StatusColor
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
        -- Current baseline is fixed to '2025-05-27'.
        CAST(b.Datetime AS DATE) = '2025-05-27'
        --CAST(b.Datetime AS DATE) = DATEFROMPARTS(YEAR(GETDATE()),1,1) --January 1st baseline
        AND a.rn = 1 -- Ensure we only take the latest record for the current month
        AND a.DBName NOT IN ('master','model','msdb','tempdb') -- Exclude system databases
        AND (a.PercentageOfTotalGBUsed <> '' OR a.TotalDatabaseSizeGB <> ''); -- Ensure relevant columns are not empty

    -- Declare variables for cursor and email details
    DECLARE @AppPoC NVARCHAR(300);
    DECLARE @RecipientName NVARCHAR(300); -- New variable for the extracted name
    DECLARE @EmailBody NVARCHAR(MAX);
    DECLARE @AppName NVARCHAR(300);
    DECLARE @Subject NVARCHAR(500);

    -- Declare a cursor to iterate through distinct Application POCs and Application Names
    -- associated with databases that have at least 0% growth (or more) in #GrowthData
    DECLARE AppPoC_Cursor CURSOR FOR
    SELECT DISTINCT ai.AppPoC, ai.ApplicationName
    FROM #GrowthData gd
    JOIN ApplicationInventory ai
        ON gd.ServerName = ai.ServerName AND gd.DatabaseName = ai.DatabaseName
    WHERE gd.TotalDataFileSizeGB_PercentChange >= 0 and gd.TotalDatabaseSizeGB >= 1-- Only process AppPoCs with non-negative growth
    ORDER BY ai.AppPoC;

    OPEN AppPoC_Cursor;
    FETCH NEXT FROM AppPoC_Cursor INTO @AppPoC, @AppName;

    -- Loop through each unique AppPoC
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Subject = 'test-Database Growth Alert for Application: ' + @AppName + ' || 1C Production';

        -- Extract the name from the email address for a personalized greeting
        -- This logic assumes the format 'firstname.lastname@domain.com' or 'firstname.initial@domain.com'
        SET @RecipientName = LEFT(@AppPoC, CHARINDEX('@', @AppPoC) - 1);
        SET @RecipientName = REPLACE(@RecipientName, '.', ' '); -- Replace dots with spaces
        SET @RecipientName = REPLACE(@RecipientName, SUBSTRING(@RecipientName, LEN(@RecipientName), 1), UPPER(SUBSTRING(@RecipientName, LEN(@RecipientName), 1))); -- Capitalize last initial if present
        SET @RecipientName = STUFF(@RecipientName, 1, 1, UPPER(LEFT(@RecipientName, 1))); -- Capitalize the first letter of the first name
        SET @RecipientName = LTRIM(RTRIM(@RecipientName)); -- Trim any leading/trailing spaces

        -- Further refine capitalization for names like "sneha.s5" to "Sneha S."
        -- This handles cases where there's an initial and potentially a number
        IF CHARINDEX(' ', @RecipientName) > 0
        BEGIN
            SET @RecipientName = LEFT(@RecipientName, CHARINDEX(' ', @RecipientName) - 1) + ' ' + UPPER(SUBSTRING(@RecipientName, CHARINDEX(' ', @RecipientName) + 1, 1)) + SUBSTRING(@RecipientName, CHARINDEX(' ', @RecipientName) + 2, LEN(@RecipientName));
        END
        -- If it's like "sneha.s5", ensure "S5" becomes "S. 5" or just "S."
        IF PATINDEX('%[0-9]%', @RecipientName) > 0
        BEGIN
            SET @RecipientName = REPLACE(@RecipientName, SUBSTRING(@RecipientName, PATINDEX('%[0-9]%', @RecipientName)-1, 1), UPPER(SUBSTRING(@RecipientName, PATINDEX('%[0-9]%', @RecipientName)-1, 1)) + '. ');
            SET @RecipientName = REPLACE(@RecipientName, SUBSTRING(@RecipientName, PATINDEX('%[0-9]%', @RecipientName), 1), ''); -- Remove the number
            SET @RecipientName = LTRIM(RTRim(REPLACE(@RecipientName, '.', ' ')));
        END
        SET @RecipientName = REPLACE(@RecipientName, ' ', '. ') + '.'; -- Add a dot after initials/last names
        SET @RecipientName = REPLACE(@RecipientName, '. .', '.'); -- Clean up double dots
        SET @RecipientName = REPLACE(@RecipientName, ' .', '.'); -- Clean up space before dot
        SET @RecipientName = REPLACE(@RecipientName, '..', '.'); -- Clean up double dots


        -- Construct the HTML email body with embedded styles
        SET @EmailBody =
            N'<style>' + -- Start of style block
            N'table, th, td { ' +
            N'border:1px solid black; ' +
            N'border-collapse: collapse; ' +
            N'font-family:Serif; ' +
            N'text-align: center; ' +
            N'padding: 3px; ' +
            N'font-size: 10.5pt; ' +
            N'} ' +
            N'th { ' +
            N'background:#87ceeb; ' +
            N'} ' +
            N'p,h5 { ' +
            N'font-family:Serif; ' +
            N'} ' +
            N'</style>' + -- End of style block
            '<p>Hi ' + @RecipientName + ',</p>' + -- Use the extracted name here
            '<p>This notification is to inform you about significant database growth observed for your application: <strong>' + @AppName + '</strong> in our Production environment. The databases listed below have grown by 10% or more since the ' + FORMAT(CAST('2025-05-27' AS DATE), 'dd MMMM yyyy') + ' baseline. Your review of the provided details for potential data optimization and purging is highly appreciated:</p>' +
            -- Main database growth table section
            (
                SELECT
                    '<h5><font face="Lucida Bright" color="blue">Server Name: ' + gd.ServerName + '</font></h5>' +
                    '<table border="1" cellpadding="5" cellspacing="0" style="width:100%; border-collapse: collapse;">' +
                    '<tr style="background-color:#f2f2f2;"><th>DB Name</th><th>Total DB Size(GB)</th>' +
                    '<th>Total DataFile Size(GB)</th><th>Baseline DataFile Size(GB)</th>' +
                    '<th>DataFile Size Change(GB)</th><th>Total GB Used(in %)</th>' +
                    '<th>Percent Change From Baseline</th><th>Growth Status</th><th>Data As Of Date</th></tr>' +
                    (
                        SELECT
                            '<tr><td>' + ISNULL(gd.DatabaseName, 'N/A') + '</td><td>' +
                            ISNULL(CAST(gd.TotalDatabaseSizeGB AS NVARCHAR), 'N/A') + '</td><td>' +
                            ISNULL(CAST(gd.TotalDataFileSizeGB AS NVARCHAR), 'N/A') + '</td><td>' +
                            ISNULL(CAST(gd.TotalDataFileSizeGB_Jan1 AS NVARCHAR), 'N/A') + '</td><td>' +
                            ISNULL(CAST(gd.TotalDataFileSizeChange AS NVARCHAR), 'N/A') + '</td><td>' +
                            ISNULL(CAST(gd.PercentageOfTotalGBUsed AS NVARCHAR), 'N/A') + '</td><td>' +
                            ISNULL(CAST(gd.TotalDataFileSizeGB_PercentChange AS NVARCHAR), 'N/A') + '%</td><td style="color:' +
                            ISNULL(gd.StatusColor, 'black') + ';">' + ISNULL(gd.DatabaseSizeStatus, 'N/A') + '</td><td>' +
                            ISNULL(gd.FormattedDate, 'N/A') + '</td></tr>'
                        FROM #GrowthData gd
                        JOIN ApplicationInventory ai
                            ON gd.ServerName = ai.ServerName AND gd.DatabaseName = ai.DatabaseName
                        WHERE
                            ai.AppPoC = @AppPoC
                            AND gd.TotalDataFileSizeGB_PercentChange >= 0 and gd.TotalDatabaseSizeGB >= 1
                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)') +
                    '</table>'
                    +
                    -- Top 10 Tables Report for each database
                    (
                        SELECT
                            '<br/>' +
                            '<h5><font face="Lucida Bright" color="blue">Top 10 Largest Tables in ' + gd.DatabaseName + ' on ' + gd.ServerName + ' :</font></h5>' +
                            '<table border="1" cellpadding="5" cellspacing="0"; border-collapse: collapse;">' +
                            '<tr style="background-color:#f2f2f2;"><th>Table Name</th><th>Total Rows</th><th>Table Size(GB)</th></tr>' +
                            (
                                SELECT top 10
                                    '<tr><td>' + ISNULL(tt.TableName, 'N/A') + '</td><td>' +
                                    ISNULL(CAST(tt.TotalRows AS NVARCHAR), 'N/A') + '</td><td>' +
                                    ISNULL(CAST(tt.TableSizeGB AS NVARCHAR), 'N/A') + '</td></tr>'
                                FROM [dbo].[Top_ten_tables_of_Each_Database_Prod_tbl] tt WITH (NOLOCK)
                                WHERE
                                    tt.DatabaseName = gd.DatabaseName
                                    AND tt.ServerName = gd.ServerName
                                    -- Use MAX(CaptureDate) to get the latest data, not necessarily today.
                                    AND CAST(tt.CaptureDate AS DATE) = (SELECT MAX(CAST(CaptureDate AS DATE)) FROM [dbo].[Top_ten_tables_of_Each_Database_Prod_tbl]
                                    WHERE ServerName = tt.ServerName AND DatabaseName = tt.DatabaseName)
                                ORDER BY tt.TableSizeGB DESC
                                FOR XML PATH(''), TYPE
                            ).value('.', 'NVARCHAR(MAX)') +
                            '</table>'
                        FROM #GrowthData gd_sub
                        WHERE gd_sub.ServerName = gd.ServerName
                            AND gd_sub.DatabaseName = gd.DatabaseName
                            AND gd_sub.TotalDataFileSizeGB_PercentChange >= 0 and gd_sub.TotalDatabaseSizeGB >= 1
                        GROUP BY gd_sub.ServerName, gd_sub.DatabaseName, gd_sub.TotalDatabaseSizeGB
                        FOR XML PATH(''), TYPE
                    ).value('.', 'NVARCHAR(MAX)')
                FROM #GrowthData gd
                JOIN ApplicationInventory ai
                    ON gd.ServerName = ai.ServerName AND gd.DatabaseName = ai.DatabaseName
                WHERE
                    ai.AppPoC = @AppPoC
                    AND gd.TotalDataFileSizeGB_PercentChange >= 0 and gd.TotalDatabaseSizeGB >= 1
                GROUP BY gd.ServerName, gd.DatabaseName, gd.TotalDatabaseSizeGB
                ORDER BY gd.ServerName, gd.DatabaseName
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') -- Convert this main XML fragment to NVARCHAR(MAX) string
            + '<br/><br/>'
            + '<p style="font-family:Serif;"><b>Note:</b> This is an auto generated mail from 1C DBA Team, please reach to DL: <a href="mailto:CRSDBASUPPORT@cognizant.com">CRSDBASUPPORT@cognizant.com</a> for further steps/queries.</p>' -- Inline style
            + '<br/><p style="font-family:Serif;">Thanks &amp; Regards,<br/><b>ITOps 1C DBA Team<b></p>'; -- Wrapped in <p> with inline style


        -- Only send an email if there's content in the @EmailBody (i.e., if growth criteria were met)
        IF @EmailBody IS NOT NULL AND LTRIM(RTRIM(@EmailBody)) <> ''
        BEGIN
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'ITOps1CDBA',
                @recipients = @AppPoC,
                @copy_recipients='kirankumar.gannavaram@cognizant.com;ashwathi.k@cognizant.com;balakrishna.mannepalli@cognizant.com;vijaianand.pv@cognizant.com;2275509@cognizant.com',
                @subject = @Subject,
                @body = @EmailBody,
                @body_format = 'HTML';
        END

        FETCH NEXT FROM AppPoC_Cursor INTO @AppPoC, @AppName
    END;
    select * from #GrowthData where TotalDataFileSizeGB_PercentChange >= 0 and TotalDatabaseSizeGB >= 1
    --and DatabaseName in ('OneC_714','OneC_2190','Onec_Mycareer','Onec_Onboarding','Onec_988','Onec_2381')
    -- Clean up the cursor
    CLOSE AppPoC_Cursor;
    DEALLOCATE AppPoC_Cursor;

    -- Drop the temporary table at the end of the procedure
    DROP TABLE #GrowthData;
END;
GO