USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[MI_Prod_Servers_Storage_Utilization_Report]    Script Date: 2/12/2025 12:01:44 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/***** Object:  StoredProcedure [dbo].[MI_Prod_Servers_Storage_Utilization_Report]    Script Date: 11-11-2024 2.10.03 PM ******/     
-- =============================================    
-- Author:  <Hima Vishnu P>    
-- Create date: <12-03-2025>    
-- Description: <Description,,>    
------ =============================================  
ALTER PROCEDURE [dbo].[MI_Prod_Servers_Storage_Utilization_Report]
with ENCRYPTION
AS
BEGIN
  --SET NOCOUNT ON added to prevent extra result sets from
  --interfering with SELECT statements.

  CREATE TABLE #temp(
    Servername nvarchar(200),
    total_TB Decimal(9,3),
    Used_TB decimal(9,3),
    Available_GB decimal(9,3),
    [percent] int
  );

  INSERT INTO #temp
  SELECT * FROM MI_Prod_Servers_Storage_Utilization_Tracker WITH (NOLOCK);

  UPDATE #temp
  SET [percent] = ((Available_GB / (Total_TB * 1024)) * 100);

  IF EXISTS (SELECT 1 FROM #temp WHERE [percent] < 30)
  BEGIN
    DECLARE @date Nvarchar(MAX);
    SET @date = GETDATE();
    DECLARE @html varchar(MAX) =
    N'<p>
    Hi ITOps 1C DBA Team,
    <br>Please find the below Production MI Server(s) with free space less than 30%.<br>
    <br><br>
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
            p {
            font-family:Serif;
            }
    </style>

    <table id="tablaPrincipal">
    <tr>
    <th>Server Name</th>
    <th>Total Space(TB)</th>
    <th>Used Space(TB)</th>
    <th>Available Space(GB)</th>
    <th>Available Space(%)</th>
    </tr>';

    SELECT @html = @html +
    '<tr style="color:' + CASE WHEN [percent] < 20 THEN 'orange' WHEN [percent] < 15 THEN 'red' ELSE 'black' END + ';">
    <td>' + Servername + '</td>
    <td>' + CAST(Total_TB AS nvarchar(2000)) + '</td>
    <td>' + CAST(Used_TB AS nvarchar(2000)) + '</td>
    <td>' + CAST(Available_GB AS nvarchar(2000)) + '</td>
    <td>' + CAST([percent] AS nvarchar(2000)) + '</td>
    </tr>'
    FROM #temp WITH (NOLOCK)
    WHERE [percent] < 30
    ORDER BY [percent] ASC;

    DROP TABLE #temp;

    EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'CRS',
	@recipients ='RaviShankar.C@cognizant.com;Janani.M2dcbb3@cognizant.com;Badam.Navya@cognizant.com; Bindu.Raavi@cognizant.com;pradheep.kumartk@cognizant.com; megha.singhal@cognizant.com;
		Sneha.S5@cognizant.com;Vimalraj.S3@cognizant.com;vidya.erragopula@cognizant.com;
		Burra.Sandhya@cognizant.com;PydaVenkata.SrihimaVishnuSeshasai@cognizant.com;EDMDBA@cognizant.com',    
    @copy_recipients='rambabu.s@cognizant.com;vijaianand.pv@cognizant.com;kirankumar.gannavaram@cognizant.com;
		ashwathi.k@cognizant.com;balakrishna.mannepalli@cognizant.com', 
    @body = @html,
    @body_format = 'HTML',
    @subject = 'Warning: Production MI Server(s) Free Storage below 30%';
  END
  ELSE
  BEGIN
    DROP TABLE #temp;
  END
END
GO