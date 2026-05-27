-- Log % used
SET NOCOUNT ON
IF OBJECT_ID(N'tempdb..#tlogtables_temp') IS NOT NULL
BEGIN
DROP TABLE #tlogtables_temp
END
GO

IF OBJECT_ID(N'tempdb..#tlogtables') IS NOT NULL
BEGIN
DROP TABLE #tlogtables
END
GO

IF OBJECT_ID(N'tempdb..#tlogtablesfinal') IS NOT NULL
BEGIN
DROP TABLE #tlogtablesfinal
END
GO

DECLARE @threshold   INT = 60



CREATE TABLE #tlogtables_temp
(
   databaseName   sysname,
   logSize        DECIMAL (18, 5),
   logUsed        DECIMAL (18, 5),
   status         INT
)

INSERT INTO #tlogtables_temp
EXECUTE ('DBCC SQLPERF(LOGSPACE)')

SELECT databaseName,
       logSize,
       logUsed,
       status
	   into #tlogtables
  FROM #tlogtables_temp
 WHERE logUsed >= (@threshold) and databaseName NOT IN ('master','msdb','model')

 
select a.*,b.log_reuse_wait_desc into #tlogtablesfinal from #tlogtables a 
INNER JOIN sys.databases b 
on a.[DatabaseName] = b.name 


 select @@servername as MI,*,1 as [Table_Status],getdate() as Date_Collection from #tlogtablesfinal

 