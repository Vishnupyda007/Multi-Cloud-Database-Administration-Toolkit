USE [EDWMonitoring]
GO

/****** Object:  StoredProcedure [dbo].[USP_EDW_UAT_Long_Running_Query_Alert_Mail]    Script Date: 7/18/2025 11:58:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/****** Object:  StoredProcedure [dbo].[USP_EDW_UAT_Long_Running_Query_Alert_Mail]       
--SET ANSI_NULLS ON        
--GO        
--SET QUOTED_IDENTIFIER ON        
--GO        
-- =============================================        
-- Author:  <Hima Vishnu P/Bala Krishna Mannepalli>        
-- Create date: <06:11PM,16th July,2025>        
-- Description: <Description,,>       
--- EXEC [USP_EDW_UAT_Long_Running_Query_Alert_Mail]   
--
------ ============================================= ***/ 
ALTER PROCEDURE [dbo].[USP_EDW_UAT_Long_Running_Query_Alert_Mail]
--WITH ENCRYPTION
AS
BEGIN
    CREATE TABLE #temp
    (
	[database_name] [sysname] NOT NULL,
	[Duration_hhmmss] [datetime2](7) NOT NULL,
	[Query_ID] [nvarchar](100) NOT NULL,
	[Session_ID] [nvarchar](100) NOT NULL,
	[Status] [nvarchar](100) NOT NULL,
	[Querytext] [nvarchar](max) NOT NULL,
	[login_name] [nvarchar](200) NOT NULL
    );

    INSERT INTO #temp
    SELECT * FROM [dbo].[edw_uat_long_run_query_alerts_tbl] WITH (NOLOCK) 
	--where Servername ='ctsinazprdedssqlmi.inso1a101c37461fa.database.windows.net' and 
	--[Duration_hhmmss] > '0:02:00:00';

    DECLARE @body_HTML1 NVARCHAR(MAX) = N'';
    DECLARE @body_HTML2 NVARCHAR(MAX) = N'';
    DECLARE @hasData BIT = 0;

    -- List of servers to check
    --DECLARE @servers TABLE (ID INT IDENTITY(1,1), Servername NVARCHAR(200));
    --INSERT INTO @servers (Servername)
    --SELECT ServerName FROM [dbo].[MI_Prod_Long_Running_Sessions_tbl] with(nolock)

    ---- Loop through each server and check the condition
    --DECLARE @servername NVARCHAR(200);
    --DECLARE @i INT = 1;
    --DECLARE @serverCount INT;

    --SELECT @serverCount = COUNT(*) FROM @servers;

    --WHILE @i <= @serverCount
    --BEGIN
    --    SELECT @servername = Servername FROM @servers WHERE ID = @i;

        IF EXISTS (SELECT 1 FROM #temp WHERE DATEDIFF(hour, CAST('00:00:00' AS TIME), CAST(Duration_hhmmss AS TIME)) >= 1 )
        BEGIN
            SET @hasData = 1;

            SET @body_HTML1 = @body_HTML1 +
            N'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">EDW UAT Long Running Query Session(s):</font></H2>' +
            N'<table border="1">' +
            N'<font face="fantasy" size="2" font-family:Serif><tr>' +
            N'<th style="background:#87ceeb">Database Name</th>' +
            N'<th style="background:#87ceeb">Duration(HH:MM:SS)</th>' +
            N'<th style="background:#87ceeb">Query ID</th>' +
            N'<th style="background:#87ceeb">Session ID</th>' +
            N'<th style="background:#87ceeb">Status</th>' +
            N'<th style="background:#87ceeb">login_name</th>' +
            N'<th style="background:#87ceeb">Querytext</th>' +
            N'</tr></font>' +
            N'<font face="bold" font-family:Serif color="Black" size="2">' +
   
			ISNULL(CAST((SELECT
                td = [database_name], '',
                td = [Duration_hhmmss], '',
                td = [Query_ID], '',
                td = [Session_ID], '',
                td = [Status], '',
				td = [login_name], '',
                td = [Querytext], ''
               
           
                FROM #temp with(nolock)
                ORDER BY [Duration_hhmmss] DESC
                FOR XML PATH('tr'), TYPE
            ) AS NVARCHAR(MAX)), N'') +
            N'</font></table>';
        END

        -- Debugging: Print intermediate values
        PRINT @body_HTML1;

    END

    IF @hasData = 1
    BEGIN
        SET @body_HTML2 =
        N'<p>
        Hi EDMDBA Team,
        <br>We have observed Long Running Session(s) in EDW UAT environment.Immediate action is necessary to prevent potential system disruptions and ensure continuous performance.<br>
		<br>Note: We will get alert when Query Runtime of a session is greater than one hour.<br>
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
            @profile_name = 'EDMDBA', 
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
		 @recipients='EDMDBA@cognizant.com;balakrishna.mannepalli@cognizant.com',
		 --CRSDBASUPPORT@cognizant.com',
            @subject = 'Critical Alert :EDW UAT Server || Detected Long Running Session(s)';
    END

    DROP TABLE #temp;
    


GO


