
SET NOCOUNT ON

IF OBJECT_ID(N'tempdb..#IO_Percent') IS NOT NULL
BEGIN
DROP TABLE #IO_Percent
END
GO
declare @IO_Threshold int = 90
SELECT top 1 end_time,avg_data_io_percent,avg_log_write_percent
INTO #IO_Percent
FROM sys.dm_db_resource_stats


select * from #IO_Percent where (avg_data_io_percent > @IO_Threshold OR avg_log_write_percent > @IO_Threshold)
