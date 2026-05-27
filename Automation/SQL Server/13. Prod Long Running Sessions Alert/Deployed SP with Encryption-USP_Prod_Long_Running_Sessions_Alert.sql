

/****** Object:  StoredProcedure [dbo].[USP_Prod_Long_Running_Sessions_Alert]    Script Date: 2/25/2025 9:14:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  StoredProcedure [dbo].[USP_Prod_Long_Running_Sessions_Alert]        
--SET ANSI_NULLS ON        
--GO        
--SET QUOTED_IDENTIFIER ON        
--GO        
-- =============================================        
-- Author:  <Hima Vishnu P>        
-- Create date: <06:11PM,05 July,2025>        
-- Description: <Description,,>       
--- EXEC [USP_Prod_Long_Running_Sessions_Alert]   
--
------ ============================================= ***/ 
ALTER PROCEDURE [dbo].[USP_Prod_Long_Running_Sessions_Alert]
WITH ENCRYPTION
AS
BEGIN
    CREATE TABLE #temp
    (
	[Servername] [nvarchar](200) NOT NULL,
	[session_id] [int] NULL,
	blocking_session_id [int] NULL,
	[login_name] [nvarchar](128) NULL,
	[host_name] [nvarchar](128) NULL,
	[program_name] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[status] [nvarchar](200) NULL,
	command [nvarchar](128) NULL,
	reads [bigint] null,
	writes [bigint] null,
	logical_reads [bigint] null,
	[query_start_time] [datetime2](3) NULL,
	[query_runtime_ddhhmmss] [varchar](50) NULL,
	cpu_time_seconds [int] NULL,
	query_text [nvarchar](max) null
    );

    INSERT INTO #temp
    SELECT * FROM [dbo].[MI_Prod_Long_Running_Sessions_tbl] WITH (NOLOCK) 
	where Servername !='ctsinazprdedssqlmi.inso1a101c37461fa.database.windows.net' and 
	[query_runtime_ddhhmmss] > '0:02:00:00';

    DECLARE @body_HTML1 NVARCHAR(MAX) = N'';
    DECLARE @body_HTML2 NVARCHAR(MAX) = N'';
    DECLARE @hasData BIT = 0;

    -- List of servers to check, use distinct here to get only unique servers and no repetion of data
    DECLARE @servers TABLE (ID INT IDENTITY(1,1), Servername NVARCHAR(200));
    INSERT INTO @servers (Servername)
    SELECT distinct ServerName FROM [dbo].[MI_Prod_Long_Running_Sessions_tbl] with(nolock)

    -- Loop through each server and check the condition
    DECLARE @servername NVARCHAR(200);
    DECLARE @i INT = 1;
    DECLARE @serverCount INT;

    SELECT @serverCount = COUNT(*) FROM @servers;

    WHILE @i <= @serverCount
    BEGIN
        SELECT @servername = Servername FROM @servers WHERE ID = @i;

        IF EXISTS (SELECT 1 FROM #temp WHERE Servername = @servername)
        BEGIN
            SET @hasData = 1;

            SET @body_HTML1 = @body_HTML1 +
            N'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">' + @servername + ' Long Running Session(s):</font></H2>' +
            N'<table border="1">' +
            N'<font face="fantasy" size="2" font-family:Serif><tr>' +
            N'<th style="background:#87ceeb">Session ID</th>' +
            N'<th style="background:#87ceeb">Login Name</th>' +
            N'<th style="background:#87ceeb">Program Name</th>' +
            N'<th style="background:#87ceeb">Database Name</th>' +
            N'<th style="background:#87ceeb">Status</th>' +
            N'<th style="background:#87ceeb">Command Type</th>' +
            N'<th style="background:#87ceeb">Blocking Session ID</th>' + 
            N'<th style="background:#87ceeb">Query Start Time</th>' +
            N'<th style="background:#87ceeb">Query RunTime(DD HH:MM:SS)</th>' +
            N'<th style="background:#87ceeb">Host Name</th>' +
			N'<th style="background:#87ceeb">Query Text</th>' +
            N'</tr></font>' +
            N'<font face="bold" font-family:Serif color="Black" size="2">' +
            ISNULL(CAST((SELECT
                td = session_id, '',
                td = [login_name], '',
                td = [program_name], '',
                td = [database_name], '',
                td = [status], '',
                td = command, '',               
                td = CASE 
                WHEN blocking_session_id IS NOT NULL AND blocking_session_id <> 0 
                THEN '<td style="color:red">' + CAST(blocking_session_id AS NVARCHAR) + '</td>' 
                ELSE '<td>' + CAST(blocking_session_id AS NVARCHAR) + '</td>' 
                END, '',
                td = [query_start_time], '',
                td = [query_runtime_ddhhmmss], '',
                td = [host_name], '',
				td=[query_text],''
                FROM #temp with(nolock)
                WHERE Servername = @servername
                ORDER BY [query_runtime_ddhhmmss] DESC
                FOR XML PATH('tr'), TYPE
            ) AS NVARCHAR(MAX)), N'') +
            N'</font></table>';
        END

        -- Debugging: Print intermediate values
        PRINT @body_HTML1;

        SET @i = @i + 1;
    END

    IF @hasData = 1
    BEGIN
        SET @body_HTML2 =
        N'<p>
        Hi ITOps 1C DBA Team,
        <br>We have observed Long Running Session(s) in Production MI server(s).Immediate action is necessary to prevent potential system disruptions and ensure continuous performance.<br>
		<br>Note: We will get alert when Query Runtime of a session is greater than two hours.<br>
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
        </style>' + ISNULL(@body_HTML1, N'');

        -- Debugging: Print final values
select @body_HTML1 as Body_HTML, @body_HTML2 as Body_HTML

        PRINT @body_HTML2;

        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ITOps1CDBA', 
            @body = @body_HTML2, 
            @body_format = 'HTML', 
          --@recipients ='RaviShankar.C@cognizant.com;Janani.M2dcbb3@cognizant.com;
			--Badam.Navya@cognizant.com; Bindu.Raavi@cognizant.com;pradheep.kumartk@cognizant.com;
			--megha.singhal@cognizant.com;Sneha.S5@cognizant.com;Vimalraj.S3@cognizant.com;
		 --   vidya.erragopula@cognizant.com;Burra.Sandhya@cognizant.com;
		 --   PydaVenkata.SrihimaVishnuSeshasai@cognizant.com;EDMDBA@cognizant.com',    
         --@copy_recipients='rambabu.s@cognizant.com;vijaianand.pv@cognizant.com;
		 --  kirankumar.gannavaram@cognizant.com;ashwathi.k@cognizant.com;
		 --  balakrishna.mannepalli@cognizant.com;PydaVenkata.SrihimaVishnuSeshasai@cognizant.com', 
		 @recipients='CRSDBASUPPORT@cognizant.com;EDMDBA@cognizant.com',
            @subject = 'Critical Alert : Detected Long Running Session(s) in 1C Prod Server(s)';
    END

    DROP TABLE #temp;
    
END
GO