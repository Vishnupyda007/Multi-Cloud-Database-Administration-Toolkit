----Unused or rarely used indexes in SQL Server can consume unnecessary resources and negatively impact performance.
--Use the below script to identify unused indexes in the database:

SELECT
   o.name AS ObjectName,
   i.name AS IndexName,
   user_seeks + user_scans + user_lookups AS Reads,
   user_updates AS Writes
FROM
   sys.dm_db_index_usage_stats ius
JOIN
   sys.indexes i ON i.index_id = ius.index_id AND i.object_id = ius.object_id
JOIN
   sys.objects o ON i.object_id = o.object_id
WHERE
   OBJECTPROPERTY(o.object_id, 'IsUserTable') = 1
   AND i.index_id > 0
   AND user_seeks + user_scans + user_lookups = 0
ORDER BY
   Writes DESC, Reads DESC;


--------------------or----------------------------------

--Identifying unused indexes in SQL Server can help improve performance by reducing unnecessary overhead. Here are some steps and a query to help you identify unused indexes:


--Best Practices
--Review Before Dropping: Always review the indexes identified as unused before dropping them. Some indexes might be used infrequently but are still important for specific queries or reports.
--Monitor Over Time: Since the DMV data is reset on SQL Server restart, it's a good idea to monitor index usage over a period of time to get a more accurate picture.
--Test in Development: Before making changes in production, test the impact of dropping indexes in a development environment.
--By following these steps, you can effectively identify and manage unused indexes, leading to better database performance and efficiency.
--Using Dynamic Management Views (DMVs)
--sys.dm_db_index_usage_stats: This DMV provides information about how indexes are used. If an index is not listed in this DMV, it means it hasn't been used since the last SQL Server restart.
--Query to Identify Unused Indexes: You can use the following query to find unused indexes:


SELECT 
    s.name AS SchemaName,
    o.name AS TableName,
    i.name AS IndexName,
    i.index_id AS IndexID,
    dm_ius.user_seeks AS UserSeeks,
    dm_ius.user_scans AS UserScans,
    dm_ius.user_lookups AS UserLookups,
    dm_ius.user_updates AS UserUpdates,
    'DROP INDEX ' + QUOTENAME(i.name) + ' ON ' + QUOTENAME(s.name) + '.' + QUOTENAME(o.name) AS DropStatement
FROM 
    sys.indexes AS i
    INNER JOIN sys.objects AS o ON i.object_id = o.object_id
    INNER JOIN sys.schemas AS s ON o.schema_id = s.schema_id
    LEFT JOIN sys.dm_db_index_usage_stats AS dm_ius 
        ON i.object_id = dm_ius.object_id AND i.index_id = dm_ius.index_id
WHERE 
    o.type = 'U' -- User tables
    AND i.type_desc = 'NONCLUSTERED'
    AND i.is_primary_key = 0
    AND i.is_unique_constraint = 0
    AND (dm_ius.user_seeks IS NULL 
         AND dm_ius.user_scans IS NULL 
         AND dm_ius.user_lookups IS NULL)
ORDER BY 
    s.name, o.name, i.name;


---------------Script 2:------------------------


-- Unused Index Script
-- Original Author: Pinal Dave 
SELECT TOP 25
o.name AS ObjectName
, i.name AS IndexName
, i.index_id AS IndexID
, dm_ius.user_seeks AS UserSeek
, dm_ius.user_scans AS UserScans
, dm_ius.user_lookups AS UserLookups
, dm_ius.user_updates AS UserUpdates
, p.TableRows
, 'DROP INDEX ' + QUOTENAME(i.name)
+ ' ON ' + QUOTENAME(s.name) + '.'
+ QUOTENAME(OBJECT_NAME(dm_ius.OBJECT_ID)) AS 'drop statement'
FROM sys.dm_db_index_usage_stats dm_ius
INNER JOIN sys.indexes i ON i.index_id = dm_ius.index_id 
AND dm_ius.OBJECT_ID = i.OBJECT_ID
INNER JOIN sys.objects o ON dm_ius.OBJECT_ID = o.OBJECT_ID
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
INNER JOIN (SELECT SUM(p.rows) TableRows, p.index_id, p.OBJECT_ID
FROM sys.partitions p GROUP BY p.index_id, p.OBJECT_ID) p
ON p.index_id = dm_ius.index_id AND dm_ius.OBJECT_ID = p.OBJECT_ID
WHERE OBJECTPROPERTY(dm_ius.OBJECT_ID,'IsUserTable') = 1
AND dm_ius.database_id = DB_ID()
AND i.type_desc = 'nonclustered'
AND i.is_primary_key = 0
AND i.is_unique_constraint = 0
ORDER BY (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups) ASC
GO





--Review Index Usage:

--Before dropping any index, review its usage over a period of time to ensure it is truly unused. Consider monitoring index usage for at least a few weeks.
--Test in Development:

--Test the impact of dropping indexes in a development or staging environment before making changes in production.
--Check Dependencies:

--Ensure that the index is not part of any constraints (e.g., unique constraints, primary keys) that are critical for the application1.
--Backup:

--Take a backup of the database before making any changes. This ensures you can restore the database if needed.
--Drop Index:

--Once you are confident that the index is unused and safe to drop, use the generated DROP INDEX statement to remove the index.
--Example Drop Statement
--The query above generates a DROP INDEX statement for each unused index. You can execute these statements to drop the indexes safely.

--Monitoring After Dropping
--After dropping the indexes, monitor the database performance to ensure there are no negative impacts. If any issues arise, you can restore the indexes from the backup.





-------------------***Imp Article***-----------------

https://www.sqlshack.com/how-to-identify-and-monitor-unused-indexes-in-sql-server/