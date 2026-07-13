# Quick Start Guide

## Welcome to the Multi-Cloud Database Administration Toolkit!

This guide will get you up and running in **5 minutes**.

---

## Choose Your Platform

### ☁️ Using AWS?
👉 [Go to AWS Quick Start](./quickstart-aws-rds.md)

### ☁️ Using Azure?
👉 [Go to Azure Quick Start](./quickstart-azure-sql.md)

### ☁️ Using GCP?
👉 [Go to GCP Quick Start](./quickstart-gcp-cloudsql.md)

### 🖥️ Using SQL Server (On-Premises)?
👉 [Go to SQL Server Quick Start](./quickstart-mssqlserver.md)

### 🐘 Using PostgreSQL (On-Premises)?
👉 [Go to PostgreSQL Quick Start](./quickstart-postgresql.md)

---

## Before You Start

### ✅ Prerequisites

1. **Cloud CLI installed** (AWS CLI, Azure CLI, or gcloud)
2. **Cloud credentials configured**
3. **Appropriate permissions** for your platform
4. **Database client** (sqlcmd, psql, mysql, etc.)
5. **Text editor or IDE** for viewing scripts

See [PREREQUISITES.md](./PREREQUISITES.md) for detailed setup.

---

## General Workflow

### Step 1: Identify Your Need

**What do you want to do?**
- 📦 Backup databases → [Backup & Recovery](#backup--recovery-scripts)
- ⚡ Optimize performance → [Performance Tuning](#performance-tuning-scripts)
- 👁️ Monitor databases → [Monitoring](#monitoring-scripts)
- 👤 Manage users/roles → [Administration](#administration-scripts)
- 🔄 Setup replication → [Replication](#replication-scripts)
- 🔒 Secure databases → [Security](#security-scripts)
- 🐛 Fix problems → [Troubleshooting](#troubleshooting-scripts)

### Step 2: Review Documentation

Read the category's `README.md` file:
```bash
cd AWS/RDS/backup-management/
cat README.md
```

### Step 3: Review the Script

```bash
# Always read before running
cat backup-rds-database.sh

# Check for:
# - Purpose & requirements
# - Parameters/variables
# - Impact on database
# - Recovery procedures
```

### Step 4: Test in Non-Production

```bash
# Use a test/dev database FIRST
./backup-rds-database.sh --instance-id dev-db
```

### Step 5: Verify Results

```bash
# Confirm successful execution
echo $?
# Expected output: 0 (success)
```

### Step 6: Run in Production

```bash
# After successful testing
./backup-rds-database.sh --instance-id prod-db
```

---

## Common Tasks

### Backup & Recovery Scripts

**I want to...**

**Backup my database:**
```bash
# AWS
cd AWS/RDS/backup-management/
bash create-automated-backup.sh --instance-id mydb

# Azure
cd Azure/SQL-Database/backup-recovery/
PowerShell backup-sqldb.ps1 -ServerName myserver -DatabaseName mydb

# GCP
cd GCP/Cloud-SQL/backup-recovery/
bash create-backup.sh --instance myinstance
```

**Restore my database:**
```bash
# AWS
bash restore-from-backup.sh --instance-id mydb --backup-id backup123

# Azure
PowerShell restore-sqldb.ps1 -DatabaseName mydb-restored

# GCP
bash restore-from-backup.sh --instance myinstance --backup-id backup123
```

**Test recovery procedure:**
```bash
# Read the procedure first
cat docs/disaster-recovery-procedures.md

# Run in test environment
./restore-from-backup.sh --instance test-db
```

---

### Performance Tuning Scripts

**I want to...**

**Find slow queries:**
```bash
# SQL Server
cd MSSQLServer/Performance Related Scripts/
sqlcmd -S localhost -d master -i slow-queries.sql

# PostgreSQL
cd PostgreSQL/Performance Related/
psql -U postgres -f slow-queries.sql
```

**Optimize indexes:**
```bash
# SQL Server
sqlcmd -S localhost -i index-optimization.sql

# PostgreSQL
psql -U postgres -f index-optimization.sql
```

**Analyze query performance:**
```bash
# See query execution plan
# SQL Server: Use INCLUDE (ACTUAL PLAN) in query
# PostgreSQL: Prefix with EXPLAIN ANALYZE
EXPLAIN ANALYZE SELECT * FROM large_table;
```

---

### Monitoring Scripts

**I want to...**

**Setup monitoring dashboard:**
```bash
# AWS
cd AWS/RDS/monitoring/
bash create-cloudwatch-dashboard.sh --instance mydb

# Azure
cd Azure/SQL-Database/monitoring/
PowerShell create-alerts.ps1 -ServerName myserver

# GCP
cd GCP/Cloud-SQL/monitoring/
bash create-monitoring.sh --instance myinstance
```

**Check database health:**
```bash
# SQL Server
sqlcmd -S localhost -i health-check.sql

# PostgreSQL
psql -U postgres -f health-check.sql
```

**View resource usage:**
```bash
# AWS
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --start-time 2026-07-10T00:00:00Z \
  --end-time 2026-07-13T00:00:00Z \
  --period 3600 \
  --statistics Maximum,Average
```

---

### Administration Scripts

**I want to...**

**Create a new user:**
```bash
# SQL Server
sqlcmd -S localhost -Q "CREATE LOGIN newuser WITH PASSWORD = 'SecurePass123!'"

# PostgreSQL
psql -U postgres -c "CREATE ROLE newuser WITH LOGIN PASSWORD 'SecurePass123';"

# Azure
az sql db update --server myserver --name mydb --add-user-id newuser
```

**Grant permissions:**
```bash
# SQL Server
sqlcmd -S localhost -Q "GRANT SELECT, INSERT ON table1 TO newuser"

# PostgreSQL
psql -U postgres -c "GRANT SELECT, INSERT ON table1 TO newuser;"
```

**Create a new database:**
```bash
# SQL Server
sqlcmd -S localhost -Q "CREATE DATABASE newdb"

# PostgreSQL
psql -U postgres -c "CREATE DATABASE newdb;"

# AWS
aws rds create-db-instance \
  --db-instance-identifier mydb \
  --db-instance-class db.t3.micro \
  --engine mysql
```

---

## Platform-Specific Quick Starts

### AWS RDS (5-minute quickstart)

```bash
# 1. Install AWS CLI
brew install awscli

# 2. Configure credentials
aws configure

# 3. List your RDS instances
aws rds describe-db-instances

# 4. Create a backup
aws rds create-db-snapshot \
  --db-instance-identifier mydb \
  --db-snapshot-identifier mydb-backup-$(date +%Y%m%d)

# 5. Verify backup
aws rds describe-db-snapshots --db-snapshot-identifier mydb-backup-20260713
```

### Azure SQL (5-minute quickstart)

```powershell
# 1. Install Azure CLI
choco install azure-cli

# 2. Login
az login

# 3. List SQL servers
az sql server list

# 4. Create a backup
az sql db copy \
  --resource-group myresourcegroup \
  --server myserver \
  --name mydb \
  --dest-name mydb-backup-20260713

# 5. Verify backup
az sql db show --server myserver --name mydb-backup-20260713
```

### GCP Cloud SQL (5-minute quickstart)

```bash
# 1. Install gcloud SDK
brew install google-cloud-sdk

# 2. Initialize
gcloud init

# 3. List Cloud SQL instances
gcloud sql instances list

# 4. Create a backup
gcloud sql backups create \
  --instance=myinstance

# 5. List backups
gcloud sql backups list --instance=myinstance
```

---

## Troubleshooting

### Script won't execute

```bash
# Fix permissions
chmod +x script.sh

# Run with bash explicitly
bash script.sh

# Check shell compatibility
head -1 script.sh  # Should be #!/bin/bash
```

### Permission denied error

```bash
# Check your cloud permissions
aws sts get-caller-identity
az account show
gcloud config list

# Verify database credentials
aws rds modify-db-instance --db-instance-identifier mydb --master-user-password NewPassword123!
```

### Connection timeout

```bash
# Test connectivity
# AWS
telnet mydb.xxxxx.us-east-1.rds.amazonaws.com 3306

# Azure
telnet myserver.database.windows.net 1433

# GCP
gcloud sql connect myinstance --user=root
```

### Script failed

```bash
# Check error messages
# Enable debug mode
bash -x script.sh

# Review documentation
cat README.md

# Check logs
cat error.log
```

---

## Next Steps

1. ✅ Read your platform's quick start guide
2. ✅ Install required tools (AWS CLI, Azure CLI, etc.)
3. ✅ Configure credentials
4. ✅ Find your first task
5. ✅ Review the script
6. ✅ Test in non-production
7. ✅ Deploy to production

---

## Getting Help

- 📖 **Documentation:** Read [ARCHITECTURE.md](./ARCHITECTURE.md) for overview
- 🔍 **Search:** Use [SCRIPT_CATALOG.md](./SCRIPT_CATALOG.md) to find scripts
- ❓ **Questions:** Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- 🐛 **Issues:** Open a GitHub issue
- 💬 **Discussion:** Start a GitHub discussion
- 🤝 **Contributing:** See [CONTRIBUTING.md](../CONTRIBUTING.md)

---

**Ready to get started?**  
Choose your platform at the top of this guide →