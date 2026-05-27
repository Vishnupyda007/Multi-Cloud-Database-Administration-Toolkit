--Analyzing index usage statistics in SQL Server can help you understand how indexes are being utilized and identify any that are underused or unused. Here are some methods to gather and analyze index usage statistics:

--Using Dynamic Management Views (DMVs)
--sys.dm_db_index_usage_stats: This DMV provides information about how indexes are used, including the number of seeks, scans, lookups, and updates. Here's a query to get index usage statistics:


SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    u.user_seeks,
    u.user_scans,
    u.user_lookups,
    u.user_updates,
    u.last_user_seek,
    u.last_user_scan,
    u.last_user_lookup,
    u.last_user_update
FROM 
    sys.indexes AS i
    JOIN sys.dm_db_index_usage_stats AS u
        ON i.object_id = u.object_id AND i.index_id = u.index_id
WHERE 
    OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
ORDER BY 
    OBJECT_NAME(i.object_id), i.name;



--sys.dm_db_index_operational_stats: This DMV provides operational statistics for indexes, including information about insert, update, and delete operations, as well as locking and latching. Here's a query to get operational statistics:


SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    o.leaf_insert_count,
    o.leaf_update_count,
    o.leaf_delete_count,
    o.leaf_ghost_count,
    o.row_lock_count,
    o.row_lock_wait_count,
    o.row_lock_wait_in_ms,
    o.page_latch_wait_count,
    o.page_latch_wait_in_ms
--row_lock_count
--row_lock_wait_count
--row_lock_wait_in_ms
--page_lock_count
--page_lock_wait_count
--page_lock_wait_in_ms
--index_lock_promotion_attempt_count
--index_lock_promotion_count
FROM 
    sys.indexes AS i
    JOIN sys.dm_db_index_operational_stats(NULL, NULL, NULL, NULL) AS o
        ON i.object_id = o.object_id AND i.index_id = o.index_id
WHERE 
    OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
ORDER BY 
    OBJECT_NAME(i.object_id), i.name;



--Using SQL Server Management Studio (SSMS) Reports
--Index Usage Statistics Report:

--In SSMS, right-click on the database, go to Reports -> Standard Reports -> Index Usage Statistics. This report provides a graphical view of index usage, including seeks, scans, and updates.
--Index Physical Statistics Report:

--Similarly, you can access the Index Physical Statistics report from the same menu. This report shows the physical layout and fragmentation of indexes.
--Best Practices
--Regular Monitoring: Regularly monitor index usage to identify and remove unused or underused indexes, which can improve performance and reduce maintenance overhead.
--Index Maintenance: Perform regular index maintenance tasks such as rebuilding or reorganizing fragmented indexes to ensure optimal performance3.
--By using these methods, you can effectively analyze and manage your index usage, leading to better database performance and efficiency.

--Let me know if you need any further assistance!

--1: SQL Shack - Gathering SQL Server Indexes Statistics and Usage Information 2: SQL Authority - Index Usage Statistics, Physical Statistics & User Statistics 3: MSSQLTips - How to get index usage information in SQL Server



--1
--Favicon type
--Gathering SQL Server indexes statistics and usage information - SQL Shack

--2
--Favicon type
--SQL SERVER - SSMS: Index Usage Statistics, Physical Statistics & User ...

--3
--Favicon type
--Gathering SQL Server Index Statistics and Usage Information
