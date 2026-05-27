ALTER PROCEDURE [dbo].[USP_Non_Prod_tempDB_utilization_Test]
AS
BEGIN
    DECLARE @ServerName NVARCHAR(200);
    DECLARE @body_HTML NVARCHAR(MAX);
    DECLARE @body_HTML1 NVARCHAR(MAX);
	DECLARE @body_HTML2 NVARCHAR(MAX);
    DECLARE @hasData BIT;
    DECLARE @subject NVARCHAR(255);

    -- List of server names
    DECLARE @ServerList TABLE (ServerName NVARCHAR(200));
    INSERT INTO @ServerList (ServerName)
    VALUES
        ('ctsazsimisstfd1.inso13dfbbbfa2150.database.windows.net'),
        ('ctsazsimisgntm1.inso13dfbbbfa2150.database.windows.net'),
        ('ctsazsimisplt01.inso13dfbbbfa2150.database.windows.net'),
        ('ctsazsimisnc02.inso13dfbbbfa2150.database.windows.net'),
        ('ctsazsimisitde1.inso13dfbbbfa2150.database.windows.net');

    DECLARE ServerCursor CURSOR FOR
    SELECT ServerName FROM @ServerList;

    OPEN ServerCursor;
    FETCH NEXT FROM ServerCursor INTO @ServerName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Reset variables
        SET @body_HTML = N'';
        SET @body_HTML1 = N'';
		SET @body_HTML2 = N'';
        SET @hasData = 0;

        -- Create temporary tables
        CREATE TABLE #temp3
        (
            [Servername] NVARCHAR(200) NOT NULL,
        [Free_space(MB)] INT NULL,
        [Used_Space_by_VersionStore(MB)] INT NULL,
        [Used_Space_by_InternalObjects(MB)] INT NOT NULL,
        [Used_Space_by_UserObjects(MB)] INT NOT NULL,
        [Total_data_file_Size_of_tempdb(MB)] INT NOT NULL,
        [Total_Log_Size(MB)] INT NOT NULL,
        [Used_Log_Space(MB)] INT NOT NULL,
        [Free_Log_Space(MB)] INT NOT NULL,
        [Total_TempDB_Size(MB)] INT NOT NULL,
        [Total_TempDB_Size(GB)] INT NOT NULL
        );

        CREATE TABLE #temp32
        (
        [Servername] NVARCHAR(200) NOT NULL,
        [session_id] INT,
        [login_name] NVARCHAR(128),
        [host_name] NVARCHAR(128),
        [program_name] NVARCHAR(128),
        [database_name] NVARCHAR(128),
        [status] NVARCHAR(30),
        tempdb_user_alloc_pages INT,
        tempdb_internal_alloc_pages INT,
        tempdb_alloc_mb INT,
        tempdb_user_current_pages INT,
        tempdb_internal_current_pages INT,
        tempdb_current_mb INT,
        total_pages_allocated INT,
        query_start_time DATETIME2(3),
        query_runtime_seconds VARCHAR(50),
        query_text NVARCHAR(MAX)
        );

        -- Insert data into temporary tables
        INSERT INTO #temp3
        SELECT * FROM [DBAdmin].[dbo].[MI_Prod_Servers_Tempdb_Utilization] WITH (NOLOCK) WHERE Servername = @ServerName;

        INSERT INTO #temp32
        SELECT * FROM [DBAdmin].[dbo].[MI_Prod_Servers_Tempdb_Usage_Queries] WITH (NOLOCK) WHERE Servername = @ServerName;

        -- Check for high TempDB utilization
        IF EXISTS (SELECT 1 FROM #temp3 WHERE Servername = @ServerName AND [Total_TempDB_Size(GB)] > 80)
        BEGIN
            SET @hasData = 1;
            SET @body_HTML = @body_HTML +
            N'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">' + @ServerName + ' TempDB utilization status:</font></H2>' +
            N'<table border="1">' +
            N'<tr><th style="background:#87ceeb">Total TempDB Size(GB)</th>' +
            N'<th style="background:#87ceeb">Total TempDB Size(MB)</th>' +
            N'<th style="background:#87ceeb">Free Space(MB)</th>' +
            N'<th style="background:#87ceeb">Used space by User Objects(MB)</th>' +
            N'<th style="background:#87ceeb">Used Space by Internal Objects(MB)</th>' +
            N'<th style="background:#87ceeb">Used Space by VersionStore(MB)</th>' +
            N'<th style="background:#87ceeb">Total Data File Size of TempDB(MB)</th>' +
            N'<th style="background:#87ceeb">Total Log Space Size(MB)</th>' +
            N'<th style="background:#87ceeb">Used Log Space Size(MB)</th>' +
            N'<th style="background:#87ceeb">Free Log Space Size(MB)</th></tr>';

            SET @body_HTML = @body_HTML +
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
                FROM #temp3
                WHERE Servername = @ServerName AND
                [Total_TempDB_Size(GB)] > 80
            FOR XML PATH('tr'), TYPE
            ) AS NVARCHAR(MAX)) +
            N'</table>';

            SET @body_HTML1 = @body_HTML1 +
            N'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">' + @ServerName + ' TempDB Usage Queries:</font></H2>' +
            N'<table border="1">' +
            N'<tr><th style="background:#87ceeb">Session ID</th>' +
            N'<th style="background:#87ceeb">Login Name</th>' +
            N'<th style="background:#87ceeb">Program Name</th>' +
            N'<th style="background:#87ceeb">Database Name</th>' +
            N'<th style="background:#87ceeb">Status</th>' +
            N'<th style="background:#87ceeb">tempDB Alloc(MB)</th>' +
            N'<th style="background:#87ceeb">TempDB Current(MB)</th>' +
            N'<th style="background:#87ceeb">Query Start Time</th>' +
            N'<th style="background:#87ceeb">Query RunTime</th>' +
            N'<th style="background:#87ceeb">Query Text</th>' +
            N'<th style="background:#87ceeb">Host Name</th></tr>';

            SET @body_HTML1 = @body_HTML1 +
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
            FROM #temp32
            WHERE Servername = @ServerName
            ORDER BY [query_start_time] DESC, [tempdb_current_mb] DESC
            FOR XML PATH('tr'), TYPE
            ) AS NVARCHAR(MAX)) +
            N'</table>';
        END

        -- Send email if data exists
        IF @hasData = 1
        BEGIN
            SET @body_HTML2 =
            N'<p>
            Hi ITOps 1C DBA Team,
            <br>We have observed the Production MI server TempDB utilization has reached critical levels, exceeding 100 GB. Immediate action is necessary to prevent potential system disruptions and ensure continued performance. Please investigate the current TempDB usage and take appropriate measures to mitigate this issue promptly.<br>
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
            </style>' + @body_HTML + @body_HTML1;

            SET @subject = 'Critical Alert: ' + @ServerName + ' TempDB Utilization Exceeds 100 GB';

			select * from #temp3;
		    select * from #temp32;
		    select @body_HTML2;

            EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'CRS',
            @body = @body_HTML2,
            @body_format = 'HTML',
            --@recipients ='CRSDBASUPPORT@cognizant.com',    
        @copy_recipients='pydavenkata.srihimavishnuseshasai@cognizant.com',    
        @subject = 'Test-Critical Alert: Production MI Server TempDB Utilization Exceeds 100 GB';    
    END  
  END
  DROP TABLE #temp3;
  DROP TABLE #temp32;
END