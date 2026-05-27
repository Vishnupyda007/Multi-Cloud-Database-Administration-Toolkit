SELECT OBJECT_NAME(OBJECT_ID) AS TableName,
last_user_update,*
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID( 'CentralRepository')
AND OBJECT_ID=OBJECT_ID('dbo.CentralRepository_Practice')