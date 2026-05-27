

/****** Object:  StoredProcedure [dbo].[USP_MI_PROD_DB_Capacity_Report]    Script Date: 2/11/2025 10:33:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
/****** Object:  StoredProcedure [dbo].[USP_MI_PROD_DB_Capacity_Report]        
--SET ANSI_NULLS ON        
--GO        
--SET QUOTED_IDENTIFIER ON        
--GO        
-- =============================================        
-- Author:  <Hima Vishnu P>        
-- Create date: <6:30PM,27 May,2025>        
-- Description: <Description,,>       
--- EXEC USP_MI_PROD_DB_Capacity_Report   
------ ============================================= ***/    
Alter PROCEDURE [dbo].[USP_MI_Prod_DB_Capacity_Report] with encryption
AS
BEGIN
    CREATE TABLE #temp(
        ServerName NVARCHAR(128),
        DBName NVARCHAR(128),
        [Name] NVARCHAR(128),
        FileId INT,
        TotalSizeGB DECIMAL(18,3),
        AvailableSpaceGB DECIMAL(18,3),
        UsedSpaceGB DECIMAL(18,3),
        PercentageUsed DECIMAL(5,2),
        TotalDatabaseSizeGB NVARCHAR(50),
        PercentageOfTotalGBUsed NVARCHAR(10),
		TotalDataFileSizeGB NVARCHAR(50),
        TotalLogFileSizeGB NVARCHAR(50)
    );  
    
    INSERT INTO #temp 
    SELECT DISTINCT
        ServerName,
        DBName,
        [Name],
        FileId,
        TotalSizeGB,
        AvailableSpaceGB,
        UsedSpaceGB,
        PercentageUsed,
        TotalDatabaseSizeGB,
        PercentageOfTotalGBUsed,
		TotalDataFileSizeGB,
		TotalLogFileSizeGB
    FROM (
        SELECT 
            ServerName,
            DBName,
            [Name],
            FileId,
            TotalSizeGB,
            AvailableSpaceGB,
            UsedSpaceGB,
            PercentageUsed,
            TotalDatabaseSizeGB,
            PercentageOfTotalGBUsed,
			TotalDataFileSizeGB,
			TotalLogFileSizeGB,
            ROW_NUMBER() OVER (PARTITION BY ServerName, DBName, [Name], FileId ORDER BY (SELECT NULL)) AS RowNum
        FROM MI_Prod_DB_Capacity_Report with(nolock) where DBName not in ('master','model','msdb','tempdb')
    ) AS sub
    WHERE RowNum = 1;
   
    DECLARE @body_HTML NVARCHAR(MAX) = N'';  
    DECLARE @hasData BIT = 0;  
  
    -- Function to generate HTML for a specific server
    DECLARE @server NVARCHAR(128);
    DECLARE @serverName NVARCHAR(128);
    DECLARE server_cursor CURSOR FOR
    SELECT DISTINCT ServerName FROM #temp;

    OPEN server_cursor;
    FETCH NEXT FROM server_cursor INTO @server;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @serverName = CASE 
            WHEN @server = 'ctsazsimibcapps1.inso1a101c37461fa.database.windows.net' THEN 'BCApps1'
            WHEN @server = 'ctsazsimibcapps2.inso1a101c37461fa.database.windows.net' THEN 'BCApps2'
            WHEN @server = 'ctsazmibcapps3.293366d454bb.database.windows.net' THEN 'BCApps3'
            WHEN @server = 'ctsazsimipddeapps1.293366d454bb.database.windows.net' THEN 'DEApps1'
            WHEN @server = 'ctsazsimipfd.inso1a101c37461fa.database.windows.net' THEN 'PFD'
            when @server = 'ctsazsimipplt.inso1a101c37461fa.database.windows.net' THEN 'PPLT'
            WHEN @server = 'ctsazsimimcapps1.293366d454bb.database.windows.net' THEN 'MCApps1'
            when @server = 'ctsazsimipst.inso1a101c37461fa.database.windows.net' THEN 'PST'
            WHEN @server = 'ctsazsimipgn.inso1a101c37461fa.database.windows.net' THEN 'PGN'
            when @server = 'ctsazsimiptm.inso1a101c37461fa.database.windows.net' THEN 'PTM'
            WHEN @server = 'ctsazsimiptm1.293366d454bb.database.windows.net' THEN 'PTM1'
            when @server = 'ctsazpdmincapps1.b96303a221dc.database.windows.net' THEN 'NCApps1'
            WHEN @server = 'ctsazpdmincapps2.b96303a221dc.database.windows.net' THEN 'NCApps2'
            when @server = 'ctsazmipdpcrsr1.inso1a101c37461fa.database.windows.net' THEN 'R1 Cloud'
			when @server = 'ctsazsimiprdml01.293366d454bb.database.windows.net' THEN 'PRML01'
        END;

        IF EXISTS (SELECT 1 FROM #temp WHERE ServerName = @server)
        BEGIN
            SET @hasData = 1;  
            SET @body_HTML = @body_HTML +     
            N'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">' + @serverName + ' DB Capacity Status:</font></H2>
            <table id="tablaPrincipal">    
            <tr>                       
            <th>Database Name</th>
            <th>File Name</th>
            <th>Total file Size(GB)</th>
            <th>Available Space(GB)</th>
            <th>Used Space(GB)</th>
            <th>Percentage of Used(%)</th>
            <th>Database Total Size(GB)</th>
            <th>Percentage of Total Used(%)</th>
            </tr>';                

            SELECT @body_HTML = @body_HTML + 
            '<tr style="color:' + CASE WHEN PercentageOfTotalGBUsed >= '95%' THEN 'red' ELSE 'black' END + ';">
            <td>' + DBName + '</td>
            <td>' + [Name] + '</td> 
            <td>' + CAST(TotalSizeGB AS NVARCHAR) + '</td> 
            <td>' + CAST(AvailableSpaceGB AS NVARCHAR) + '</td>
            <td>' + CAST(UsedSpaceGB AS NVARCHAR) + '</td>
            <td>' + CAST(PercentageUsed AS NVARCHAR) + '</td> 
            <td>' + TotalDatabaseSizeGB + '</td> 
            <td>' + PercentageOfTotalGBUsed + '</td> 
            </tr>'  
            FROM #temp WITH (NOLOCK) 
            WHERE ServerName = @server ORDER BY ServerName, DBName, FileId ASC;

            SET @body_HTML = @body_HTML + '</table><br><br>';
        END;

        FETCH NEXT FROM server_cursor INTO @server;
    END;

    CLOSE server_cursor;
    DEALLOCATE server_cursor;

    IF @hasData = 1  
    BEGIN  
        SET @body_HTML =     
        N'<p>       
        Hi ITOps 1C DBA Team,    
        <br>Please find the below MI Prod Servers BI Weekly DB Capacity Report.<br>
		<br>Note: Databases highlighted in red are Percentage of total GB Used of a Database >=95%.<br>
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
  
        EXEC msdb.dbo.sp_send_dbmail     
        @profile_name = 'ITOps1CDBA',    
        @body         = @body_HTML,    
        @body_format  = 'HTML',    
  --      @recipients ='RaviShankar.C@cognizant.com;Janani.M2dcbb3@cognizant.com;Badam.Navya@cognizant.com; Bindu.Raavi@cognizant.com;pradheep.kumartk@cognizant.com; megha.singhal@cognizant.com;
		--Sneha.S5@cognizant.com;Vimalraj.S3@cognizant.com;vidya.erragopula@cognizant.com;
		--Burra.Sandhya@cognizant.com;PydaVenkata.SrihimaVishnuSeshasai@cognizant.com;EDMDBA@cognizant.com',
        @copy_recipients='PydaVenkata.SrihimaVishnuSeshasai@cognizant.com',  
        @subject = 'Daily MI Prod DB Capacity Report';    
		 
    END;  
  
    DROP TABLE #temp;  
END    
GO


