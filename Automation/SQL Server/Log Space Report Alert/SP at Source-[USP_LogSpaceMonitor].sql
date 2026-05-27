USE [master]
GO

/****** Object:  StoredProcedure [dbo].[USP_LogSpaceMonitor]    Script Date: 6/17/2025 12:35:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER Proc [dbo].[USP_LogSpaceMonitor] 
AS 
Begin 
 IF(object_id('dbo.Logspace') is NULL)    --need to run first insert query manually due this null condition
Begin   
  Create table Logspace (DBName varchar(200),OldSize Numeric(20,2),CurSize_MB Numeric(20,2),UsedSize Numeric(20,2),GrowthTime datetime,[status] int) 
   
  Insert into Logspace (DBName, CurSize_MB, UsedSize, [Status])   
  Exec('DBCC SQLPERF (Logspace)')    
  Update L set GrowthTime = getdate() , L.RecoveryModel = D.recovery_model_desc,L.LogWait_Description= D.log_reuse_wait_desc
  from LogSpace L   
      join sys.databases D on L.dbname = D.name   
End 
         
Truncate table atLogspace 

Insert Into [dbo].[atLogspace] (DBName, logSize_MB, UsedSpace_Per, [Status])   
Exec('DBCC SQLPERF (Logspace)')  



---Copy Current size to Old Size   
update LogSpace set OldSize = CurSize_MB   
   
--Update Growth Time   
Update Logspace  set GrowthTime = getdate() from Logspace L join [dbo].[atLogspace] T    
on L.DBname = T.DBName   
where L.CurSize_MB <> T.logSize_MB   
   
   
--Copy new data to table   
Update Logspace   
set UsedSize = T.UsedSpace_Per , CurSize_MB = T.logSize_MB   
from Logspace L   
join [dbo].[atLogspace] T    
on L.DBname = T.DBName   
 
select * from [dbo].[atLogspace] with(nolock)
select * from [dbo].[Logspace] with(nolock)
End 
 
GO


