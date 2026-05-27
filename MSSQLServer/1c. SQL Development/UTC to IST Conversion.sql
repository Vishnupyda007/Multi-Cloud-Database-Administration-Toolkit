SELECT top 1 avg_cpu_percent,avg_log_write_percent,avg_memory_usage_percent,max_worker_percent,dateadd(minute,330,end_time) as Captured_time
FROM sys.dm_db_resource_stats
ORDER BY end_time DESC;

select end_time at time zone 'UTC' at time zone 'India Standard TIme' as ISTTIme from sys.dm_db_resource_stats