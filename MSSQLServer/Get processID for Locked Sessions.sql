-----to check proccess ID for locked sessions

----use with (no lock) at end of the query to avoid locking

--sp_LOCK


-----------OR-----------
SELECT
    SP.spid AS ProcessID,
    SP.status AS ProcessStatus,
    SP.loginame AS LoginName,
    SP.hostname AS HostName,
    SP.cmd AS Command,
CDB.name AS DatabaseName,
    SP.cpu AS CPUUsage,
    SP.physical_io AS IOResources
FROM
    master.dbo.sysprocesses SP
INNER JOIN
    master.dbo.sysdatabases CDB ON SP.dbid = CDB.dbid
ORDER BY
    SP.cpu DESC;


	------------------OR-------------------------------
	To get the process ID of locked sessions in SQL Server Management Studio (SSMS), you can use the following SQL query:
 
```sql
SELECT
    request_session_id AS SessionID,
    resource_type AS ResourceType,
    DB_NAME(resource_database_id) AS DatabaseName,
    request_mode AS LockType,
    request_status AS LockStatus,
    request_owner_type AS OwnerType,
    resource_description AS Description,
    resource_associated_entity_id AS AssociatedEntityID
FROM
    sys.dm_tran_locks
WHERE
    request_status = 'WAIT'
```
 
This query will show you the session ID (`request_session_id`) of the locked sessions, along with other relevant information such as the resource type, database name, lock type, lock status, owner type, description, and associated entity ID.