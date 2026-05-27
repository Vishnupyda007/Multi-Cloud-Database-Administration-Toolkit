ALTER PROCEDURE [dbo].[PAAS_Master_Replication_Tables_List]
with ENCRYPTION	
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




declare @sql varchar(8000)


select @sql = 'bcp "select  ''Publication'',''Article'',''Subsriber_Server'',''DestinationDB'' union all select convert(nvarchar(128),[Publication]),convert(nvarchar(128),isnull([Article],'''')),convert(nvarchar(128),isnull([DestinationDB],''''))  FROM DBAdmin..EDS_DEV_Repli_Tables_List" queryout \\CTSC01048405301\Packages\EDS_DEV_Repli_List.xlsx -c -t, -T -S'+ @@Servername;
--SELECT @sql =  'bcp "select studentid from tmseprd.dbo.Feith_Emas_Compare Where status = 'U' and counselor >199  and stage > 200 " queryout "C:\EMAS_Feith\advmove.txt" -c -t, -T  -S' + @@Servername;

--union all select convert(nvarchar(128),[Servername]),convert(nvarchar(128),[jobname]),convert(nvarchar128),[Outcome]) FROM ADT_Audit..DE_SQL_jobs" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\DE_SQLjobs\DE_SQLjobs.csv -c -t, -T -S' 
--select @sql = 'bcp "select ''servername'',''DBName'',''FileName'',''Type_desc'',''CurrentSizeMB'',''FreeSpaceMB''union all select convert(nvarchar(128),[Servername]),convert(nvarchar(128),[DBName]),convert(nvarchar(128),[FileName]),Convert(nvarchar(128),[Type_Desc]),Convert(nvarchar(128),[CurrentSizeMB]),Convert(nvarchar(128),[FreeSpaceMB]) FROM ADT_Audit..CRS_MI_WeeklySpace" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Datafilesizedetails.csv -c -t, -T -S' + @@servername

----bcp "select 'SalesOrderID', 'CarrierTrackingNumber','ModifiedDate','UpdateTime' union all SELECT 
----convert(varchar(20),[SalesOrderID]),convert(varchar(20),[CarrierTrackingNumber]),CONVERT(nvarchar(30), 
--[ModifiedDate], 120),CONVERT(nvarchar(30), [UpdateTime], 120) FROM [testdb].[dbo].[SalesOrderDetailIn]" 
--queryout D:\People.txt -t, -c -T  


----sqlcmd -s, -W -Q "set nocount on; select * from [DATABASE].[dbo].[TABLENAME]" | findstr /v /c:"-" /b > "c:\dirname\file.csv"


exec master..xp_cmdshell @sql

 


DECLARE @filenames varchar(max)
DECLARE @file1 VARCHAR(MAX) = '\\CTSC01048405301\Packages\EDS_DEV_Repli_List.xlsx'

--DECLARE @file3 VARCHAR(MAX) = ';C:\Testfiles\Test3.csv'

 

-- Create list from optional files
SELECT @filenames = @file1 



 

-- Send the email
EXEC msdb.dbo.sp_send_dbmail
  @profile_name = 'CRS',
  @recipients= 'PydaVenkata.SrihimaVishnuSeshasai@cognizant.com',
  @subject = 'PAAS Master Replication Tables List Report',
  @body= 'Hi Team,
Please find the attached DE_SQL_job status',
  @file_attachments = @filenames

END


GO