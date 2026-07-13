# SQL Server Performance Tuning Scripts

Scripts for identifying slow queries, optimizing indexes, updating statistics, and analyzing execution plans.

---

## Scripts in This Category

### Query Analysis
- **Daily Queries.txt** - 50+ useful daily monitoring queries
- **Sp_whoisactive SP Script.txt** - sp_whoisactive for active query monitoring
- **slow-queries.sql** - Identify slow-running queries
- **Query Performance Analysis.sql** - Detailed query performance metrics

### Index Management
- **IndexOptimize.txt** - Comprehensive index maintenance (40KB+)
- **index-optimization.sql** - Rebuild and reorganize indexes
- **Index strategies.sql** - Indexing best practices

### Statistics
- **statistics-update.sql** - Update table and index statistics
- **Statistics maintenance.sql** - Full statistics management

### Execution Plans
- **execution-plans.sql** - Analyze and interpret plans
- **Query optimizer analysis.sql** - Tune optimizer behavior

### Resource Monitoring
- **system-space-check-queries.txt** - Monitor disk usage
- **CPU, Memory Resource Monitoring.sql** - Track resource utilization
- **Performance baseline collection.sql** - Establish performance baseline

### Waits & Locks
- **Get processID for Locked Sessions.sql** - Find blocking queries
- **Resource and Locks.txt** - Lock investigation
- **DeadLock_Objects.sql** - Deadlock analysis

---

## Performance Tuning Process

### Step 1: Establish Baseline
```sql
-- Capture current performance metrics
SELECT 
    d.name AS DatabaseName,
    CONVERT(NUMERIC(10,2), SUM(size)*8/1024.0) AS 'Size(MB)',
    CONVERT(NUMERIC(10,2), SUM(FILEPROPERTY(name, 'SpaceUsed'))*8/1024.0) AS 'Used(MB)'
FROM sys.master_files mf
JOIN sys.databases d ON mf.database_id = d.database_id
GROUP BY d.name;
```

### Step 2: Identify Slow Queries
```sql
-- Find top 10 expensive queries
SELECT TOP 10
    qs.sql_handle,
    qs.execution_count,
    qs.total_elapsed_time/1000000.0 AS 'Total Sec',
    qs.total_elapsed_time/qs.execution_count/1000.0 AS 'Avg MilliSec',
    SUBSTRING(st.text, 1, 80) AS 'Query'
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.total_elapsed_time DESC;
```

### Step 3: Analyze Execution Plan
```sql
-- See query execution plan
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT * FROM YourTable WHERE SomeColumn = 'Value';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
```

### Step 4: Optimize
- Check indexes (missing, unused, fragmented)
- Update statistics
- Rewrite query if needed
- Consider table structure

### Step 5: Verify Improvement
```sql
-- Re-run metrics to compare
-- Should see:
-- - Reduced execution time
-- - Reduced reads/writes
-- - Reduced CPU
```

---

## Common Tasks

### Find Slow Queries
```sql
-- Queries taking most time
SELECT TOP 20
    DB_NAME(qt.dbid) AS DatabaseName,
    SUBSTRING(qt.text, 1, 80) AS QueryText,
    qs.execution_count,
    qs.total_elapsed_time/1000000.0 AS TotalSeconds,
    qs.total_elapsed_time/qs.execution_count/1000.0 AS AvgMilliseconds
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.total_elapsed_time DESC;
```

### Check Index Fragmentation
```sql
-- Find fragmented indexes (>10% fragmented)
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.index_type_desc,
    CONVERT(NUMERIC(5,2), ips.avg_fragmentation_in_percent) AS 'Fragmentation %'
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id 
    AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10
    AND ips.page_count > 1000
ORDER BY ips.avg_fragmentation_in_percent DESC;
```

### Rebuild Index
```sql
-- Rebuild highly fragmented index (>30%)
ALTER INDEX IX_YourIndex ON dbo.YourTable REBUILD;

-- Reorganize moderately fragmented index (10-30%)
ALTER INDEX IX_YourIndex ON dbo.YourTable REORGANIZE;
```

### Update Statistics
```sql
-- Update all statistics in database
EXEC sp_updatestats;

-- Update specific table statistics
UPDATE STATISTICS YourTable;
```

### Monitor Active Queries
```sql
-- Show currently executing queries
SELECT 
    er.session_id,
    er.status,
    SUBSTRING(st.text, 1, 80) AS 'Query',
    er.logical_reads,
    er.reads,
    er.writes,
    er.cpu_time
FROM sys.dm_exec_requests er
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE er.session_id > 50;
```

### Find Missing Indexes
```sql
-- Identify frequently used missing indexes
SELECT TOP 20
    d.statement AS TableName,
    d.equality_columns,
    d.inequality_columns,
    d.included_columns,
    s.avg_total_user_cost,
    s.avg_user_impact,
    s.user_seeks
FROM sys.dm_db_missing_index_details d
JOIN sys.dm_db_missing_index_groups_stats s ON d.index_handle = s.index_handle
ORDER BY (s.avg_total_user_cost * s.avg_user_impact * s.user_seeks) DESC;
```

---

## Prerequisites

- SQL Server 2016 SP2+
- VIEW SERVER STATE permission
- ALTER INDEX permission
- UPDATE STATISTICS permission
- Query analysis tools (SSMS, SSDT)
- Baseline metrics for comparison

---

## Best Practices

### Query Optimization
- ✅ Use indexes wisely (but not too many)
- ✅ Update statistics regularly (daily or weekly)
- ✅ Avoid functions in WHERE clauses
- ✅ Use appropriate data types
- ✅ Minimize sorting and grouping
- ❌ Don't use SELECT * in production
- ❌ Don't create unnecessary indexes
- ❌ Don't ignore table statistics

### Index Management
- ✅ Rebuild fragmented indexes (>30%)
- ✅ Reorganize moderate fragments (10-30%)
- ✅ Remove unused indexes
- ✅ Monitor index bloat
- ✅ Regular maintenance (daily or weekly)
- ❌ Don't rebuild every index automatically
- ❌ Don't ignore performance impact of new indexes

### Monitoring
- ✅ Monitor CPU usage
- ✅ Monitor I/O (reads/writes)
- ✅ Monitor lock contention
- ✅ Track long-running queries
- ✅ Set up alerts for anomalies

---

## Troubleshooting

### High CPU Usage
```sql
-- Find queries using most CPU
SELECT TOP 10
    qs.sql_handle,
    qs.cpu_time,
    qs.execution_count,
    SUBSTRING(st.text, 1, 80)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.cpu_time DESC;
```

### High I/O (Disk Activity)
```sql
-- Queries with most logical reads
SELECT TOP 10
    qs.sql_handle,
    qs.logical_reads,
    qs.execution_count,
    SUBSTRING(st.text, 1, 80)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.logical_reads DESC;
```

### Blocked Sessions
```sql
-- Find blocking relationships
SELECT 
    r1.session_id AS BlockingSession,
    r2.session_id AS BlockedSession,
    SUBSTRING(st.text, 1, 80) AS Query
FROM sys.dm_exec_requests r1
JOIN sys.dm_exec_requests r2 ON r1.session_id = r2.blocking_session_id
CROSS APPLY sys.dm_exec_sql_text(r2.sql_handle) st;
```

---

## Related Files

- **Administration:** `../administration/`
- **Backup & Recovery:** `../backup-recovery/`
- **Monitoring:** `../monitoring/`
- **Troubleshooting:** `../troubleshooting/`

---

**Last Updated:** 2026-07-13  
**Versions:** SQL Server 2016+  
**Status:** Production-Ready