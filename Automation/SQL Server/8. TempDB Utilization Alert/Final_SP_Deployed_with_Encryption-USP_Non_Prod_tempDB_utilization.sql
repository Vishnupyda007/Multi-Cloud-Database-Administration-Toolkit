USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[USP_Non_Prod_tempDB_utilization]    Script Date: 2/25/2025 9:14:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  StoredProcedure [dbo].[USP_Non_Prod_tempDB_utilization]        
--SET ANSI_NULLS ON        
--GO        
--SET QUOTED_IDENTIFIER ON        
--GO        
-- =============================================        
-- Author:  <Hima Vishnu P>        
-- Create date: <07:11PM,24 Feb,2025>        
-- Description: <Description,,>       
--- EXEC USP_Non_Prod_tempDB_utilization   
---Retained Total TempDB in GB column in TempDB Utilization Table as other columns not required and removed SQL_test column as it takes more space. 
------ ============================================= ***/ 
ALTER PROCEDURE [dbo].[USP_Non_Prod_tempDB_utilization]
WITH ENCRYPTION
AS
BEGIN
    CREATE TABLE #temp
    (
        [Servername] nvarchar(200) NOT NULL,
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

    INSERT INTO #temp
    SELECT * FROM [DBAdmin].[dbo].[MI_Prod_Servers_Tempdb_Utilization] WITH (NOLOCK);

    CREATE TABLE #temp2
    (
        [Servername] nvarchar(200) NOT NULL,
        [session_id] INT,
        [login_name] NVARCHAR(128),
        [host_name] NVARCHAR(128),
        [program_name] NVARCHAR(128),
        [database_name] NVARCHAR(128),
        [status] NVARCHAR(30),
        [tempdb_user_alloc_pages] INT,
        [tempdb_internal_alloc_pages] INT,
        [tempdb_alloc_mb] INT,
        [tempdb_user_current_pages] INT,
        [tempdb_internal_current_pages] INT,
        [tempdb_current_mb] INT,
        [total_pages_allocated] INT,
        [query_start_time] VARCHAR(200),
        [query_runtime_seconds] VARCHAR(50),
        [query_text] NVARCHAR(MAX)
    );

    INSERT INTO #temp2
    SELECT * FROM [DBAdmin].[dbo].[MI_Prod_Servers_Tempdb_Usage_Queries] WITH (NOLOCK);

    DECLARE @body_HTML NVARCHAR(MAX) = N'';
    DECLARE @body_HTML1 NVARCHAR(MAX) = N'';
    DECLARE @body_HTML2 NVARCHAR(MAX) = N'';
    DECLARE @hasData BIT = 0;

    -- List of servers to check
    DECLARE @servers TABLE (ID INT IDENTITY(1,1), Servername NVARCHAR(200));
    INSERT INTO @servers (Servername)
    VALUES
    ('ctsazsimisstfd1.inso13dfbbbfa2150.database.windows.net'),
    ('ctsazsimisgntm1.inso13dfbbbfa2150.database.windows.net'),
    ('ctsazsimisplt01.inso13dfbbbfa2150.database.windows.net'),
    ('ctsazsimisnc02.inso13dfbbbfa2150.database.windows.net'),
    ('ctsazsimisplt01.inso13dfbbbfa2150.database.windows.net');

    -- Loop through each server and check the condition
    DECLARE @servername NVARCHAR(200);
    DECLARE @i INT = 1;
    DECLARE @serverCount INT;

    SELECT @serverCount = COUNT(*) FROM @servers;

    WHILE @i <= @serverCount
    BEGIN
        SELECT @servername = Servername FROM @servers WHERE ID = @i;

        IF EXISTS (SELECT 1 FROM #temp WHERE Servername = @servername AND [Total_TempDB_Size(GB)] > 80)
        BEGIN
            SET @hasData = 1;
            SET @body_HTML = @body_HTML +
            N'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">' + @servername + ' TempDB utilization Status:</font></H2>' +
            N'<table border="1">' +
            N'<font face="fantasy" size="2" font-family:Serif><tr>' +
            N'<th style="background:#87ceeb">Total TempDB Size(GB)</th>' +
            N'</tr></font>' +
            N'<font face="bold" font-family:Serif color="Black" size="2">' +
            CAST((SELECT
                td = [Total_TempDB_Size(GB)], ''
                FROM #temp with(nolock)
                WHERE Servername = @servername AND [Total_TempDB_Size(GB)] > 80
                FOR XML PATH('tr'), TYPE
            ) AS NVARCHAR(MAX)) +
            N'</font></table>';

            SET @body_HTML1 = @body_HTML1 +
            N'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">' + @servername + ' TempDB Usage Queries:</font></H2>' +
            N'<table border="1">' +
            N'<font face="fantasy" size="2" font-family:Serif><tr>' +
            N'<th style="background:#87ceeb">Session ID</th>' +
            N'<th style="background:#87ceeb">Login Name</th>' +
            N'<th style="background:#87ceeb">Program Name</th>' +
            N'<th style="background:#87ceeb">Database Name</th>' +
            N'<th style="background:#87ceeb">Status</th>' +
            N'<th style="background:#87ceeb">TempDB Alloc(MB)</th>' +
            N'<th style="background:#87ceeb">TempDB Current(MB)</th>' +
            N'<th style="background:#87ceeb">Query Start Time</th>' +
            N'<th style="background:#87ceeb">Query RunTime</th>' +
            N'<th style="background:#87ceeb">Host Name</th>' +
            N'</tr></font>' +
            N'<font face="bold" font-family:Serif color="Black" size="2">' +
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
                td = [host_name], ''
                FROM #temp2 with(nolock)
                WHERE Servername = @servername
                ORDER BY [tempdb_current_mb] DESC, [query_start_time] DESC
                FOR XML PATH('tr'), TYPE
            ) AS NVARCHAR(MAX)) +
            N'</font></table>';
        END

        SET @i = @i + 1;
    END

    IF @hasData = 1
    BEGIN
        SET @body_HTML2 =
        N'<p>
        Hi ITOps 1C DBA Team,
        <br>We have observed the Production MI server TempDB utilization has reached critical levels, exceeding 80 GB. Immediate action is necessary to prevent potential system disruptions and ensure continued performance.<br>
        <br> <br>
        </p>' +
        N'<style>
        tr {
            border:1px solid black;
            border-collapse: collapse;
            font-family:Serif;
            style="background:#87ceeb";
        }
        td,tr {
            padding: 3px;
        }
        p {
            font-family:Serif;
        }
        td {
            vertical-align:top;
            text-align:left;
        }
        </style>' + @body_HTML + @body_HTML1;

        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'CRS', 
            @body = @body_HTML2, 
            @body_format = 'HTML', 
            @recipients ='kirankumar.gannavaram@cognizant.com;ashwathi.k@cognizant.com;balakrishna.mannepalli@cognizant.com', 
            @copy_recipients='pydavenkata.srihimavishnuseshasai@cognizant.com', 
            @subject = 'Test-Critical Alert : Production MI Server TempDB Utilization Exceeds 80 GB';
    END

    DROP TABLE #temp;
    DROP TABLE #temp2;
END
GO