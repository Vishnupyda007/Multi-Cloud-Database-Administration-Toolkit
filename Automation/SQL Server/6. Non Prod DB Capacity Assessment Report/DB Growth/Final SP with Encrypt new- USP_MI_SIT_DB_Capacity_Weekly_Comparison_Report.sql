USE [1CDBAMonitoring]
GO

/****** Object:  StoredProcedure [dbo].[USP_MI_SIT_DB_Capacity_Weekly_Comparison_Report]    Script Date: 2/11/2025 10:33:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
/****** Object:  StoredProcedure [dbo].[USP_MI_SIT_DB_Capacity_Weekly_Comparison_Report]        
--SET ANSI_NULLS ON        
--GO        
--SET QUOTED_IDENTIFIER ON        
--GO        
-- =============================================        
-- Author:  <Hima Vishnu P>        
-- Create date: <6:30PM,08 April,2025>        
-- Description: <Description,,>       
--- EXEC [USP_MI_SIT_DB_Capacity_Weekly_Comparison_Report]   
------ ============================================= ***/  
ALTER PROCEDURE [dbo].[USP_MI_SIT_DB_Capacity_Weekly_Comparison_Report] with encryption
AS
BEGIN
    CREATE TABLE #temp_SIT_DB_Weekly_Comparison (
        ServerName NVARCHAR(128),
        DBName NVARCHAR(128),
        FileId INT,
        TotalDatabaseSizeGB NVARCHAR(50),
        TotalDataFileSizeGB NVARCHAR(50),
	TotalDataFileSizeGB_OneWeekAgo NVARCHAR(50),
        TotalDataFileSizeChange NVARCHAR(50),
        PercentageOfTotalGBUsed NVARCHAR(10),
        PercentageOfTotalGBUsed_OneWeekAgo NVARCHAR(10),
        PercentageOfTotalGBUsedChange NVARCHAR(10),
        FormattedDate NVARCHAR(100),
        DatabaseSizeStatus NVARCHAR(50) -- New column
    );  
    
    INSERT INTO #temp_SIT_DB_Weekly_Comparison 
    SELECT DISTINCT
        ServerName,
        DBName,
        FileId,
        TotalDatabaseSizeGB,
		TotalDataFileSizeGB,
        TotalDataFileSizeGB_OneWeekAgo,
        TotalDataFileSizeChange,
        PercentageOfTotalGBUsed,
        PercentageOfTotalGBUsed_OneWeekAgo,
        PercentageOfTotalGBUsedChange,
        FormattedDate,
        CASE 
            WHEN CAST(TotalDataFileSizeChange AS FLOAT) > 0 THEN 'Increased'
            WHEN CAST(TotalDataFileSizeChange AS FLOAT) < 0 THEN 'Decreased'
            ELSE 'No Change'
        END AS DatabaseSizeStatus -- Logic for new column
    FROM (
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
            [MI_SIT_DB_Capacity_Report] a
        LEFT JOIN 
            (SELECT 
                ServerName, DBName, Name, TotalDataFileSizeGB, PercentageOfTotalGBUsed, Datetime
             FROM 
                [MI_SIT_DB_Capacity_Daily_STG]
             WHERE 
                CAST(Datetime AS DATE) = DATEADD(DAY, -1, CAST(GETDATE() AS DATE))
            ) b
        ON 
            a.DBName = b.DBName 
            AND a.ServerName = b.ServerName 
            AND a.Name = b.Name
        WHERE 
            (a.PercentageOfTotalGBUsed <> '' OR a.TotalDatabaseSizeGB <> '')
and a.Datetime >= CAST(GETDATE() AS DATE)
    ) AS sub 
    WHERE RowNum = 1;

    -- Debug print to check data in the temporary table
    SELECT * FROM #temp_SIT_DB_Weekly_Comparison;

    DECLARE @body_HTML NVARCHAR(MAX) = N'';  
    DECLARE @hasData BIT = 0;  

    -- Generate HTML content for all servers
    WITH ServerData AS (
        SELECT DISTINCT ServerName,
            CASE 
                WHEN ServerName = 'ctsazsimisitde1.inso13dfbbbfa2150.database.windows.net' THEN 'SITDE1'
                WHEN ServerName = 'ctsazsimisstfd1.inso13dfbbbfa2150.database.windows.net' THEN 'SSTFD1'
                WHEN ServerName = 'ctsazsimisgntm1.inso13dfbbbfa2150.database.windows.net' THEN 'SGNTM1'
                WHEN ServerName = 'ctsazsimisplt01.inso13dfbbbfa2150.database.windows.net' THEN 'SPLT01'
                WHEN ServerName = 'ctsazsimisnc02.inso13dfbbbfa2150.database.windows.net' THEN 'SNC02'
                WHEN ServerName = 'ctsinazqaedssqlmi.inso13dfbbbfa2150.database.windows.net' THEN 'EDS QA'
                ELSE 'Unknown'
            END AS ServerDisplayName
        FROM #temp_SIT_DB_Weekly_Comparison
    )
    SELECT @body_HTML = @body_HTML + 
        N'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">' + ServerDisplayName + ' DB Capacity Status:</font></H2>
        <table id="tablaPrincipal">    
        <tr>                       
        <th>Database Name</th>
        <th>Database Total Size(GB)</th>
        <th>Database Total DataFile SizeGB</th>
        <th>Database Total DataFile SizeGB(OneWeekAgo)</th>
	<th>Total Data File Size Change(GB)</th>
        <th>Percentage of Total Used(%)</th>
        <th>Percentage of Total Used(OneWeekAgo)</th>
        <th>Percentage of Total Used Change(%)</th>
        <th>Database Size Status</th> <!-- New column header -->
		<th>Date</th>
        </tr>' +
        (SELECT STUFF((
            SELECT
              '<tr>
                <td>' + DBName + '</td>  
                <td>' + TotalDatabaseSizeGB + '</td> 
                <td>' + TotalDataFileSizeGB + '</td>
		<td>' + TotalDataFileSizeGB_OneWeekAgo + '</td>
		<td>' + TotalDataFileSizeChange + '</td>
                <td>' + PercentageOfTotalGBUsed + '</td> 
                <td>' + PercentageOfTotalGBUsed_OneWeekAgo + '</td> 
                <td>' + PercentageOfTotalGBUsedChange + '</td> 
                <td style="color:' + CASE WHEN CAST(TotalDataFileSizeChange AS FLOAT) > 0 THEN 'red' ELSE 'green' END + ';">' + DatabaseSizeStatus + '</td> <!-- New column data with color formatting -->
				<td>' + CAST(FormattedDate AS nvarchar) + '</td> 
                </tr>'
            FROM #temp_SIT_DB_Weekly_Comparison
            WHERE ServerName = ServerData.ServerName
            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 0, '')) +
        '</table><br><br>'
    FROM ServerData;

    IF @body_HTML IS NOT NULL AND LEN(@body_HTML) > 0
    BEGIN
        SET @hasData = 1;
    END

    IF @hasData = 1  
    BEGIN  
        SET @body_HTML =     
        N'<p>       
        Hi ITOps 1C DBA Team,    
        <br>Please find the below MI SIT Servers Capacity Weekly Comparison Report.<br>
  <!--  <br>Note: Databases highlighted in red are Percentage of total GB Used of a Database >=25% when compared with data of one week before.<br> -->
        <br> <br>      
        </p>' +  
        N'<style>
            table, th, td {    
            border:1px solid black;    
            border-collapse: collapse;    
            font-family:Serif;   
            text-align: center;
            padding: 3px;
            font-size: 10.2pt;
            }    
            th {
            background:#87ceeb;
            }
            p {
            font-family:Serif;
            }
        </style>' + @body_HTML;  

        -- Debug print to check the final HTML content
        SELECT @body_HTML AS Final_HTML;
  
        EXEC msdb.dbo.sp_send_dbmail     
        @profile_name = 'ITOps1CDBA',    
        @body         = @body_HTML,    
        @body_format  = 'HTML',    
--          @recipients ='RaviShankar.C@cognizant.com;Janani.M2dcbb3@cognizant.com;Badam.Navya@cognizant.com; Bindu.Raavi@cognizant.com;pradheep.kumartk@cognizant.com; megha.singhal@cognizant.com;
--Sneha.S5@cognizant.com;Vimalraj.S3@cognizant.com;vidya.erragopula@cognizant.com;
--Burra.Sandhya@cognizant.com;PydaVenkata.SrihimaVishnuSeshasai@cognizant.com;EDMDBA@cognizant.com',
     --     @copy_recipients='kirankumar.gannavaram@cognizant.com;ashwathi.k@cognizant.com;
		   --balakrishna.mannepalli@cognizant.com;vijaianand.pv@cognizant.com;
		  @copy_recipients='balakrishna.mannepalli@cognizant.com;pydavenkata.srihimavishnuseshasai@cognizant.com',
        @subject = 'Test- MI SIT DB Capacity Weekly Comparison Report';    
    END;  

    DROP TABLE #temp_SIT_DB_Weekly_Comparison;  
END    
GO