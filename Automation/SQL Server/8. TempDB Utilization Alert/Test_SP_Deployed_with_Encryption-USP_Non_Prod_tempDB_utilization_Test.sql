USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[USP_Non_Prod_tempDB_utilization_Test]    Script Date: 2/25/2025 9:14:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



  
/****** Object:  StoredProcedure [dbo].[USP_Non_Prod_tempDB_utilization_Test]        
--SET ANSI_NULLS ON        
--GO        
--SET QUOTED_IDENTIFIER ON        
--GO        
-- =============================================        
-- Author:  <Hima Vishnu P>        
-- Create date: <07:11PM,24 Feb,2025>        
-- Description: <Description,,>       
--- EXEC USP_Non_Prod_tempDB_utilization_Test    
------ ============================================= ***/    
ALTER PROCEDURE [dbo].[USP_Non_Prod_tempDB_utilization_Test]  
WITH ENCRYPTION
AS        
BEGIN     
    CREATE TABLE #temp  
    (  
	[Servername] [nvarchar](200) not NULL,
	[Free_space(MB)] int NULL,
	[Used_Space_by_VersionStore(MB)] int NULL,
	[Used_Space_by_InternalObjects(MB)] int NOT NULL,
	[Used_Space_by_UserObjects(MB)] int NOT NULL,
	[Total_data_file_Size_of_tempdb(MB)] int NOT NULL,
	[Total_Log_Size(MB)] int not null,
	[Used_Log_Space(MB)] int not null,
	[Free_Log_Space(MB)] int not null,
	[Total_TempDB_Size(MB)] int not null,
	[Total_TempDB_Size(GB)] int not null,
);
      
  
    INSERT INTO #temp   
    SELECT * FROM [DBAdmin].[dbo].[MI_Prod_Servers_Tempdb_Utilization] with(nolock);  

	CREATE TABLE #temp2(
    [Servername] [nvarchar](200) not NULL,
    [session_id] INT,
	[login_name] NVARCHAR(128),
    [host_name] NVARCHAR(128),
	[program_name] NVARCHAR(128),
	[database_name] NVARCHAR(128),
	[status] NVARCHAR(30),
	tempdb_user_alloc_pages int,
	tempdb_internal_alloc_pages int,
	tempdb_alloc_mb int,
	tempdb_user_current_pages int,
	tempdb_internal_current_pages int,
	tempdb_current_mb int,
	total_pages_allocated int,
	query_start_time DATETIME2(3),
	query_runtime_seconds VARCHAR(50),
	query_text nvarchar(max)
);
    insert into #temp2
	select * from [DBAdmin].[dbo].[MI_Prod_Servers_Tempdb_Usage_Queries] with(nolock);
  
 --select * from #temp with(nolock)  
  
    DECLARE @body_HTML nvarchar(max) = N'';
	DECLARE @body_HTML1 nvarchar(max) = N'';
	DECLARE @body_HTML2 nvarchar(max) = N'';
    DECLARE @hasData BIT = 0;  
  
    IF EXISTS (SELECT 1 FROM #temp WHERE Servername = 'ctsazsimisstfd1.inso13dfbbbfa2150.database.windows.net' and [Total_TempDB_Size(GB)] > 80)  
    BEGIN  
        SET @hasData = 1;  
        SET @body_HTML = @body_HTML +     
        N'<H2 align = "Left"><font face="Lucida Bright" color="blue" size = "2.5">SSTFD1 TempDB utilization Status:</font></H2>' +    
        N'<table border="1">' +    
        N'<font face="fantasy" size = "2" font-family:Serif><tr>
		<th style="background:#87ceeb">Total TempDB Size(GB)</th>' +    
        N'<th style="background:#87ceeb">Total TempDB Size(MB)</th>
		<th style="background:#87ceeb">Free Space(MB)</th>
		<th style="background:#87ceeb">Used space by User Objects(MB)</th>
		<th style="background:#87ceeb">Used Space by Internal Objects(MB)</th>
		<th style="background:#87ceeb">Used Space by VersionStore(MB)</th>
		<th style="background:#87ceeb">Total Date File Size of TempDB(MB)</th>
		<th style="background:#87ceeb">Total Log Space Size(MB)</th>
		<th style="background:#87ceeb">Used Log Space Size(MB)</th>
		<th style="background:#87ceeb">Free Log Space Size(MB)</th>
		</tr>
		</font>
		<font face="bold" font-family:Serif color="Black" size = "2">'+    
          
        CAST((SELECT   
            td = [Total_TempDB_Size(GB)], '',    
            td = [Total_TempDB_Size(MB)], '',    
            td = [Free_space(MB)], '',    
            td = [Used_Space_by_UserObjects(MB)], '',    
            td = [Used_Space_by_InternalObjects(MB)], '',    
            td = [Used_Space_by_VersionStore(MB)], '',    
            td = [Total_data_file_Size_of_tempdb(MB)], '',    
            td = [Total_Log_Size(MB)], '',
			td = [Used_Log_Space(MB)], '',    
            td = [Free_Log_Space(MB)], '' 
        FROM   
            (SELECT DISTINCT   
                [Total_TempDB_Size(GB)],   
                [Total_TempDB_Size(MB)],   
                [Free_space(MB)],   
                [Used_Space_by_UserObjects(MB)],   
                [Used_Space_by_InternalObjects(MB)],   
                [Used_Space_by_VersionStore(MB)],   
                [Total_data_file_Size_of_tempdb(MB)],
				[Total_Log_Size(MB)],
				[Used_Log_Space(MB)],
                [Free_Log_Space(MB)]   
            FROM #temp   
            WHERE Servername = 'ctsazsimisstfd1.inso13dfbbbfa2150.database.windows.net' and 
			[Total_TempDB_Size(GB)] > 80) AS subquery  
        --ORDER BY   
        --    time DESC,   
        --    publisher_db DESC   
        FOR XML PATH('tr'), TYPE       
        ) AS nvarchar(max)) +       
        N'</font></table>'; 
		

		SET @hasData = 1;  
        SET @body_HTML1 = @body_HTML1 +     
        N'<H2 align = "Left"><font face="Lucida Bright" color="blue" size = "2.5">SSTFD1 TempDB Usage Queries:</font></H2>' +    
        N'<table border="1">' +    
        N'<font face="fantasy" size = "2" font-family:Serif><tr>
		<th style="background:#87ceeb">Session ID</th>' +    
        N'<th style="background:#87ceeb">Login Name</th>
		<th style="background:#87ceeb">Program Name</th>
		<th style="background:#87ceeb">Database Name</th>
		<th style="background:#87ceeb">Status</th>
		<th style="background:#87ceeb">tempDB Alloc(MB)</th>
		<th style="background:#87ceeb">TempDB Current(MB)</th>
		<th style="background:#87ceeb">Query Start Time</th>
		<th style="background:#87ceeb">Query RunTime</th>
		<th style="background:#87ceeb">Query Text</th>
		<th style="background:#87ceeb">Host Name</th>
		</tr>
		</font>
		<font face="bold" font-family:Serif color="Black" size = "2">'+    
          
        CAST((SELECT   
            td = session_id, '',    
            td = [login_name], '',    
            td = [program_name], '',    
            td = [database_name], '',    
            td = [status], '',    
            td = [tempdb_alloc_mb], '',    
            td = [tempdb_current_mb], '',    
            td = [query_start_time], '',
			td = [query_runtime_seconds], '',    
            td = [query_text], '',
			td = [host_name], ''
        FROM  #temp2   
            WHERE Servername = 'ctsazsimisstfd1.inso13dfbbbfa2150.database.windows.net'  
        ORDER BY [tempdb_current_mb] DESC, [query_start_time] DESC   
        FOR XML PATH('tr'), TYPE       
        ) AS nvarchar(max)) +       
        N'</font></table>'; 
    END  
  
    IF EXISTS (SELECT 1 FROM #temp WHERE Servername = 'ctsazsimisgntm1.inso13dfbbbfa2150.database.windows.net' and [Total_TempDB_Size(GB)] > 80)  
    BEGIN  
        SET @hasData = 1;  
        SET @body_HTML = @body_HTML +     
        N'<H2 align = "Left"><font face="Lucida Bright" color="blue" size = "2.5">SGNTM1 TempDB utilization Status:</font></H2>' +    
        N'<table border="1">' +    
        N'<font face="fantasy" size = "2" font-family:Serif><tr>
		<th style="background:#87ceeb">Total TempDB Size(GB)</th>' +    
        N'<th style="background:#87ceeb">Total TempDB Size(MB)</th>
		<th style="background:#87ceeb">Free Space(MB)</th>
		<th style="background:#87ceeb">Used space by User Objects(MB)</th>
		<th style="background:#87ceeb">Used Space by Internal Objects(MB)</th>
		<th style="background:#87ceeb">Used Space by VersionStore(MB)</th>
		<th style="background:#87ceeb">Total Date File Size of TempDB(MB)</th>
		<th style="background:#87ceeb">Total Log Space Size(MB)</th>
		<th style="background:#87ceeb">Used Log Space Size(MB)</th>
		<th style="background:#87ceeb">Free Log Space Size(MB)</th>
		</tr>
		</font>
		<font face="bold" font-family:Serif color="Black" size = "2">'+    
          
        CAST((SELECT   
            td = [Total_TempDB_Size(GB)], '',    
            td = [Total_TempDB_Size(MB)], '',    
            td = [Free_space(MB)], '',    
            td = [Used_Space_by_UserObjects(MB)], '',    
            td = [Used_Space_by_InternalObjects(MB)], '',    
            td = [Used_Space_by_VersionStore(MB)], '',    
            td = [Total_data_file_Size_of_tempdb(MB)], '',    
            td = [Total_Log_Size(MB)], '',
			td = [Used_Log_Space(MB)], '',    
            td = [Free_Log_Space(MB)], '' 
        FROM   
            (SELECT DISTINCT   
                [Total_TempDB_Size(GB)],   
                [Total_TempDB_Size(MB)],   
                [Free_space(MB)],   
                [Used_Space_by_UserObjects(MB)],   
                [Used_Space_by_InternalObjects(MB)],   
                [Used_Space_by_VersionStore(MB)],   
                [Total_data_file_Size_of_tempdb(MB)],
				[Total_Log_Size(MB)],
				[Used_Log_Space(MB)],
                [Free_Log_Space(MB)]   
            FROM #temp   
            WHERE Servername = 'ctsazsimisgntm1.inso13dfbbbfa2150.database.windows.net' and 
			[Total_TempDB_Size(GB)] > 80) AS subquery  
        --ORDER BY   
        --    time DESC,   
        --    publisher_db DESC   
        FOR XML PATH('tr'), TYPE       
        ) AS nvarchar(max)) +       
        N'</font></table>'; 
		

		SET @hasData = 1;  
        SET @body_HTML1 = @body_HTML1 +     
        N'<H2 align = "Left"><font face="Lucida Bright" color="blue" size = "2.5">SGNTM1 TempDB Usage Queries:</font></H2>' +    
        N'<table border="1">' +    
        N'<font face="fantasy" size = "2" font-family:Serif><tr>
		<th style="background:#87ceeb">Session ID</th>' +    
        N'<th style="background:#87ceeb">Login Name</th>
		<th style="background:#87ceeb">Program Name</th>
		<th style="background:#87ceeb">Database Name</th>
		<th style="background:#87ceeb">Status</th>
		<th style="background:#87ceeb">tempDB Alloc(MB)</th>
		<th style="background:#87ceeb">TempDB Current(MB)</th>
		<th style="background:#87ceeb">Query Start Time</th>
		<th style="background:#87ceeb">Query RunTime</th>
		<th style="background:#87ceeb">Query Text</th>
		<th style="background:#87ceeb">Host Name</th>
		</tr>
		</font>
		<font face="bold" font-family:Serif color="Black" size = "2">'+    
          
        CAST((SELECT   
            td = session_id, '',    
            td = [login_name], '',    
            td = [program_name], '',    
            td = [database_name], '',    
            td = [status], '',    
            td = [tempdb_alloc_mb], '',    
            td = [tempdb_current_mb], '',    
            td = [query_start_time], '',
			td = [query_runtime_seconds], '',    
            td = [query_text], '',
			td = [host_name], ''
        FROM  #temp2   
            WHERE Servername = 'ctsazsimisgntm1.inso13dfbbbfa2150.database.windows.net'  
        ORDER BY [tempdb_current_mb] DESC, [query_start_time] DESC   
        FOR XML PATH('tr'), TYPE       
        ) AS nvarchar(max)) +       
        N'</font></table>'; 
    END  
   
  
    IF @hasData = 1  
    BEGIN  
        SET @body_HTML2 =     
        N'<p>       
        Hi ITOps 1C DBA Team,    
        <br>We have observed the Production MI server TempDB utilization has reached critical levels, exceeding 80 GB. Immediate action is necessary to prevent potential system disruptions and ensure continued performance. Please investigate the current TempDB usage and take appropriate measures to mitigate this issue promptly.<br>    
        <br> <br>      
        </p>' +  
  N'<style>    
        tr {    
        border:1px solid black;    
        border-collapse: collapse;    
        font-family:Serif;    
        style="background:#87ceeb";}    
        td,tr {    
        padding: 3px;} 
		p {
		font-family:Serif;}
		td{
		vertical-align:top;text-align:left;}
        </style>' + @body_HTML + @body_HTML1; 
		
		select * from #temp;
		select * from #temp2;
		select @body_HTML2;
  
        EXEC msdb.dbo.sp_send_dbmail     
        @profile_name = 'CRS',    
        @body         = @body_HTML2,    
        @body_format  = 'HTML',    
        @recipients ='kirankumar.gannavaram@cognizant.com;ashwathi.k@cognizant.com',    
        @copy_recipients='pydavenkata.srihimavishnuseshasai@cognizant.com',    
        @subject = 'Test-Critical Alert: Production MI Server TempDB Utilization Exceeds 80 GB';    
    END  
  
    DROP TABLE #temp;
	DROP TABLE #temp2;
END    
GO


