# SQL Server Troubleshooting & Diagnostics

Scripts and procedures for diagnosing and resolving common SQL Server issues.

---

## Scripts in This Category

### Deadlocks
- **DeadLock_Objects.sql** - Find deadlock victims
- **deadlock-analysis.sql** - Analyze deadlock graphs
- **deadlock-prevention.sql** - Best practices to avoid

### Blocking & Locking
- **Get processID for Locked Sessions.sql** - Find blocking sessions
- **blocking-sessions.sql** - Identify blocking queries
- **Resource and Locks.txt** - Lock investigation
- **Script to check long running sessions and killing it.txt** - Kill blocking sessions

### Connection Issues
- **connection-troubleshooting.sql** - Diagnose connection problems
- **IP_Address_Port_Number, Server Version, ipconfig.txt** - Network config
- **How to get last logged in date for user.txt** - Track access
- **How-to test TCP connectivity from a SQL Managed Instance.sql** - Test connectivity

### Orphaned Users
- **Orphan user autofix.txt** - Fix orphaned users
- **orphan-user-detection.sql** - Find orphaned users
- **orphan-user-repair.sql** - Repair procedure

### Compatibility Issues
- **Compatibility set and query optimizer fixes.txt** - Database compatibility
- **database-compatibility-check.sql** - Check compatibility level

### Replication Failures
- **replication-error-analysis.sql** - Diagnose replication issues
- **replication-synchronization.sql** - Resync failing subscriptions

### Backup Issues
- **backup-failure-analysis.sql** - Diagnose backup failures
- **backup-recovery-validation.sql** - Verify backup integrity

### Data Recovery
- **data-recovery-procedures.txt** - Recover deleted data
- **transaction-log-recovery.sql** - Restore to point in time

---

## Common Issues & Solutions

### Deadlock

**Symptoms:**
- Applications receive "Deadlock victim" errors
- Transaction rollbacks
- Users experiencing random failures

**Diagnosis:**
```sql
-- Enable deadlock trace
TRACE ON -T1222;  -- Graph format
TRACE ON -T1204;  -- Detailed format

-- Find deadlock in error log
EXEC sp_readerrorlog 0, 1, 'Deadlock graph';
```

**Solution:**
```sql
-- 1. Identify tables involved
-- 2. Ensure consistent access order
-- 3. Use shorter transactions
-- 4. Add indexes to reduce lock escalation
-- 5. Use isolation level READ COMMITTED SNAPSHOT

ALTER DATABASE YourDatabase SET READ_COMMITTED_SNAPSHOT ON;
```

---

### Blocking Sessions

**Symptoms:**
- Long-running queries
- Other queries waiting
- "Session timed out" errors

**Diagnosis:**
```sql
-- Find blocking relationships
SELECT 
    r1.session_id AS BlockingSession,
    r2.session_id AS BlockedSession,
    DATEDIFF(SECOND, r2.start_time, GETDATE()) AS WaitSeconds,
    SUBSTRING(st.text, 1, 100) AS Query
FROM sys.dm_exec_requests r1
JOIN sys.dm_exec_requests r2 ON r1.session_id = r2.blocking_session_id
CROSS APPLY sys.dm_exec_sql_text(r2.sql_handle) st;
```

**Solution:**
```sql
-- Option 1: Wait for blocking query to complete
WAITFOR DELAY '00:05:00';

-- Option 2: Kill blocking session (careful!)
KILL 54;  -- session_id

-- Option 3: Optimize blocking query
-- - Add indexes
-- - Rewrite query
-- - Split into smaller transactions
```

---

### Orphaned Database User

**Symptoms:**
- "Cannot create user, login already exists"
- "User without login"

**Diagnosis:**
```sql
-- Find orphaned users
EXEC sp_change_users_login 'Report';
```

**Solution:**
```sql
-- Automatic fix (recreate login)
EXEC sp_change_users_login 'Auto_Fix', 'username';

-- Manual fix
CREATE LOGIN username WITH PASSWORD = 'NewPassword123!';
EXEC sp_change_users_login 'Update_One', 'username', 'username';
```

---

### Connection Failures

**Symptoms:**
- "Cannot connect to server"
- "Timeout expired"
- "Network error"

**Diagnosis:**
```sql
-- Check SQL Server is running
-- Check TCP is enabled (SQL Server Configuration Manager)
-- Check firewall allows port 1433
-- Test connectivity
telnet SERVERNAME 1433

-- Check SQL Server error log
EXEC sp_readerrorlog 0, 1;
```

**Solution:**
```powershell
# Check if SQL Server service is running
Get-Service MSSQLSERVER

# Start if not running
Start-Service MSSQLSERVER

# Check TCP/IP is enabled
# SQL Server Configuration Manager > Protocols > TCP/IP > Enabled

# Check firewall
netsh advfirewall firewall add rule name="SQL Server" dir=in action=allow program="C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Binn\sqlservr.exe" enable=yes
```

---

### High CPU/Memory

**Symptoms:**
- Server unresponsive
- Slow query execution
- Memory pressure

**Diagnosis:**
```sql
-- Find expensive queries
SELECT TOP 10
    qs.sql_handle,
    qs.cpu_time/1000000.0 AS CPUSeconds,
    qs.execution_count,
    SUBSTRING(st.text, 1, 80)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY qs.cpu_time DESC;
```

**Solution:**
```sql
-- 1. Identify slow queries
-- 2. Add missing indexes
-- 3. Update statistics
-- 4. Rewrite queries
-- 5. Increase server resources (last resort)

UPDATE STATISTICS YourTable;
ALTER INDEX IX_YourIndex ON YourTable REBUILD;
```

---

### Failed Backups

**Symptoms:**
- Backup job fails
- Error messages in SQL Agent
- No backup files created

**Diagnosis:**
```sql
-- Check backup history
SELECT TOP 10
    backup_start_date,
    backup_finish_date,
    type,
    CASE WHEN type = 'D' THEN 'Full'
         WHEN type = 'I' THEN 'Differential'
         WHEN type = 'L' THEN 'Log'
         ELSE type END AS BackupType
FROM msdb.dbo.backupset
ORDER BY backup_start_date DESC;

-- Check SQL Agent job history
EXEC msdb.dbo.sp_help_job @job_name = 'BackupJob';
```

**Solution:**
```sql
-- Check disk space
EXEC xp_fixeddrives;

-- Check permissions
-- Verify backup folder writable
-- Verify account running SQL Agent has permissions

-- Manual test
BACKUP DATABASE YourDatabase
TO DISK = 'C:\Backups\Test.bak'
WITH INIT, COMPRESSION;
```

---

## Diagnostic Queries

### Overall Health Check
```sql
SELECT 
    @@SERVERNAME AS ServerName,
    @@VERSION AS Version,
    GETDATE() AS CurrentTime,
    (SELECT COUNT(*) FROM sys.databases) AS DatabaseCount,
    (SELECT COUNT(*) FROM sys.sysprocesses WHERE status = 0) AS RunningProcesses;
```

### Check Database Integrity
```sql
-- DBCC CHECKDB (can take time on large databases)
DBCC CHECKDB (YourDatabase, NOINDEX);
```

### Check Error Log
```sql
-- View last 100 error log entries
EXEC sp_readerrorlog 0, 1;
```

---

## Best Practices

### Prevention
- ✅ Monitor proactively (don't wait for issues)
- ✅ Update statistics regularly
- ✅ Maintain indexes
- ✅ Keep error logs
- ✅ Test recovery procedures
- ✅ Plan for high availability
- ❌ Don't ignore warnings
- ❌ Don't skip maintenance

### Response
- ✅ Document the issue
- ✅ Don't panic (think first)
- ✅ Isolate the problem
- ✅ Don't kill random sessions
- ✅ Have a rollback plan
- ❌ Don't modify production without testing
- ❌ Don't ignore messages

---

## Related Files

- **Administration:** `../administration/`
- **Performance:** `../performance/`
- **Monitoring:** `../monitoring/`
- **Backup & Recovery:** `../backup-recovery/`
- **Replication:** `../replication/`

---

**Last Updated:** 2026-07-13  
**Versions:** SQL Server 2016+  
**Status:** Production-Ready