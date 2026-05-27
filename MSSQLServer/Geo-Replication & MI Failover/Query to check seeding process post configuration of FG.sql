select name as database_Name,* from sys.dm_hadr_physical_seeding_stats hadr left join sys.databases d on hadr.local_database_id=
d.database_id


--https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-hadr-physical-seeding-stats?view=azuresqldb-current

