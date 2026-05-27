Azure SQL Database does **not natively track the last modified date** for index operations like **REBUILD** or **REORGANIZE**. However, you can **infer** the last time an index was rebuilt or reorganized by checking the **last updated date of statistics**, since these operations typically update statistics as well.

Here’s a query that helps you **approximate** the last index maintenance date:

```sql
SELECT 
    OBJECT_NAME(s.[object_id]) AS TableName,
    i.name AS IndexName,
    s.name AS StatsName,
    STATS_DATE(s.[object_id], s.stats_id) AS LastStatsUpdate,
    i.type_desc AS IndexType,
    s.auto_created,
    s.user_created
FROM 
    sys.stats AS s
JOIN 
    sys.indexes AS i ON s.object_id = i.object_id AND s.name = i.name
WHERE 
    OBJECTPROPERTY(s.object_id, 'IsUserTable') = 1
ORDER BY 
    LastStatsUpdate DESC;
```

### ?? Notes:
- `STATS_DATE` gives the **last time statistics were updated**, which often correlates with index rebuilds.
- This is **not a guaranteed indicator** of a REBUILD or REORGANIZE unless you log those operations explicitly (e.g., using Ola Hallengren’s `CommandLog` table).

---

### ? Better Tracking Option:
If you're using **Ola Hallengren’s `IndexOptimize`** with `@LogToTable = 'Y'`, you can query the `CommandLog` table directly:

```sql
SELECT 
    DatabaseName,
    SchemaName,
    ObjectName,
    IndexName,
    CommandType,
    StartTime,
    EndTime,
    ErrorMessage
FROM 
    dbo.CommandLog
WHERE 
    CommandType IN ('ALTER_INDEX_REORGANIZE', 'ALTER_INDEX_REBUILD')
ORDER BY 
    StartTime DESC;
```

Let me know if you'd like help setting up this logging or building a dashboard view for it.