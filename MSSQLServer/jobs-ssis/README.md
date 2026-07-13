# SQL Server Jobs & SSIS Packages

Scripts for creating and managing SQL Agent jobs, scheduling maintenance tasks, and SSIS package execution.

---

## Scripts in This Category

### SQL Agent Jobs
- **create-backup-job.sql** - Schedule automated backups
- **create-maintenance-job.sql** - Schedule maintenance tasks
- **job-execution-tracking.sql** - Monitor job execution

### Job Scheduling
- **schedule-daily-backup.sql** - Daily backup schedule
- **schedule-maintenance-window.sql** - Off-hours maintenance
- **enable-job-notifications.sql** - Job failure alerts

### SSIS Packages
- **Package execution Flow - SSIS and Normal Package.txt** - SSIS execution methods
- **ssis-package-execution.sql** - Run SSIS packages
- **ssis-error-handling.sql** - SSIS error handling

### Job Monitoring
- **job-history-analysis.sql** - Review job execution history
- **failed-job-investigation.sql** - Debug failed jobs
- **job-performance-analysis.sql** - Monitor job duration trends

---

## SQL Agent Jobs

### Create Backup Job
```sql
-- Step 1: Create backup job
EXEC msdb.dbo.sp_add_job
    @job_name = N'Daily Full Backup',
    @enabled = 1,
    @description = N'Full database backup daily at 2 AM';

-- Step 2: Add job step
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Daily Full Backup',
    @step_name = N'Backup YourDatabase',
    @subsystem = N'TSQL',
    @command = N'BACKUP DATABASE YourDatabase TO DISK = N"C:\\Backups\\YourDatabase_full.bak" WITH INIT, COMPRESSION;',
    @retry_attempts = 2,
    @retry_interval = 5;

-- Step 3: Add schedule
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Daily 2 AM',
    @freq_type = 4,  -- Daily
    @freq_interval = 1,
    @active_start_time = 020000;  -- 2:00 AM

-- Step 4: Attach schedule to job
EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'Daily Full Backup',
    @schedule_name = N'Daily 2 AM';
```

### Create Maintenance Job
```sql
-- Step 1: Create maintenance job
EXEC msdb.dbo.sp_add_job
    @job_name = N'Weekly Maintenance',
    @enabled = 1,
    @description = N'Maintenance tasks';

-- Step 2: Add job steps
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Weekly Maintenance',
    @step_name = N'Update Statistics',
    @subsystem = N'TSQL',
    @command = N'EXEC sp_updatestats;',
    @on_success_action = 3;  -- Go to next step

EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Weekly Maintenance',
    @step_name = N'Rebuild Indexes',
    @subsystem = N'TSQL',
    @command = N'ALTER INDEX ALL ON dbo.YourTable REBUILD;';
```

### Schedule Job
```sql
-- Daily schedule
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Daily',
    @freq_type = 4,           -- Daily
    @freq_interval = 1,       -- Every day
    @active_start_time = 020000;  -- 2:00 AM

-- Weekly schedule (Sunday)
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Weekly Sunday',
    @freq_type = 8,           -- Weekly
    @freq_interval = 1,       -- Sunday
    @active_start_time = 030000;  -- 3:00 AM

-- Monthly schedule (1st of month)
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Monthly',
    @freq_type = 16,          -- Monthly
    @freq_interval = 1;       -- 1st day
```

### Monitor Job Execution
```sql
-- View job history
SELECT 
    j.name AS JobName,
    h.run_date,
    h.run_time,
    h.run_status,
    CASE h.run_status 
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Cancelled'
    END AS Status,
    h.message
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
ORDER BY h.run_date DESC, h.run_time DESC;

-- View currently running jobs
SELECT 
    j.name AS JobName,
    ja.run_requested_date,
    DATEDIFF(MINUTE, ja.run_requested_date, GETDATE()) AS MinutesRunning
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobactivity ja ON j.job_id = ja.job_id
WHERE ja.stop_execution_date IS NULL;
```

### Enable Job Notifications
```sql
-- Setup Database Mail first
EXEC msdb.dbo.sysmail_configure_sp
    @parameter_name = 'LoggingLevel',
    @parameter_value = '1';

-- Create job alert
EXEC msdb.dbo.sp_add_alert
    @name = N'Backup Job Failed',
    @event_source = 'SQLServerAgent',
    @enabled = 1,
    @alert_type = 101,
    @performance_condition = 'SQL Server:General Statistics|User Connections||>|10';

-- Add notification
EXEC msdb.dbo.sp_add_notification
    @alert_name = N'Backup Job Failed',
    @operator_name = N'DBA Team',
    @notification_method = 1;  -- Email
```

---

## SSIS Packages

### Execute SSIS Package
```sql
-- Execute SSIS package (SQL Server 2012+)
EXEC msdb.dbo.sp_start_job @job_name = N'SSIS Package - Import Data';

-- Execute with parameters (SQL Server 2016+)
EXEC [SSISDB].[catalog].[create_execution]
    @folder_name = N'Imports',
    @project_name = N'DataImport',
    @package_name = N'ImportCustomers.dtsx',
    @use32bitruntime = 0,
    @execution_id = @ExecutionID OUTPUT;

EXEC [SSISDB].[catalog].[start_execution] @ExecutionID;
```

### Monitor SSIS Execution
```sql
-- View package execution history
SELECT 
    e.folder_name,
    e.project_name,
    e.package_name,
    e.start_time,
    e.end_time,
    e.status
FROM [SSISDB].[catalog].[executions] e
ORDER BY e.start_time DESC;

-- View execution details
SELECT 
    l.event_name,
    l.message,
    l.message_time
FROM [SSISDB].[catalog].[event_messages] l
WHERE l.execution_id = @ExecutionID
ORDER BY l.message_time DESC;
```

---

## Best Practices

### Job Design
- ✅ Keep jobs focused (single responsibility)
- ✅ Use meaningful names
- ✅ Add error handling (retry logic)
- ✅ Set notifications on failure
- ✅ Schedule during off-peak hours
- ✅ Monitor job duration trends
- ❌ Don't create long-running synchronous jobs
- ❌ Don't ignore job failures

### Scheduling
- ✅ Schedule backups during low-usage windows
- ✅ Stagger jobs to avoid resource contention
- ✅ Document schedules
- ✅ Test jobs before production
- ✅ Review job history regularly
- ❌ Don't schedule during peak hours
- ❌ Don't run too many jobs simultaneously

### Monitoring
- ✅ Check job history daily
- ✅ Alert on failures
- ✅ Track job duration trends
- ✅ Monitor job impact on system
- ✅ Keep job logs

---

## Troubleshooting

### Job Failed
```sql
-- Check job history
EXEC msdb.dbo.sp_help_jobhistory
    @job_name = 'BackupJob',
    @step_name = NULL,
    @sql_message_id = NULL,
    @sql_severity = NULL,
    @start_run_date = NULL,
    @end_run_date = NULL,
    @start_run_time = NULL,
    @end_run_time = NULL;

-- Check error message
SELECT message FROM msdb.dbo.sysjobhistory 
WHERE job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'BackupJob')
ORDER BY run_date DESC;
```

### Job Not Running
```sql
-- Check if SQL Agent is running
SELECT * FROM sys.services WHERE service_name = 'MSSQLSERVER';

-- Check if job is enabled
SELECT name, enabled FROM msdb.dbo.sysjobs WHERE name = 'BackupJob';

-- Enable job
EXEC msdb.dbo.sp_update_job
    @job_name = 'BackupJob',
    @enabled = 1;
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