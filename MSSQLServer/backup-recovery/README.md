# SQL Server Backup & Recovery Scripts

Scripts for creating backups, performing restores, point-in-time recovery, and disaster recovery procedures.

---

## Scripts in This Category

### Full Backups
- **Shrink data_log files, backup&restore, check orphan users after restore.txt** - Complete backup workflow
- **full-backup.sql** - Create full database backup (recommended: daily)

### Transaction Log Backups
- **Log_Backup_OnPrem.txt** - Configure transaction log backups
- **Log size and log space % usage by DBs in a Server.sql** - Monitor log usage

### Restore Procedures
- **Percentage query for restoring.txt** - Monitor restore progress
- **Script for data and log file relocation while restoring(OnPrem).sql** - Restore to different location
- **on prem restore ui.txt** - Step-by-step restore UI guide

### Point-in-Time Recovery
- **Recovery procedures** - Advanced recovery options
- **backup-recovery-procedure.txt** - Detailed procedures

### Cloud Backup (Azure)
- **ONPREM_Azure Backup Scripts.txt** - Backup on-premises database to Azure
- **Latest_Cloud_Backup_Key_credentials_Prod&NonProd_Recreate.sql** - Cloud credential setup
- **Cloud Credential Key.txt** - Azure credential configuration

---

## Backup Strategy

### Recommended Schedule

| Type | Frequency | Retention | Purpose |
|------|-----------|-----------|----------|
| Full | Daily (off-peak) | 7-30 days | Complete database copy |
| Transaction Log | Every 15-60 min | 1-7 days | Enable point-in-time recovery |
| Differential | Every 6 hours | 3-7 days | Faster recovery than full |

### Backup to Cloud

**For Azure:**
- Copy backups to Azure Blob Storage
- Use Azure credential with SQL Server
- Enables geo-redundancy
- Meets disaster recovery requirements

---

## Common Tasks

### Create Full Backup
```sql
-- Simple full backup
BACKUP DATABASE YourDatabase
TO DISK = 'C:\Backups\YourDatabase_full.bak'
WITH
    INIT,
    COMPRESSION,
    STATS = 10,
    CHECKSUM,
    DESCRIPTION = 'Full backup';
```

### Create Transaction Log Backup
```sql
-- Transaction log backup (enables point-in-time recovery)
BACKUP LOG YourDatabase
TO DISK = 'C:\Backups\YourDatabase_log.trn'
WITH
    INIT,
    COMPRESSION,
    STATS = 5,
    CHECKSUM;
```

### Create Differential Backup
```sql
-- Differential backup (only changed pages since last full)
BACKUP DATABASE YourDatabase
TO DISK = 'C:\Backups\YourDatabase_diff.bak'
WITH
    INIT,
    COMPRESSION,
    DIFFERENTIAL,
    STATS = 10,
    CHECKSUM;
```

### Restore Database
```sql
-- Basic restore
RESTORE DATABASE YourDatabase_Restored
FROM DISK = 'C:\Backups\YourDatabase_full.bak'
WITH
    REPLACE,
    RECOVERY,
    STATS = 10;
```

### Restore to Different Location
```sql
-- Restore and relocate files
RESTORE DATABASE YourDatabase_Restored
FROM DISK = 'C:\Backups\YourDatabase_full.bak'
WITH
    MOVE 'YourDatabase' TO 'D:\Data\YourDatabase_restored.mdf',
    MOVE 'YourDatabase_log' TO 'E:\Logs\YourDatabase_restored.ldf',
    REPLACE,
    RECOVERY,
    STATS = 10;
```

### Point-in-Time Recovery
```sql
-- Restore to specific point in time
RESTORE DATABASE YourDatabase
FROM DISK = 'C:\Backups\YourDatabase_full.bak'
WITH NORECOVERY, STATS = 10;

-- Restore transaction logs up to point in time
RESTORE LOG YourDatabase
FROM DISK = 'C:\Backups\YourDatabase_log.trn'
WITH RECOVERY,
    STOPAT = '2026-07-13 14:30:00',
    STATS = 5;
```

### Check Backup History
```sql
-- View recent backups
SELECT 
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.type,
    CONVERT(NUMERIC(10,2), bs.backup_size/1048576) AS 'Size(MB)',
    bs.database_name
FROM msdb.dbo.backupset bs
WHERE bs.database_name = 'YourDatabase'
ORDER BY bs.backup_start_date DESC;
```

### Monitor Restore Progress
```sql
-- Watch restore progress in real-time
SELECT 
    r.session_id,
    r.command,
    CONVERT(NUMERIC(6,2), r.percent_complete) AS 'Progress %',
    CONVERT(VARCHAR(20), DATEADD(second, r.estimated_completion_time/1000, GETDATE()), 20) AS 'Est Completion'
FROM sys.dm_exec_requests r
WHERE r.command IN ('RESTORE DATABASE', 'RESTORE LOG');
```

---

## Prerequisites

- SQL Server 2016 SP2+
- BACKUP DATABASE permission
- RESTORE DATABASE permission
- Sufficient disk space for backups
- For Azure: Azure storage account + credentials
- For testing: Separate test environment

---

## Best Practices

### Backup
- ✅ Use COMPRESSION (saves 50-90% space)
- ✅ Use CHECKSUM (verify backup integrity)
- ✅ Store backups off-site (disaster recovery)
- ✅ Test restores regularly (verify backup integrity)
- ✅ Use full + transaction log + differential
- ✅ Document backup location and credentials
- ❌ Don't keep backups on same server
- ❌ Don't backup during peak hours

### Recovery
- ✅ Test restore procedures monthly
- ✅ Know your RTO (Recovery Time Objective)
- ✅ Know your RPO (Recovery Point Objective)
- ✅ Have written recovery procedures
- ✅ Train team on recovery procedures
- ✅ Keep backup media in good condition
- ❌ Don't restore to production without testing first

### Monitoring
- ✅ Monitor backup success/failure
- ✅ Alert on backup failures
- ✅ Track backup duration
- ✅ Monitor disk space
- ✅ Review backup size trends

---

## Disaster Recovery Planning

### Step 1: Define RTO & RPO
- **RTO** (Recovery Time Objective): Max acceptable downtime (e.g., 1 hour)
- **RPO** (Recovery Point Objective): Max data loss acceptable (e.g., 15 minutes)

### Step 2: Implement Backup Strategy
Based on RTO/RPO requirements:
- RTO < 1 hour + RPO < 15 min → Full + frequent transaction log backups
- RTO < 4 hours + RPO < 1 hour → Daily full + hourly differential

### Step 3: Test Recovery
- Perform monthly restore tests
- Document recovery procedures
- Time the recovery process
- Verify data integrity

### Step 4: Monitor Continuously
- Alert on backup failures
- Track backup size/duration trends
- Monitor storage capacity

---

## Troubleshooting

### Backup fails with "Not enough space"
```sql
-- Check available disk space
EXEC xp_fixeddrives;

-- Check backup file sizes
SELECT 
    database_name,
    CONVERT(NUMERIC(10,2), backup_size/1048576) AS 'Size(MB)'
FROM msdb.dbo.backupset
WHERE database_name = 'YourDatabase'
ORDER BY backup_start_date DESC;
```

### Restore fails with "File is already in use"
```sql
-- Kill connections to database being restored
ALTER DATABASE YourDatabase SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

-- Retry restore
RESTORE DATABASE YourDatabase FROM DISK = 'C:\backup.bak';

-- Set back to multi-user
ALTER DATABASE YourDatabase SET MULTI_USER;
```

### Can't find backup file
```sql
-- Check backup locations
EXEC sp_helpfile;

-- Search recent backups
SELECT TOP 10 
    backup_start_date,
    physical_device_name
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bm ON bs.media_set_id = bm.media_set_id
WHERE database_name = 'YourDatabase'
ORDER BY backup_start_date DESC;
```

---

## Related Files

- **Administration:** `../administration/`
- **Performance:** `../performance/`
- **Monitoring:** `../monitoring/`
- **Replication:** `../replication/`
- **Troubleshooting:** `../troubleshooting/`

---

**Last Updated:** 2026-07-13  
**Versions:** SQL Server 2016+  
**Status:** Production-Ready