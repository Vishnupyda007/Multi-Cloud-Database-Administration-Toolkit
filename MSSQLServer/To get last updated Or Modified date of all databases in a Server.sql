select  * from sys.dm_db_index_usage_stats
WHERE database_id = DB_ID('ARCProjectionDB') 
order by last_user_update desc;



----------------OR-----------------

SELECT
    DB_NAME(database_id) AS DatabaseName,
    MAX(last_user_update) AS LastUserUpdate
FROM
    sys.dm_db_index_usage_stats
GROUP BY
    database_id;



-------------------------OR----------------------------
	SELECT
    d.name AS [DatabaseName],
    MAX(s.last_user_update) AS [LastUpdateTime]
FROM
    sys.dm_db_index_usage_stats AS s
INNER JOIN
    sys.databases AS d ON s.database_id = d.database_id
WHERE
    d.database_id > 4 -- Exclude system databases
GROUP BY
    d.name
ORDER BY
    [LastUpdateTime] DESC;
