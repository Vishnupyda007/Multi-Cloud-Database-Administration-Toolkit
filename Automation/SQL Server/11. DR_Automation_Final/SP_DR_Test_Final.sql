/****** Object:  StoredProcedure [dbo].[DR_INDEX_USER_Roles_ACCESSSCripts]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:<Vishnu P,,2275509>
-- Create date: <03-04-2025,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DR_INDEX_USER_Roles_ACCESSSCripts] with ENCRYPTION
	
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




DECLARE @sql VARCHAR(8000);
DECLARE @sql1 VARCHAR(8000);
DECLARE @sql2 VARCHAR(8000);



SELECT @sql = 'bcp "SELECT ''--createscript--'' UNION ALL SELECT CONVERT(NVARCHAR(MAX), [createscript]) FROM DBAdmin..DRscripts_MI_Users_Roles WHERE CONVERT(DATE, DateT) = CONVERT(DATE, GETDATE()) ORDER BY DateT, Servername, Database_Name, name" queryout \\CTSC00969373301\Backup\temp\test2\CRS_DB_Users_Create_Script.txt -w -t, -T -S' + @@servername;
SELECT @sql1 = 'bcp "SELECT ''--createrolescript--'' UNION ALL SELECT CONVERT(NVARCHAR(MAX), [createrolescript]) FROM DBAdmin..DRscripts_MI_Servers_Roles WHERE CONVERT(DATE, DateT) = CONVERT(DATE, GETDATE()) ORDER BY DateT, Servername, Database_Name, name" queryout \\CTSC00969373301\Backup\temp\test2\CRS_DB_Roles_Create_Script.txt -w -t, -T -S' + @@servername;
SELECT @sql2 = 'bcp "SELECT ''--Index_Details--'' UNION ALL SELECT CONVERT(NVARCHAR(MAX), [Index_Details]) FROM DBAdmin..DRMI_Index_CRS WHERE CONVERT(DATE, DateT) = CONVERT(DATE, GETDATE()) ORDER BY DateT, Servername, Database_Name, name" queryout \\CTSC00969373301\Backup\temp\test2\CRS_DB_Indexes_Create_Script.txt -w -t, -T -S' + @@servername;



--select @sql = 'bcp "select ''createscript''union all select Convert(nvarchar(128),[createscript]) FROM DBAdmin..DRscripts_MI_Users_Roles where convert(Date,DateT)=convert(Date,getdate())" queryout \\CTSC00969373301\Backup\temp\test2\CRS_DB_Users_Create_Script.txt -c -t, -T -S' + @@servername
--select @sql1 = 'bcp "select ''createrolescript''union all select Convert(nvarchar(128),[createrolescript]) FROM DBAdmin..DRscripts_MI_Servers_Roles where convert(Date,DateT)=convert(Date,getdate())" queryout \\CTSC00969373301\Backup\temp\test2\CRS_DB_Roles_Create_Script.txt -c -t, -T -S'+ @@servername
--select @sql2 = 'bcp "select ''Index_Details''union all select Convert(nvarchar(128),[Index_Details]) FROM DBAdmin..DRMI_Index_CRS where convert(Date,DateT)=convert(Date,getdate())" queryout \\CTSC00969373301\Backup\temp\test2\CRS_DB_Indexes_Create_Script.txt -c -t, -T -S'+ @@servername

----bcp "select 'SalesOrderID', 'CarrierTrackingNumber','ModifiedDate','UpdateTime' union all SELECT 
----convert(varchar(20),[SalesOrderID]),convert(varchar(20),[CarrierTrackingNumber]),CONVERT(nvarchar(30), 
--[ModifiedDate], 120),CONVERT(nvarchar(30), [UpdateTime], 120) FROM [testdb].[dbo].[SalesOrderDetailIn]" 
--queryout D:\People.txt -t, -c -T  


----sqlcmd -s, -W -Q "set nocount on; select * from [DATABASE].[dbo].[TABLENAME]" | findstr /v /c:"-" /b > "c:\dirname\file.csv"


exec master..xp_cmdshell @sql
exec master..xp_cmdshell @sql1
exec master..xp_cmdshell @sql2
 


DECLARE @filenames varchar(max)
--DECLARE @file1 VARCHAR(MAX) = '\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset\DRscripts_MI_Users_Roles.csv'
--DECLARE @file2 VARCHAR(MAX) = ';\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset\DRscripts_MI_Servers_Roles.txt'
--DECLARE @file3 VARCHAR(MAX) = ';\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset\DRMI_Index_CRS.csv'

 

---- Create list from optional files
--SELECT @filenames = @file1 + @file3 + @file2
--+ @file3

--DECLARE @FolderPath VARCHAR(255) =  '\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset';
--DECLARE @ZipFilePath VARCHAR(255) = '\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset.zip';
--DECLARE @Command VARCHAR(1000);
 
--SET @Command = '7z a -r "' + @ZipFilePath + '" "' + @FolderPath + '"';
--EXEC master..xp_cmdshell @Command;


Set @filenames='\\CTSC00969373301\Backup\temp\test2.zip'
EXEC xp_cmdshell 'powershell.exe -ExecutionPolicy Bypass -File "\\CTSC00969373301\Backup\temp\Extract.ps1"'
 
-- DELETE FROM your_table
--WHERE your_datetime_column < DATEADD(day, -10, GETDATE()); --yet to update

-- Send the email
EXEC msdb.dbo.sp_send_dbmail
  @profile_name = 'adtaudit',

  @recipients= '2275509@cognizant.com;2191016@cognizant.com;946572@cognizant.com',
  @subject = 'DR_INDEX_USER_Roles_AccessScripts',
 
  @file_attachments = @filenames;


Truncate table DBAdmin.[dbo].[DRMI_Index_CRS]
Truncate table DBAdmin.[dbo].[DRscripts_MI_Servers_Roles]
truncate  table DBAdmin.[dbo].[DRscripts_MI_Users_Roles]

END
GO