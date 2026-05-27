USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[USP_MI_SIT_DB_Capacity_Report]    Script Date: 2/8/2025 6:35:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



  
/****** Object:  StoredProcedure [dbo].[USP_MI_SIT_DB_Capacity_Report]        
--SET ANSI_NULLS ON        
--GO        
--SET QUOTED_IDENTIFIER ON        
--GO        
-- =============================================        
-- Author:  <Hima Vishnu P>        
-- Create date: <3:30PM,08 Feb,2025>        
-- Description: <Description,,>       
--- EXEC USP_MI_SIT_DB_Capacity_Report   
------ ============================================= ***/    
ALTER PROCEDURE [dbo].[USP_MI_SIT_DB_Capacity_Report]
AS
BEGIN
    CREATE TABLE #temp(
        ServerName NVARCHAR(128),
        DBName NVARCHAR(128),
        [Name] NVARCHAR(128),
        TotalSizeGB DECIMAL(18,3),
        AvailableSpaceGB DECIMAL(18,3),
        UsedSpaceGB DECIMAL(18,3),
        PercentageUsed DECIMAL(5,2),
        TotalDatabaseSizeGB NVARCHAR(50),
        PercentageOfTotalGBUsed NVARCHAR(10)
    );  
    
    INSERT INTO #temp 
    SELECT 
        ServerName,
        DBName,
        [Name],
        TotalSizeGB,
        AvailableSpaceGB,
        UsedSpaceGB,
        PercentageUsed,
        TotalDatabaseSizeGB,
        PercentageOfTotalGBUsed  
    FROM MI_SIT_DB_Capacity_Report;
   
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
            WHEN @server = 'ctsazsimisitde1.inso13dfbbbfa2150.database.windows.net' THEN 'SITDE1'
            WHEN @server = 'ctsazsimisstfd1.inso13dfbbbfa2150.database.windows.net' THEN 'SSTFD1'
            WHEN @server = 'ctsazsimisgntm1.inso13dfbbbfa2150.database.windows.net' THEN 'SGNTM1'
            WHEN @server = 'ctsazsimisplt01.inso13dfbbbfa2150.database.windows.net' THEN 'SPLT01'
            WHEN @server = 'ctsazsimisnc02.inso13dfbbbfa2150.database.windows.net' THEN 'SNC02'
            ELSE @server
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
            <th>Percentage of Used</th>
            <th>Database Total Size(GB)</th>
            <th>Percentage of Total Used(GB)</th>
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
            WHERE ServerName = @server;

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
        <br>Please find the below MI SIT Servers BI Weekly Capacity Report.<br>    
        <br> <br>      
        </p>' +  
        N'<style>
            table, th, td {    
            border:1px solid black;    
            border-collapse: collapse;    
            font-family:Serif;   
            text-align: center;
            padding: 3px;
            font-size: 10.5pt;
            }    
            th {
            background:#87ceeb;
            }
        </style>' + @body_HTML;  
  
        EXEC msdb.dbo.sp_send_dbmail     
        @profile_name = 'CRS',    
        @body         = @body_HTML,    
        @body_format  = 'HTML',    
        --@recipients ='CRSDBASUPPORT@cognizant.com',    
        @copy_recipients='pydavenkata.srihimavishnuseshasai@cognizant.com',    
        @subject = 'Test-Bi-Weekly MI SIT DB Capacity Report';    
    END;  
  
    DROP TABLE #temp;  
END    
GO

