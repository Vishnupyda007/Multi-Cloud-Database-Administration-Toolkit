# AWS RDS Quick Start (5 Minutes)

## What You'll Do

✅ Install AWS CLI  
✅ Configure credentials  
✅ Create your first backup  
✅ Verify the backup  

---

## Step 1: Install AWS CLI (2 min)

### macOS
```bash
brew install awscli
aws --version
```

### Linux
```bash
sudo apt-get update
sudo apt-get install awscli
aws --version
```

### Windows
```powershell
# Using Chocolatey
choco install awscli

# Or download MSI
# https://awscli.amazonaws.com/AWSCLIV2.msi
```

---

## Step 2: Configure Credentials (1 min)

```bash
aws configure

# Enter when prompted:
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region: us-east-1
# Default output format: json
```

**Verify configuration:**
```bash
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDAI...",
    "Account": "123456789",
    "Arn": "arn:aws:iam::123456789:user/your-username"
}
```

---

## Step 3: List Your RDS Instances (1 min)

```bash
aws rds describe-db-instances --query 'DBInstances[].DBInstanceIdentifier' --output text
```

Expected output:
```
mydb-prod    mydb-dev     mydb-staging
```

---

## Step 4: Create Your First Backup (1 min)

```bash
# Set your database name
DB_INSTANCE=mydb-prod
BACKUP_ID="$DB_INSTANCE-backup-$(date +%Y%m%d-%H%M%S)"

# Create snapshot
aws rds create-db-snapshot \
  --db-instance-identifier $DB_INSTANCE \
  --db-snapshot-identifier $BACKUP_ID

echo "Backup created: $BACKUP_ID"
```

---

## Step 5: Verify Backup (1 min)

```bash
# Check backup status
aws rds describe-db-snapshots \
  --db-snapshot-identifier $BACKUP_ID \
  --query 'DBSnapshots[0].[DBSnapshotIdentifier,Status,SnapshotCreateTime]' \
  --output table
```

Expected output:
```
|------|--------|------------------|
| mydb-prod-backup-20260713-... | creating | 2026-07-13 ... |
```

Wait for status to change to **available** (typically 2-5 minutes).

---

## Next Steps

### 🎯 Common Tasks

**Automate daily backups:**
```bash
cd AWS/RDS/backup-management/
cat README.md
bash create-automated-backup.sh --instance-id $DB_INSTANCE
```

**Monitor database health:**
```bash
cd AWS/RDS/monitoring/
bash create-cloudwatch-dashboard.sh --instance $DB_INSTANCE
```

**Optimize performance:**
```bash
cd AWS/RDS/performance-tuning/
cat README.md  # Review available optimizations
```

**Troubleshoot issues:**
```bash
cd AWS/RDS/troubleshooting/
cat README.md  # Find solution for your issue
```

---

## Useful AWS CLI Commands

### List all databases
```bash
aws rds describe-db-instances --output table
```

### Get database details
```bash
aws rds describe-db-instances \
  --db-instance-identifier $DB_INSTANCE \
  --output table
```

### View backup history
```bash
aws rds describe-db-snapshots \
  --db-instance-identifier $DB_INSTANCE \
  --output table
```

### Restore from backup
```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier $DB_INSTANCE-restored \
  --db-snapshot-identifier $BACKUP_ID
```

### Check RDS events
```bash
aws rds describe-events \
  --source-identifier $DB_INSTANCE \
  --source-type db-instance
```

### Get CloudWatch metrics
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=$DB_INSTANCE \
  --start-time 2026-07-10T00:00:00Z \
  --end-time 2026-07-13T00:00:00Z \
  --period 3600 \
  --statistics Average,Maximum
```

---

## Troubleshooting

### AWS CLI command not found
```bash
# Reinstall
brew uninstall awscli
brew install awscli

# Verify path
which aws
```

### Access denied error
```bash
# Check credentials
aws sts get-caller-identity

# Reconfigure
aws configure

# Or use IAM role (on EC2)
aws sts assume-role --role-arn arn:aws:iam::123456789:role/RDSAdminRole --role-session-name rds-session
```

### Snapshot creation fails
```bash
# Check RDS instance status
aws rds describe-db-instances \
  --db-instance-identifier $DB_INSTANCE \
  --query 'DBInstances[0].DBInstanceStatus'

# Instance must be available
# Check for maintenance windows or ongoing operations
```

---

## What You Learned

✅ Installed and configured AWS CLI  
✅ Listed your RDS instances  
✅ Created your first database backup  
✅ Verified backup status  
✅ Explored useful CLI commands  

---

## Ready for More?

📖 **Next:** Explore [AWS/RDS/backup-management/](../../AWS/RDS/backup-management/)  
📖 **Guide:** Read [ARCHITECTURE.md](./ARCHITECTURE.md)  
📖 **Search:** Use [SCRIPT_CATALOG.md](./SCRIPT_CATALOG.md)  
📖 **Help:** Check [PREREQUISITES.md](./PREREQUISITES.md)

---

**Last Updated:** 2026-07-13