SELECT name as [Database Name], [Last Access Date] =(select MAX(temp.lastaccess)
from ( select lastaccess =
max(last_user_seek)
where max(last_user_seek)is not null
union all
select lastaccess = max(last_user_scan)
where max(last_user_scan)is not null
union all
select lastaccess = max(last_user_lookup)
where max(last_user_lookup) is not null
union all
select lastaccess =max(last_user_update)
where max(last_user_update) is not null) temp)
FROM master.dbo.sysdatabases sysdb
left outer join sys.dm_db_index_usage_stats Idxus
on sysdb.dbid= Idxus.database_id
group by sysdb.name


---------------- OR --------------------------------------------------------

SELECT d.name,
last_user_seek = MAX(last_user_seek),
last_user_scan = MAX(last_user_scan),
last_user_lookup = MAX(last_user_lookup),
last_user_update = MAX(last_user_update)
FROM sys.dm_db_index_usage_stats AS i
JOIN sys.databases AS d ON i.database_id=d.database_id
GROUP BY d.name


-------------------