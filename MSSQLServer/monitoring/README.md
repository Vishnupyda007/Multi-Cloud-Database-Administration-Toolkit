# SQL Server Monitoring & Health Checks

Scripts for monitoring server health, tracking resource usage, performance metrics, and alerting.

---

## Scripts in This Category

### Health Checks
- **health-check.sql** - Comprehensive server health status
- **Status of Databases.txt** - List all database states
- **Things to check After completing server remediation on an MS SQL Server.txt** - Post-maintenance checklist

### Resource Monitoring
- **CPU, Health Checks Related/** - CPU usage monitoring
- **Resource Utilization.sql** - Track CPU, memory, disk
- **System Space Check Queries.txt** - Monitor disk usage
- **DB total size, consumed size, free size script.txt** - Database size analysis

### Active Sessions
- **Total Sessions by DB in a server.sql** - Session count per database
- **Get processID for Locked Sessions.sql** - Find blocking sessions
- **Local_Port, Local_Address, Client_Address, Net_Transport.sql** - Network info

### Disk & Storage
- **CheckFileGroupSize.sql** - Monitor filegroup usage
- **File location script.txt** - Database file locations
- **Log size and log space % usage by DBs in a Server.sql** - Log file monitoring

### Performance Metrics
- **Daily Queries.txt** - 50+ daily monitoring queries
- **Sp_whoisactive SP Script.txt** - Activity monitoring stored procedure
- **IP_Address_Port_Number, Server Version, ipconfig.txt** - Server configuration

### Error & Event Logs
- **error-log-analysis.sql** - Review error logs
- **Event monitoring.sql** - Track important events
- **System Mails sent, unsent, failure Query.sql** - Database mail status

---

## Common Tasks

### Check Server Health
```sql
-- Quick health status
SELECT 
    @@SERVERNAME AS ServerName,
    @@VERSION AS SQLVersion,
    (SELECT COUNT(*) FROM sys.databases) AS DatabaseCount,
    (SELECT COUNT(*) FROM sys.sysprocesses WHERE status = 'runnable') AS RunningProcesses,
    GETDATE() AS CurrentTime;

-- Database status
SELECT name, state_desc, recovery_model_desc 
FROM sys.databases 
ORDER BY name;
```

### Monitor CPU Usage
```sql
-- CPU usage over time
SELECT 
    GETDATE() AS CheckTime,
    (SELECT COUNT(*) FROM sys.dm_exec_requests) AS ActiveQueries,
    (SELECT SUM(cpu_time)/1000000.0 FROM sys.dm_exec_requests) AS CPUSeconds,
    (SELECT SUM(total_elapsed_time)/1000000.0 FROM sys.dm_exec_query_stats) AS TotalElapsedSeconds;
```

### Monitor Memory Usage
```sql
-- SQL Server memory usage
SELECT 
    physical_memory_in_use_kb / 1024.0 AS 'Physical Memory Used (MB)',
    large_page_allocations_kb / 1024.0 AS 'Large Pages (MB)',
    locked_page_allocations_kb / 1024.0 AS 'Locked Pages (MB)',
    total_virtual_address_space_kb / 1024.0 / 1024.0 AS 'Total VAS (GB)'
FROM sys.dm_os_process_memory;
```

### Monitor Disk Space
```sql
-- Available disk space
EXEC xp_fixeddrives;

-- Database size
SELECT 
    name AS DatabaseName,
    CONVERT(NUMERIC(10,2), size*8/1024.0) AS 'Size(MB)',
    CONVERT(NUMERIC(10,2), FILEPROPERTY(name, 'SpaceUsed')*8/1024.0) AS 'Used(MB)',
    CONVERT(NUMERIC(10,2), (size - FILEPROPERTY(name, 'SpaceUsed'))*8/1024.0) AS 'Free(MB)'
FROM sys.database_files
ORDER BY size DESC;
```

### Monitor Transaction Log
```sql
-- Log file usage
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    name AS FileName,
    CONVERT(NUMERIC(10,2), size*8/1024.0) AS 'Size(MB)',
    CONVERT(NUMERIC(6,2), (FILEPROPERTY(name, 'SpaceUsed')*8/1024.0)/((size*8/1024.0))*100) AS 'Used %'
FROM sys.database_files
WHERE type_desc = 'LOG'
ORDER BY DB_NAME(database_id);
```

### Active Sessions & Connections
```sql
-- Who's connected
SELECT 
    session_id,
    login_name,
    program_name,
    login_time,
    last_request_end_time,
    DATEDIFF(MINUTE, login_time, GETDATE()) AS 'Minutes Connected'
FROM sys.dm_exec_sessions
WHERE session_id > 50
ORDER BY session_id;
```

### Find Blocking Sessions
```sql
-- Blocking relationships
SELECT 
    r1.session_id AS BlockingSession,
    r2.session_id AS BlockedSession,
    SUBSTRING(st.text, 1, 100) AS Query,
    DATEDIFF(SECOND, r2.start_time, GETDATE()) AS WaitSeconds
FROM sys.dm_exec_requests r1
JOIN sys.dm_exec_requests r2 ON r1.session_id = r2.blocking_session_id
CROSS APPLY sys.dm_exec_sql_text(r2.sql_handle) st;
```

### Monitor Recent Errors
```sql
-- SQL Server error log
CREATE TABLE #ErrorLog (
    LogDate DATETIME, ProcessInfo NVARCHAR(20), Text NVARCHAR(MAX)
);

INSERT INTO #ErrorLog
EXEC sp_readerrorlog;

SELECT TOP 20 * FROM #ErrorLog 
WHERE Text LIKE '%Error%' OR Text LIKE '%Fail%'
ORDER BY LogDate DESC;

DROP TABLE #ErrorLog;
```

---

## Best Practices

### Monitoring Strategy
- ✅ Monitor 24/7 (or at minimum during business hours)
- ✅ Set baselines for normal operation
- ✅ Alert on anomalies (not just thresholds)
- ✅ Track trends (growth, degradation)
- ✅ Review logs daily
- ✅ Archive old logs
- ❌ Don't ignore warnings
- ❌ Don't set thresholds too high/low

### Alert Thresholds (Example)
- CPU > 80% for > 5 minutes
- Memory < 20% free
- Disk < 20% free
- Transaction log > 90% used
- Blocking > 30 seconds
- Failed backups
- Replication lag > 1 minute

### Reporting
- ✅ Daily health report
- ✅ Weekly performance report
- ✅ Monthly capacity planning review
- ✅ Archive reports for trend analysis

---

## Troubleshooting

### High CPU Usage
```sql
-- Identify expensive queries
SELECT TOP 10
    qs.sql_handle,
    qs.cpu_time/1000000.0 AS 'CPU Seconds',
    qs.execution_count,
    qs.cpu_time/qs.execution_count/1000.0 AS 'Avg CPU ms',
    SUBSTRING(st.text, 1, 80) AS Query
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.cpu_time DESC;
```

### High Memory Pressure
```sql
-- Check memory usage
SELECT 
    name,
    COUNT(*) AS ObjectCount,
    SUM(single_pages_kb) AS 'Pages (KB)'
FROM sys.dm_os_memory_clerks
GROUP BY name
ORDER BY SUM(single_pages_kb) DESC;
```

### Disk Full Alert
```sql
-- Emergency: shrink transaction log (last resort)
ALTER DATABASE YourDatabase SET RECOVERY SIMPLE;
DBCC SHRINKFILE (YourDatabase_log, 100);
ALTER DATABASE YourDatabase SET RECOVERY FULL;
BACKUP LOG YourDatabase TO DISK = 'C:\backup.bak';
```

---

## Related Files

- **Administration:** `../administration/`
- **Backup & Recovery:** `../backup-recovery/`
- **Performance:** `../performance/`
- **Replication:** `../replication/`
- **Troubleshooting:** `../troubleshooting/`

---

**Last Updated:** 2026-07-13  
**Versions:** SQL Server 2016+  
**Status:** Production-Ready