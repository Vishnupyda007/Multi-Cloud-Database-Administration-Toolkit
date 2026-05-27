

/****** Object:  StoredProcedure [dbo].[USP_NonProd_Top_LogReaderAgent_Tables_Alert]    Script Date: 2/25/2025 9:14:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  StoredProcedure [dbo].[USP_NonProd_Top_LogReaderAgent_Tables_Alert]        
--SET ANSI_NULLS ON        
--GO        
--SET QUOTED_IDENTIFIER ON        
--GO        
-- =============================================        
-- Author:  <Hima Vishnu P>        
-- Create date: <06:11PM,19 January,2026>        
-- Description: <Description,,>       
--- EXEC [USP_Prod_Long_Running_Sessions_Alert]   
--
------ ============================================= ***/ 
ALTER PROCEDURE [dbo].[USP_NonProd_Top_LogReaderAgent_Tables_Alert]
WITH ENCRYPTION
AS
BEGIN
    CREATE TABLE #temp
    (
	[Publisher Server] [sysname] NOT NULL,
	[Table SchemaName] [sysname] NOT NULL,
	[Table Name] [sysname] NOT NULL,
	[TotalLogRecords] [bigint] NULL,
	[InsertCount] [bigint] NULL,
	[UpdateCount] [bigint] NULL,
	[DeleteCount] [bigint] NULL,
	[CapturedDate] [datetime] NULL
    );

    INSERT INTO #temp
    SELECT * FROM [EDSMONITORINGNP].[dbo].[EDS_NonProd_Top_Active_Transactions_tbl] WITH (NOLOCK) 
	where [TotalLogRecords] > 500000;

    DECLARE @body_HTML1 NVARCHAR(MAX) = N'';
    DECLARE @body_HTML2 NVARCHAR(MAX) = N'';
    DECLARE @hasData BIT = 0;

    -- List of servers to check, use distinct here to get only unique servers and no repetion of data
    DECLARE @servers TABLE (ID INT IDENTITY(1,1), Servername NVARCHAR(200));
    INSERT INTO @servers (Servername)
    SELECT distinct [Publisher Server] FROM [EDSMONITORINGNP].[dbo].[EDS_NonProd_Top_Active_Transactions_tbl] with(nolock)

    -- Loop through each server and check the condition
    DECLARE @servername NVARCHAR(200);
    DECLARE @i INT = 1;
    DECLARE @serverCount INT;

    SELECT @serverCount = COUNT(*) FROM @servers;

    WHILE @i <= @serverCount
    BEGIN
        SELECT @servername = Servername FROM @servers WHERE ID = @i;

        IF EXISTS (SELECT 1 FROM #temp WHERE [Publisher Server] = @servername)
        BEGIN
            SET @hasData = 1;

            SET @body_HTML1 = @body_HTML1 +
            N'<H2 align="Left"><font face="Lucida Bright" color="blue" size="2.5">' + @servername + ' Tables with LogReader Scans:</font></H2>' +
            N'<table border="1">' +
            N'<font face="fantasy" size="2" font-family:Serif><tr>' +
            N'<th style="background:#87ceeb">Publisher Server</th>' +
            N'<th style="background:#87ceeb">Table SchemaName</th>' +
            N'<th style="background:#87ceeb">Table Name</th>' +
            N'<th style="background:#87ceeb">TotalLogRecords</th>' +
            N'<th style="background:#87ceeb">InsertCount</th>' +
            N'<th style="background:#87ceeb">UpdateCount</th>' +
            N'<th style="background:#87ceeb">DeleteCount</th>' + 
            N'<th style="background:#87ceeb">CapturedDate(DD HH:MM:SS)</th>' +
            N'</tr></font>' +
            N'<font face="bold" font-family:Serif color="Black" size="2">' +
            ISNULL(CAST((SELECT
                td = [Publisher Server], '',
                td = [Table SchemaName], '',
                td = [Table Name], '',
                td = [TotalLogRecords], '',
                td = [InsertCount], '',
                td = [UpdateCount], '',               
                td = [DeleteCount], '',
				td = [CapturedDate], ''
               
                FROM #temp with(nolock)
                WHERE [Publisher Server] = @servername
                ORDER BY [TotalLogRecords] DESC
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
        <br>Below are the List of table(s) with High LogReader Agent Active Scans.<br>
		<br>Note: We will get alert when the TotalLog Records of tables greater than 5Lakhs count.<br>
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
            @subject = 'Critical Alert : EDS Non-Prod Tables with High LogReader Active Scan | LogReader Agent Tracker';
    END

    DROP TABLE #temp;
    
END
GO