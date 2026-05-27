SELECT DB_NAME(resource_database_id) AS DatabaseName, COUNT(*) AS TotalSessions
FROM sys.dm_tran_locks
GROUP BY DB_NAME(resource_database_id)
order by db_name(resource_database_id)