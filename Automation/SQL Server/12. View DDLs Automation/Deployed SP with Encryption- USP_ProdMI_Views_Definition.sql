USE [1CDBAMonitoring]
GO

/****** Object:  StoredProcedure [dbo].[USP_ProdMI_Views_Definition]    Script Date: 7/4/2025 12:17:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:<Vishnu P,,2275509>
-- Create date: <04-07-2025,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[USP_ProdMI_Views_Definition] with Encryption
	
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

DECLARE @sql1 VARCHAR(8000);
DECLARE @sql2 VARCHAR(8000);
DECLARE @sql3 VARCHAR(8000);
DECLARE @sql4 VARCHAR(8000);
DECLARE @sql5 VARCHAR(8000);
DECLARE @sql6 VARCHAR(8000);
DECLARE @sql7 VARCHAR(8000);
DECLARE @sql8 VARCHAR(8000);
DECLARE @sql9 VARCHAR(8000);
DECLARE @sql10 VARCHAR(8000);
DECLARE @sql11 VARCHAR(8000);
DECLARE @sql12 VARCHAR(8000);
DECLARE @sql13 VARCHAR(8000);
DECLARE @sql14 VARCHAR(8000);
DECLARE @sql15 VARCHAR(8000);

SELECT @sql1 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_BC1" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_BC1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql2 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_BC2" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_BC2.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql3 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_BC3" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_BC3.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql4 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_DE1" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_DE1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql5 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_MC1" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_MC1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql6 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_NC1" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_NC1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql7 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_NC2" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_NC2.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql8 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_PFD" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_PFD.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql9 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_PGN" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_PGN.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql10 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_PPLT" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_PPLT.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql11 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_PRDML01" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_PRDML01.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql12 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_PST" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_PST.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql13 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_PTM" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_PTM.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql14 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_PTM1" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_PTM1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql15 = 'bcp "SELECT FormattedView FROM [1CDBAMonitoring].[dbo].ViewsDefinition_R1Cloud" queryout "E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod\EDS_Views_DDLs_R1Cloud.txt" -w -t, -T -S CTSINAZSIPDDB06'


exec master..xp_cmdshell @sql1 
exec master..xp_cmdshell @sql2 
exec master..xp_cmdshell @sql3 
exec master..xp_cmdshell @sql4 
exec master..xp_cmdshell @sql5 
exec master..xp_cmdshell @sql6 
exec master..xp_cmdshell @sql7 
exec master..xp_cmdshell @sql8 
exec master..xp_cmdshell @sql9 
exec master..xp_cmdshell @sql10
exec master..xp_cmdshell @sql11
exec master..xp_cmdshell @sql12
exec master..xp_cmdshell @sql13
exec master..xp_cmdshell @sql14
exec master..xp_cmdshell @sql15

DECLARE @filenames varchar(max)

Set @filenames='E:\1CDBA_Data_Donot_Delete\EDS_Views_DDLs_Prod.zip'
EXEC xp_cmdshell 'powershell.exe -ExecutionPolicy Bypass -File "E:\1CDBA_Data_Donot_Delete\Extract_ViewDDLs.ps1"'
 


-- Send the email
EXEC msdb.dbo.sp_send_dbmail
  @profile_name = 'ITOps1CDBA',
  @recipients='EDSDev@cognizant.com',
  @copy_recipients= 'CRSDBASUPPORT@cognizant.com;EDMDBA@cognizant.com',
  --@copy_recipients='VijaiAnand.PV@cognizant.com;KiranKumar.Gannavaram@cognizant.com;
  --Ashwathi.K@cognizant.com;BalaKrishna.Mannepalli@cognizant.com;2275509@cognizant.com',
  @subject = 'Automated Mailer: View DDL Scripts || Prod Portfolio Servers',
  @body = '<html><body style="font-family:serif;">Hi Team,<br><br>Please find the latest <b>EDS View DDLs</b> extracted from the <b>1C Prod MI Portfolio Servers</b>.<br><br>Note : If you require the most up-to-date View DDLs for analysis or reference, please utilize the attached file.</br><br>Regards,<br><b>ITOps 1CDBA Team<b></body></html>',
    @body_format = 'HTML',

  @file_attachments = @filenames;



END
GO


