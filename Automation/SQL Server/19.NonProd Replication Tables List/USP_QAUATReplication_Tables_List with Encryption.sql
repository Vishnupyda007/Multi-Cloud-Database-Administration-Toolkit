USE [1CDBAMonitoring]
GO

/****** Object:  StoredProcedure [dbo].[USP_QAUATReplication_Tables_List]    Script Date: 7/4/2025 12:17:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:<Vishnu P,,2275509>
-- Create date: <04-07-2025,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[USP_QAUATReplication_Tables_List] with Encryption
	
AS

BEGIN
	
--To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  

--DECLARE @sql1 VARCHAR(8000);
--DECLARE @sql2 VARCHAR(8000);


--SELECT @sql1 = 'bcp "SELECT * FROM [1CDBAMonitoring].[dbo].ProdReplicationTablesList" queryout "E:\1CDBA_Data_Donot_Delete\Prod_Replication_Tables_List\1C_Prod_Portfolio_Replication_Tables_List.csv" -w -t, -T -S CTSINAZSIPDDB06'




DECLARE @sql NVARCHAR(4000);
DECLARE @sql1 NVARCHAR(4000);

SET @sql = 'bcp "SELECT * FROM [1CDBAMonitoring].[dbo].[vw_EDS_QA_ReplicationTablesList_WithHeaders]" queryout "E:\1CDBA_Data_Donot_Delete\NonProd_Replication_Tables_List\EDS_QA_Replication_Tables_List.csv" -c -t, -T -S CTSINAZSIPDDB06';


SET @sql1 = 'bcp "SELECT * FROM [1CDBAMonitoring].[dbo].[vw_EDS_UAT_ReplicationTablesList_WithHeaders]" queryout "E:\1CDBA_Data_Donot_Delete\NonProd_Replication_Tables_List\EDS_UAT_Replication_Tables_List.csv" -c -t, -T -S CTSINAZSIPDDB06';


EXEC master..xp_cmdshell @sql;
EXEC master..xp_cmdshell @sql1;




--📌 Notes:
---c = character format (plain text)
---t, = comma as delimiter (CSV)
---T = trusted connection (Windows auth)
---S = your SQL Server name



--SELECT @sql2 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_BC2" 
--queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_BC2.txt" -w -t, -T -S CTSINAZSIPDDB06'


--exec master..xp_cmdshell @sql1 
--exec master..xp_cmdshell @sql2 



DECLARE @filenames varchar(max)

Set @filenames='E:\1CDBA_Data_Donot_Delete\NonProd_Replication_Tables_List\EDS_QA_Replication_Tables_List.csv;E:\1CDBA_Data_Donot_Delete\NonProd_Replication_Tables_List\EDS_UAT_Replication_Tables_List.csv'
--EXEC xp_cmdshell 'powershell.exe -ExecutionPolicy Bypass -File "E:\1CDBA_Data_Donot_Delete\Extract_ViewDDLs.ps1"'
 


-- Send the email
EXEC msdb.dbo.sp_send_dbmail
  @profile_name = 'ITOps1CDBA',
  @recipients='EDSRequirementTeam@cognizant.com;KEERTHANA.SEKHARAN@cognizant.com;EDSDev@cognizant.com',
  @copy_recipients= 'CRSDBASUPPORT@cognizant.com;EDMDBA@cognizant.com',
  --@copy_recipients='VijaiAnand.PV@cognizant.com;KiranKumar.Gannavaram@cognizant.com;
  --Ashwathi.K@cognizant.com;BalaKrishna.Mannepalli@cognizant.com;2275509@cognizant.com',
  --@copy_recipients='2275509@cognizant.com;BalaKrishna.Mannepalli@cognizant.com;
  --Vedurupavuluri.Neha@cognizant.com',
  @subject = 'Reminder: EDS NonProd Replication Tables List || EDS QA || EDS UAT',
  @body = '<html><body style="font-family:serif;">Hi Team,<br><br>Please find the latest list of EDS NonProd Replication Tables for <b>EDS QA to 1C SIT Portfolio, EDS UAT to 1C UAT Portfolio Servers</b>.<br><br>Note : If you require the most up-to-date EDS NonProd Replication tables List for analysis or reference, please utilize the attached file.</br><br>Regards,<br><b>ITOps 1C-EDM DBA Team<b></body></html>',
    @body_format = 'HTML',

  @file_attachments = @filenames;

END
GO


