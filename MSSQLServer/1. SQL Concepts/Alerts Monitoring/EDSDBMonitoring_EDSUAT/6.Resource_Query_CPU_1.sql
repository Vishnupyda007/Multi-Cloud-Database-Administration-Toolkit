
SET NOCOUNT ON

IF OBJECT_ID(N'tempdb..#CPU_Percent') IS NOT NULL
BEGIN
DROP TABLE #CPU_Percent
END
GO
declare @cpu_Threshold int = 90
SELECT top 1 end_time,avg_cpu_percent
       INTO #CPU_Percent
FROM sys.dm_db_resource_stats

select * from #CPU_Percent where avg_cpu_percent > @cpu_Threshold




/*
SELECT top 10 end_time,
       avg_instance_memory_percent
FROM sys.dm_db_resource_stats

SELECT top 10 end_time,avg_data_io_percent,avg_log_write_percent
FROM sys.dm_db_resource_stats



*/