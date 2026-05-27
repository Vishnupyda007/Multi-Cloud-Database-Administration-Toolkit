-- Run on the Publisher, in the context of the publication database
--USE [YourPublicationDatabase];
--GO

-- This query reads the active part of the transaction log to find
-- which tables are causing the most DML (Insert, Update, Delete) activity.

SELECT TOP 5
    O.name AS [Table Name], -- CORRECTED: Name comes from sys.objects (aliased as O)
    COUNT(L.PartitionId) AS [Number of Log Records]
FROM
    sys.fn_dblog(NULL, NULL) AS L
INNER JOIN
    sys.allocation_units AS AU ON L.AllocUnitId = AU.allocation_unit_id
INNER JOIN
    sys.partitions AS P ON AU.container_id = P.partition_id
INNER JOIN
    sys.objects AS O ON P.object_id = O.object_id
WHERE
    AU.type_desc = 'IN_ROW_DATA' -- Filters for actual table data, not indexes
    AND O.is_ms_shipped = 0 -- Excludes system tables
    AND L.Operation IN (
        'LOP_INSERT_ROWS',
        'LOP_MODIFY_ROW',
        'LOP_DELETE_ROWS'
    )
GROUP BY
    O.name -- CORRECTED: Group by the name from sys.objects
ORDER BY
    [Number of Log Records] DESC;



----best------------


-- This query must be run on the database that is being published.
USE ent_data_store_uat;
GO

-- A potentially faster version that groups only by table name.
SELECT top 5
    COUNT(*) AS LogRecords,
    S.name AS SchemaName,
    O.name AS TableName
FROM
    fn_dblog(NULL, NULL) AS L
LEFT JOIN
    sys.allocation_units AS AU ON L.AllocUnitId = AU.allocation_unit_id
LEFT JOIN
    sys.partitions AS P ON AU.container_id = P.hobt_id
LEFT JOIN
    sys.objects AS O ON P.object_id = O.object_id
LEFT JOIN
    sys.schemas AS S ON O.schema_id = S.schema_id
WHERE
    AU.type_desc = 'IN_ROW_DATA'
    AND O.is_ms_shipped = 0
    AND O.name IS NOT NULL
    AND L.[Operation] IN ('LOP_INSERT_ROWS', 'LOP_DELETE_ROWS', 'LOP_MODIFY_ROW', 'LOP_MODIFY_COLUMNS')
GROUP BY
    S.name, O.name
ORDER BY
    LogRecords DESC;



----------------or 2nd best-------------------------------


SELECT TOP 5
    @@SERVERNAME AS PublisherServerName,
    S.name AS SchemaName,
    O.name AS TableName,
    COUNT(*) AS TotalLogRecords,
    -- Breakdown of DML Operation types
    COUNT(CASE WHEN L.[Operation] = 'LOP_INSERT_ROWS' THEN 1 END) AS InsertCount,
    COUNT(CASE WHEN L.[Operation] IN ('LOP_MODIFY_ROW', 'LOP_MODIFY_COLUMNS') THEN 1 END) AS UpdateCount,
    COUNT(CASE WHEN L.[Operation] = 'LOP_DELETE_ROWS' THEN 1 END) AS DeleteCount,
    -- Time window of the captured activity
    MIN(L.[Begin Time]) AS FirstActivity,
    MAX(L.[End Time]) AS LastActivity
FROM
    fn_dblog(NULL, NULL) AS L
LEFT JOIN
    sys.allocation_units AS AU ON L.AllocUnitId = AU.allocation_unit_id
LEFT JOIN
    sys.partitions AS P ON AU.container_id = P.hobt_id
LEFT JOIN
    sys.objects AS O ON P.object_id = O.object_id
LEFT JOIN
    sys.schemas AS S ON O.schema_id = S.schema_id
WHERE
    AU.type_desc = 'IN_ROW_DATA'
    AND O.is_ms_shipped = 0
    AND O.name IS NOT NULL
    AND L.[Operation] IN ('LOP_INSERT_ROWS', 'LOP_DELETE_ROWS', 'LOP_MODIFY_ROW', 'LOP_MODIFY_COLUMNS')
GROUP BY
    S.name,
    O.name
ORDER BY
    TotalLogRecords DESC;



-------------------------------------------

-- Run on the Publisher, in the context of the publication database
USE [YourPublicationDatabase];
GO

-- IMPORTANT: This command will read the transaction log just like the Log Reader agent.
-- If the agent is running, you might get an error or block it.
-- It's best to run this when the Log Reader agent is stopped or during a maintenance window.
-- Using 'maxtrans' limits the output to avoid overwhelming your screen.

-- This simulates the Log Reader Agent's work.
-- If you have high activity on non-published tables, this command may take
-- a while to run and still return zero rows.
EXEC sp_replcmds @maxtrans = 10;
GO




-----------------Limitations of fn_dblog func-----------------



That's a very insightful question and a crucial one for any DBA or developer to ask. While `fn_dblog` is a fascinating and powerful tool for quick, real-time diagnostics, it comes with significant limitations that make it unsuitable for robust, long-term monitoring.

Here is a detailed breakdown of its major drawbacks.

### Key Limitations of `fn_dblog`

| Limitation | Implication / Why It Matters |
|:---|:---|
| **Undocumented and Unsupported** | This is the most critical limitation. Microsoft provides no official documentation for `fn_dblog`. Its behavior, columns, and even its existence can change or be removed in any new SQL Server version, cumulative update, or service pack without warning. **Scripts that rely on it can break unexpectedly after an upgrade.** |
| **Performance Impact** | Reading the transaction log is an I/O-intensive operation. Running this query frequently on a high-transaction system can introduce performance overhead and potentially cause contention with other processes that need to write to the log. It is not "free" to run. |
| **It's a Point-in-Time Snapshot** | The function only reads the *active* portion of the transaction log. Once a transaction log backup occurs (in `FULL` recovery model) or a checkpoint happens (in `SIMPLE` recovery model), the log is truncated, and that history is gone from `fn_dblog`. It cannot be used for historical analysis over days or weeks. |
| **Requires `sysadmin` Privileges** | To execute `fn_dblog`, a user must be a member of the `sysadmin` fixed server role. This is a massive security risk. You cannot grant access to this function to regular developers or monitoring accounts, severely limiting who can use it in a production environment. |
| **Output is Complex and Low-Level** | The output is not a clean, logical representation of your SQL statements. It shows physical page modifications. A single `UPDATE` statement might generate dozens of log records (`LOP_MODIFY_ROW`, page splits, etc.). This makes `COUNT(*)` an *approximation* of activity, not an exact statement count. |
| **Dependent on Database Recovery Model** | The script is only truly useful for databases in `FULL` or `BULK_LOGGED` recovery models. In the `SIMPLE` model, the log is reused so aggressively that the window of activity you can see is often just a few seconds or minutes, making it almost useless for analysis. |
| **Not Available in Azure SQL Database** | For security and architectural reasons, you cannot use `fn_dblog` in Azure SQL Database. This makes it a non-starter for any cloud-based monitoring strategy involving PaaS databases. |

---

### What Should You Use Instead for Monitoring?

Given these limitations, `fn_dblog` should be treated as a scalpel for emergency, real-time diagnostics, not as a foundation for a monitoring solution. For proper, supported, and safe monitoring, you should use the tools Microsoft provides:

1.  **Extended Events (XEvents):** This is the modern, lightweight, and official way to trace database activity. You can create a session to specifically track DML operations on certain tables with very little performance overhead. This is the direct replacement for SQL Profiler and the recommended approach.

2.  **Query Store:** While more focused on query performance than table-level changes, it is excellent for identifying queries that are causing high I/O, which often correlates with heavy DML activity.

3.  **System Dynamic Management Views (DMVs):** Views like `sys.dm_db_index_operational_stats` and `sys.dm_db_index_usage_stats` provide aggregated counts of inserts, updates, deletes, and seeks against your tables since the last server restart. This is a great, supported way to see which tables are most active over a long period.

**Conclusion:** It's great that you have the `fn_dblog` script in your toolbox, but always remember it's the emergency tool, not the everyday one. For building a reliable monitoring strategy, stick to Extended Events and DMVs.
