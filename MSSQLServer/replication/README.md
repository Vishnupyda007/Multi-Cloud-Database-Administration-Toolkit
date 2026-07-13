# SQL Server Replication & High Availability

Scripts for setting up and managing transactional replication, failover, and high availability configurations.

---

## Scripts in This Category

### Replication Setup
- **setup-replication.sql** - Configure transactional replication
- **Geo-Replication & MI Failover/** - Azure-specific replication
- **Query to get the table list in replication.txt** - List replicated tables

### Monitoring Replication
- **monitor-replication.sql** - Monitor replication status
- **Replication lag monitoring.sql** - Track synchronization
- **Replication health checks.sql** - Verify replication integrity

### Failover
- **failover-procedure.txt** - Manual failover steps
- **Failover testing guide.sql** - Test failover procedures
- **Failover validation.sql** - Verify failover readiness

### High Availability
- **High Availablity/** - HA configuration guides
- **Always On setup.sql** - Configure SQL Server Always On
- **Availability Group monitoring.sql** - Monitor AG status

---

## Replication Fundamentals

### Replication Types

**Transactional Replication:**
- Publishes changes to subscribers
- Near real-time synchronization
- Good for reporting, load distribution

**Merge Replication:**
- Bidirectional synchronization
- Allows offline changes
- Conflicts resolved at merge

**Snapshot Replication:**
- Full copy at schedule
- Simple setup
- Good for non-continuous sync

### Replication Components
- **Publisher:** Source database with publication
- **Subscriber:** Receives replicated data
- **Distributor:** Stores replication metadata
- **Distribution Agent:** Delivers changes

---

## Common Tasks

### Setup Transactional Replication
```sql
-- Step 1: Enable Publishing at Publisher
EXEC sp_replicationdboption 
    @dbname = 'YourDatabase',
    @optname = 'publish',
    @value = 'true';

-- Step 2: Create Publication
EXEC sp_addpublication
    @publication = 'YourPublication',
    @restricted = 'false',
    @repl_freq = 'continuous';

-- Step 3: Add Articles (tables)
EXEC sp_addarticle
    @publication = 'YourPublication',
    @article = 'YourTable',
    @source_owner = 'dbo',
    @source_object = 'YourTable';

-- Step 4: Create Snapshot Agent Job
EXEC sp_addpublication_snapshot
    @publication = 'YourPublication',
    @frequency_type = 1;  -- Once
```

### Add Subscriber
```sql
-- Step 1: Enable Subscription at Subscriber
EXEC sp_replicationdboption 
    @dbname = 'SubscriberDB',
    @optname = 'subscribe',
    @value = 'true';

-- Step 2: Add Subscription
EXEC sp_addsubscription
    @publication = 'YourPublication',
    @subscriber = 'SUBSCRIBER_SERVER',
    @destination_db = 'SubscriberDB',
    @subscription_type = 'push',
    @status = 'subscribed';

-- Step 3: Add Distribution Agent Job
EXEC sp_addpushsubscription_agent
    @publication = 'YourPublication',
    @subscriber = 'SUBSCRIBER_SERVER',
    @subscriber_db = 'SubscriberDB',
    @subscriber_security_mode = 1;
```

### Monitor Replication
```sql
-- Check replication status
SELECT 
    pub.name AS Publication,
    sub.name AS Subscriber,
    sub.status,
    sub.subscription_type
FROM sys.publications pub
JOIN sys.subscriptions sub ON pub.publication_id = sub.publication_id;

-- Check replication lag
SELECT 
    ds.name AS DistributionAgent,
    mda.time_lag_sec,
    mda.latest_delivered_time
FROM sys.dm_replication_monitor_subscription_agent mda
JOIN msdb.dbo.MSdistribution_agents ds ON mda.agent_id = ds.id;
```

### Test Replication
```sql
-- Insert test data
INSERT INTO dbo.YourTable (Column1, Column2) 
VALUES ('Test', GETDATE());

-- Verify at subscriber (wait a few seconds)
SELECT * FROM dbo.YourTable WHERE Column1 = 'Test';
```

### Reinitialize Subscription
```sql
-- Resync subscription (reinitialize)
EXEC sp_reinitsubscription
    @publication = 'YourPublication',
    @subscriber = 'SUBSCRIBER_SERVER',
    @subscriber_db = 'SubscriberDB';
```

### Check Replication Agents
```sql
-- View all replication agents
SELECT 
    id,
    name,
    publication_db,
    status,
    last_run_time
FROM msdb.dbo.MSdistribution_agents
ORDER BY last_run_time DESC;

-- Check agent job status
EXEC sp_help_replication_agent_job
    @agent_type = 'distribution';
```

---

## Always On Availability Groups (SQL Server 2012+)

### Enable Always On
```sql
-- Step 1: Enable Always On Feature (requires restart)
-- In SQL Server Configuration Manager:
-- SQL Server Services > SQL Server Instance > Always On High Availability
-- Set to "Enabled" and restart SQL Server

-- Step 2: Create Availability Group
CREATE AVAILABILITY GROUP [AG_YourGroup]
FOR DATABASE [YourDatabase]
REPLICA ON
    N'PRIMARY_SERVER' WITH (ENDPOINT_URL = N'TCP://PRIMARY_SERVER:5022'),
    N'SECONDARY_SERVER' WITH (ENDPOINT_URL = N'TCP://SECONDARY_SERVER:5022');

-- Step 3: Join Secondary Replica
ALTER AVAILABILITY GROUP [AG_YourGroup] JOIN;
```

### Monitor Availability Group
```sql
-- Check AG status
SELECT 
    ag.name,
    ar.replica_server_name,
    ar.availability_mode_desc,
    ars.synchronization_state_desc
FROM sys.availability_groups ag
JOIN sys.availability_replicas ar ON ag.group_id = ar.group_id
JOIN sys.dm_hadr_availability_replica_states ars ON ar.replica_id = ars.replica_id;

-- Check database sync status
SELECT 
    db.name AS DatabaseName,
    drs.synchronization_state_desc
FROM sys.availability_databases_cluster dac
JOIN sys.dm_hadr_database_replica_states drs ON dac.group_id = drs.group_id
JOIN sys.databases db ON dac.database_id = db.database_id;
```

---

## Best Practices

### Replication
- ✅ Use transactional replication for most scenarios
- ✅ Test replication thoroughly before production
- ✅ Monitor replication lag continuously
- ✅ Have documented failover procedures
- ✅ Test failover regularly (quarterly minimum)
- ❌ Don't replicate temporary tables
- ❌ Don't modify replicated data at subscriber
- ❌ Don't ignore replication errors

### Failover
- ✅ Maintain warm standby (synchronized)
- ✅ Use automatic failover when possible
- ✅ Test failover in non-production first
- ✅ Document application connection strings
- ✅ Plan for application-level failover
- ❌ Don't lose data during failover

### Monitoring
- ✅ Monitor replication lag (target: <5 seconds)
- ✅ Alert on replication failures
- ✅ Check agent job status daily
- ✅ Monitor subscriber performance
- ✅ Track data divergence

---

## Troubleshooting

### Replication Lag High
```sql
-- Check distribution agent
EXEC sp_help_replication_agent_job
    @agent_type = 'distribution';

-- Check queue
SELECT COUNT(*) AS PendingCommands
FROM msdb.dbo.MSrepl_commands;

-- Restart agent if needed
EXEC msdb.dbo.sp_start_job @job_name = N'distribution_agent_job';
```

### Replication Error
```sql
-- Check recent errors
SELECT TOP 20
    agent_id,
    time,
    error_id,
    error_text
FROM msdb.dbo.MSrepl_errors
ORDER BY time DESC;
```

### Subscriber Out of Sync
```sql
-- Reinitialize (drops and recreates)
EXEC sp_reinitsubscription
    @publication = 'YourPublication',
    @subscriber = 'SUBSCRIBER_SERVER',
    @subscriber_db = 'SubscriberDB';
```

---

## Related Files

- **Administration:** `../administration/`
- **Backup & Recovery:** `../backup-recovery/`
- **Performance:** `../performance/`
- **Monitoring:** `../monitoring/`
- **Troubleshooting:** `../troubleshooting/`

---

**Last Updated:** 2026-07-13  
**Versions:** SQL Server 2012+  
**Status:** Production-Ready