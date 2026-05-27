
SET NOCOUNT ON

IF OBJECT_ID(N'tempdb..#Memory_Percent') IS NOT NULL
BEGIN
DROP TABLE #Memory_Percent
END
GO
declare @Memory_Threshold int = 98
SELECT top 1 end_time,
       avg_instance_memory_percent
	   INTO #Memory_Percent
FROM sys.dm_db_resource_stats

select * from #Memory_Percent where avg_instance_memory_percent > @Memory_Threshold
