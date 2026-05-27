USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[USP_MI_SIT_DB_Capacity_Report]    Script Date: 2/8/2025 4:23:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[USP_MI_SIT_DB_Capacity_Report]
AS
BEGIN
    --SET NOCOUNT ON added to prevent extra result sets from
    --interfering with SELECT statements.

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
   
    SELECT * FROM #temp WITH (NOLOCK);
     
    DECLARE @date NVARCHAR(MAX) = CONVERT(NVARCHAR, GETDATE(), 101);
    DECLARE @html VARCHAR(MAX) = '   
    <p>   
    Hi Team,   
    <br>Please find the below MI SIT Servers BI Weekly Capacity Report.<br>   
    <br> <br>  
    </p>  
    <style>
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
    </style>'
	BEGIN
	SET @html = @html +
	'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">SITDE1 DB Capacity Status:</font></H2>
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

    SELECT @html = @html + 
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
    WHERE ServerName = 'ctsazsimisitde1.inso13dfbbbfa2150.database.windows.net';
    END


	BEGIN
	SET @html = @html +
	'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">SGNTM1 DB Capacity Status:</font></H2>
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

    SELECT @html = @html + 
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
    WHERE ServerName = 'ctsazsimisgntm1.inso13dfbbbfa2150.database.windows.net';
    END


	BEGIN
	SET @html = @html +
	'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">SSTFD1 DB Capacity Status:</font></H2>
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

    SELECT @html = @html + 
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
    WHERE ServerName = 'ctsazsimisstfd.inso13dfbbbfa2150.database.windows.net';
    END


	BEGIN
	SET @html = @html +
	'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">SPLT01 DB Capacity Status:</font></H2>
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

    SELECT @html = @html + 
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
    WHERE ServerName = 'ctsazsimisplt01.inso13dfbbbfa2150.database.windows.net';
    END


	BEGIN
	SET @html = @html +
	'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">SNC02 DB Capacity Status:</font></H2>
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

    SELECT @html = @html + 
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
    WHERE ServerName = 'ctsazsimisnc02.inso13dfbbbfa2150.database.windows.net';
    END



DROP TABLE #temp;
    
SELECT @html;
    
    EXEC msdb.dbo.sp_send_dbmail    
        @profile_name = 'CRS',    
        @recipients = 'pydavenkata.srihimavishnuseshasai@cognizant.com',
        @body = @html,    
        @body_format = 'HTML',    
        @subject = 'Test-BI-Weekly MI SIT DB Capacity Report';
END
GO


