# SQL Server Database Administration Scripts

Comprehensive collection of T-SQL and PowerShell scripts for Microsoft SQL Server (2016+) administration, both on-premises and in Azure environments.

---

## 📂 Directory Structure

```
MSSQLServer/
├── administration/              # User, role, and database management
├── backup-recovery/            # Backup and restore procedures
├── performance/                # Query optimization and tuning
├── monitoring/                 # Health checks and metrics
├── replication/                # Replication and HA setup
├── security/                   # Encryption and access control
├── troubleshooting/            # Common issues and solutions
├── jobs-ssis/                  # SQL Agent jobs and SSIS
└── README.md                   # (this file)
```

---

## 🎯 Quick Navigation

### Administration
User management, login creation, permissions, database setup

**Common Scripts:**
- User & login creation
- Role management
- Permission grants
- Database creation

**Files:** `administration/`

```sql
-- Create new login
CREATE LOGIN newuser WITH PASSWORD = 'SecurePass123!';

-- Create database user
CREATE USER newuser FOR LOGIN newuser;

-- Grant permissions
GRANT SELECT, INSERT ON table1 TO newuser;
```

---

### Backup & Recovery
Database backups, point-in-time recovery, restore procedures

**Common Tasks:**
- Full database backup
- Transaction log backup
- Restore from backup
- Point-in-time recovery

**Files:** `backup-recovery/`

**Key Scripts:**
- `full-backup.sql` - Create full database backup
- `transaction-log-backup.sql` - Backup transaction logs
- `restore-procedure.sql` - Restore database
- `backup-recovery-procedure.txt` - Step-by-step guide

---

### Performance
Query optimization, index management, statistics, execution plans

**Common Tasks:**
- Find slow queries
- Optimize indexes
- Update statistics
- Analyze execution plans

**Files:** `performance/`

**Key Scripts:**
- `slow-queries.sql` - Identify slow-running queries
- `index-optimization.sql` - Rebuild/reorganize indexes
- `statistics-update.sql` - Update query statistics
- `execution-plans.sql` - Analyze query plans
- `IndexOptimize.txt` - Comprehensive index maintenance

---

### Monitoring
Health checks, resource monitoring, performance metrics

**Common Tasks:**
- Server health checks
- CPU/memory/disk monitoring
- Active sessions tracking
- Error log analysis

**Files:** `monitoring/`

**Key Scripts:**
- `health-check.sql` - Overall server health
- `resource-utilization.sql` - CPU, memory, disk usage
- `active-sessions.sql` - Connected users
- `error-log.sql` - SQL Server errors
- `Daily Queries.txt` - Daily monitoring queries

---

### Replication
Transactional replication, failover setup, lag monitoring

**Common Tasks:**
- Setup replication
- Configure failover
- Monitor replication lag
- Troubleshoot replication

**Files:** `replication/`

**Key Scripts:**
- `setup-replication.sql` - Transactional replication config
- `monitor-replication.sql` - Replication status
- `failover-procedure.txt` - Failover steps
- `replication-troubleshooting.sql` - Diagnose issues

---

### Security
Encryption (TDE), SSL/TLS, auditing, compliance

**Common Tasks:**
- Enable TDE (Transparent Data Encryption)
- SSL/TLS configuration
- Audit logging
- Access control

**Files:** `security/`

**Key Scripts:**
- `enable-tde.sql` - Enable database encryption
- `ssl-configuration.txt` - Configure SSL/TLS
- `audit-setup.sql` - Enable audit logging
- `cloud-credentials.sql` - Azure backup credentials

---

### Troubleshooting
Common issues, diagnostics, solutions

**Common Problems:**
- Connection issues
- High CPU/memory
- Deadlocks
- Failed backups
- Slow performance
- Replication failures

**Files:** `troubleshooting/`

**Key Scripts:**
- `deadlock-detection.sql` - Find deadlock objects
- `connection-issues.sql` - Diagnose connection problems
- `orphan-user-fix.sql` - Fix orphaned users
- `blocking-queries.sql` - Find blocking sessions

---

### Jobs & SSIS
SQL Agent jobs, scheduled tasks, SSIS packages

**Common Tasks:**
- Create SQL Agent jobs
- Schedule backups
- SSIS package execution
- Job troubleshooting

**Files:** `jobs-ssis/`

---

## 📋 Prerequisites

- SQL Server 2016 SP2 or later
- SQL Server Management Studio (SSMS) or DBeaver
- `sqlcmd` command-line utility
- PowerShell 5.0+ (for PS scripts)
- Appropriate database permissions

---

## 🚀 Getting Started

### 1. Review Script
```bash
# Always read the script first
cat MSSQLServer/backup-recovery/full-backup.sql
```

### 2. Understand Prerequisites
```bash
# Check what's needed before running
head -20 script.sql  # Look for comments
```

### 3. Test in Development
```powershell
# Never run in production first!
sqlcmd -S localhost\SQLEXPRESS -d TestDB -i full-backup.sql
```

### 4. Review Results
```sql
-- Verify successful execution
SELECT * FROM msdb.dbo.backupset 
ORDER BY backup_start_date DESC;
```

### 5. Deploy to Production
```powershell
# After testing successfully
sqlcmd -S prod-server\SQLSERVER -d ProductionDB -i full-backup.sql
```

---

## 🔗 Common Workflows

### Daily Backup Setup
1. Navigate to `backup-recovery/`
2. Review `full-backup.sql`
3. Test on development database
4. Schedule with SQL Agent
5. Monitor backup jobs

### Performance Optimization
1. Navigate to `performance/`
2. Run `slow-queries.sql`
3. Review expensive queries
4. Run `index-optimization.sql`
5. Update statistics
6. Verify improvement

### Server Health Check
1. Navigate to `monitoring/`
2. Run `health-check.sql`
3. Review results
4. Set up alerts
5. Monitor metrics

### Disaster Recovery Test
1. Navigate to `backup-recovery/`
2. Create backup on production
3. Restore to test environment
4. Verify data integrity
5. Document time taken
6. Plan for production failover

---

## 📊 Script Statistics

| Category | Count | Complexity | Status |
|----------|-------|-----------|--------|
| Administration | 15 | Simple-Medium | Active |
| Backup/Recovery | 20 | Simple-Advanced | Active |
| Performance | 25 | Medium-Advanced | Active |
| Monitoring | 20 | Simple-Medium | Active |
| Replication | 15 | Advanced | Active |
| Security | 10 | Medium-Advanced | Active |
| Troubleshooting | 25 | Medium-Advanced | Active |
| Jobs/SSIS | 10 | Medium-Advanced | Active |
| **Total** | **140** | - | - |

---

## ⚠️ Important Notes

### Before Running Any Script
- ✅ Read the entire script first
- ✅ Understand what it does
- ✅ Test in non-production environment
- ✅ Verify you have required permissions
- ✅ Create database backup
- ✅ Review potential impact
- ✅ Have rollback plan

### Security
- ❌ Never hardcode passwords
- ❌ Don't commit credentials to git
- ❌ Use secure connection (SSL/TLS)
- ✅ Use environment variables
- ✅ Use managed identities (Azure)
- ✅ Enable audit logging
- ✅ Rotate passwords regularly

### Performance
- ⚠️ Run during maintenance windows
- ⚠️ Monitor resource usage
- ⚠️ Test on production-like data
- ⚠️ Have monitoring in place
- ⚠️ Set timeouts appropriately

---

## 🔍 Troubleshooting

### Script fails to execute
```powershell
# Check SQL Server version
SELECT @@VERSION;

# Check compatibility level
SELECT compatibility_level FROM sys.databases WHERE name = 'YourDB';

# Try with explicit compatibility
ALTER DATABASE YourDB SET COMPATIBILITY_LEVEL = 130;
```

### Permission denied
```sql
-- Check current permissions
SELECT * FROM fn_my_permissions(NULL, 'SERVER');

-- Check database permissions
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');

-- Get required role
ALTER SERVER ROLE sysadmin ADD MEMBER [DOMAIN\YourUser];
```

### Backup fails
```sql
-- Check backup locations
EXEC sp_helpfile;

-- Check available disk space
EXEC xp_fixeddrives;

-- Review backup history
SELECT * FROM msdb.dbo.backupset 
WHERE backup_finish_date > DATEADD(DAY, -1, GETDATE())
ORDER BY backup_start_date DESC;
```

---

## 📚 Learning Resources

- **Getting Started:** `docs/quickstart-mssqlserver.md`
- **Best Practices:** `docs/ARCHITECTURE.md`
- **Prerequisites:** `docs/PREREQUISITES.md`
- **Script Index:** `docs/SCRIPT_CATALOG.md`
- **Troubleshooting:** `docs/TROUBLESHOOTING.md`

---

## 🤝 Contributing

Want to add new scripts? See [CONTRIBUTING.md](../CONTRIBUTING.md)

**When adding scripts:**
1. Follow naming conventions
2. Include comprehensive header comments
3. Add to appropriate category folder
4. Create/update category README
5. Update scripts.json
6. Test thoroughly
7. Submit pull request

---

## 📞 Support

- 📖 Read the README in each category folder
- 🔍 Search [SCRIPT_CATALOG.md](../docs/SCRIPT_CATALOG.md)
- 🐛 Report issues on GitHub
- 💬 Start discussion on GitHub
- 📧 Check repository for contact info

---

**Last Updated:** 2026-07-13  
**Total Scripts:** 140+  
**Supported Versions:** SQL Server 2016 SP2+  
**Status:** Active & Maintained