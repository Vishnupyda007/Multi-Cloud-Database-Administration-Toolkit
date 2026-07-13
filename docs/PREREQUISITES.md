# Prerequisites & Setup Requirements

This document outlines all prerequisites needed before using scripts in this toolkit.

---

## General Requirements

### 1. Git & Version Control
```bash
# Verify Git is installed
git --version
# Expected: git version 2.30+
```

### 2. Text Editor / IDE
- **SQL Scripts:** SQL Server Management Studio, DBeaver, VS Code with SQL extensions
- **PowerShell:** Visual Studio Code, PowerShell ISE, JetBrains Rider
- **Bash:** Any text editor (nano, vim, VS Code)
- **JavaScript:** VS Code, WebStorm

### 3. Command-Line Tools
```bash
# Verify bash/shell
bash --version

# Verify Python (optional)
python3 --version

# Verify Node.js (for JavaScript scripts)
node --version
```

---

## AWS Prerequisites

### 1. AWS CLI Installation
```bash
# macOS
brew install awscli

# Linux
sudo apt-get install awscli

# Windows
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Verify
aws --version
```

### 2. AWS Configuration
```bash
# Configure credentials
aws configure

# Enter:
# AWS Access Key ID: [your-access-key]
# AWS Secret Access Key: [your-secret-key]
# Default region: us-east-1
# Default output format: json

# Verify
aws sts get-caller-identity
```

### 3. Required AWS Permissions

**IAM Policy for RDS Management:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:*",
        "rds-db:connect"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::your-backup-bucket/*"
    }
  ]
}
```

### 4. Database Client
```bash
# For MySQL/PostgreSQL
# macOS
brew install mysql postgresql

# Linux
sudo apt-get install mysql-client postgresql-client
```

---

## Azure Prerequisites

### 1. Azure CLI Installation
```bash
# macOS
brew install azure-cli

# Linux
sudo apt-get install azure-cli

# Windows
choco install azure-cli

# Verify
az --version
```

### 2. Azure PowerShell Installation
```powershell
# Windows PowerShell or PowerShell 7+
Install-Module -Name Az -AllowClobber -Force

# Verify
Get-Module Az
```

### 3. Azure Authentication
```bash
# Login with CLI
az login

# Set default subscription
az account set --subscription "subscription-id"

# Verify
az account show
```

```powershell
# Login with PowerShell
Connect-AzAccount

# Set default subscription
Set-AzContext -SubscriptionId "subscription-id"
```

### 4. Required Azure Roles
- **SQL Database:** SQL DB Contributor
- **CosmosDB:** CosmosDB Account Contributor
- **Resource Groups:** Contributor
- **Key Vault:** Key Vault Administrator
- **Backups:** Backup Contributor

### 5. SQL Server Management Studio (Optional)
```bash
# Download from: https://aka.ms/ssmsfullsetup
```

---

## GCP Prerequisites

### 1. Google Cloud SDK Installation
```bash
# macOS
brew install google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash

# Windows
# Download from: https://cloud.google.com/sdk/docs/install-sdk

# Verify
gcloud --version
```

### 2. GCP Authentication
```bash
# Login
gcloud auth login

# Set default project
gcloud config set project PROJECT_ID

# Verify
gcloud config list
```

### 3. Enable Required APIs
```bash
# Cloud SQL API
gcloud services enable sqladmin.googleapis.com

# BigQuery API
gcloud services enable bigquery.googleapis.com

# Firestore API
gcloud services enable firestore.googleapis.com

# Cloud Storage API
gcloud services enable storage.googleapis.com

# Verify
gcloud services list --enabled
```

### 4. Required GCP Roles
- **Cloud SQL:** Cloud SQL Admin
- **BigQuery:** BigQuery Admin
- **Firestore:** Firestore Service Agent
- **Cloud Storage:** Storage Admin
- **Service Accounts:** Service Account User

### 5. Service Account (for automation)
```bash
# Create service account
gcloud iam service-accounts create db-admin \
  --display-name="Database Administration"

# Grant roles
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:db-admin@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudsql.admin"

# Create key
gcloud iam service-accounts keys create key.json \
  --iam-account=db-admin@PROJECT_ID.iam.gserviceaccount.com

# Export for use
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
```

---

## SQL Server (On-Premises) Prerequisites

### 1. SQL Server Version
- **Supported:** SQL Server 2016 SP2+
- **Recommended:** SQL Server 2019 or later

### 2. Client Tools
```powershell
# SQL Server Management Studio (SSMS)
# Download: https://aka.ms/ssmsfullsetup

# SQL Server Data Tools (SSDT)
# Download: https://aka.ms/ssdt-download

# Sqlcmd command-line utility
# Included with SQL Server or SSMS
```

### 3. PowerShell SqlServer Module
```powershell
Install-Module -Name SqlServer -Force
Import-Module SqlServer
```

### 4. Database Permissions
Minimum required:
- **Server Roles:** sysadmin or db_creator
- **Database Roles:** db_owner
- **Specific:** BACKUP DATABASE, RESTORE DATABASE

---

## PostgreSQL Prerequisites

### 1. PostgreSQL Client
```bash
# macOS
brew install postgresql

# Linux
sudo apt-get install postgresql-client

# Windows
# Download from: https://www.postgresql.org/download/windows/
```

### 2. psql Command-Line
```bash
# Verify installation
psql --version
# Expected: psql 12.0+
```

### 3. PgAdmin (Optional GUI)
```bash
# macOS
brew install pgadmin4

# Linux
sudo apt-get install pgadmin4

# Windows
# Download from: https://www.pgadmin.org/download/
```

### 4. PostgreSQL Permissions
- **Superuser** or **database owner** role
- **pg_database_owner** role for database management
- **CREATEDB** privilege
- **REPLICATION** privilege (for replication scripts)

---

## Environment Variables Setup

### Create `.env` File
```bash
# AWS
export AWS_REGION=us-east-1
export AWS_PROFILE=default
export RDS_INSTANCE_ID=my-database

# Azure
export AZURE_SUBSCRIPTION_ID=your-subscription-id
export AZURE_RESOURCE_GROUP=my-resource-group
export AZURE_SQL_SERVER=my-server.database.windows.net

# GCP
export GCP_PROJECT_ID=my-project
export CLOUDSQL_INSTANCE=my-instance
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json

# PostgreSQL
export PGHOST=localhost
export PGPORT=5432
export PGUSER=postgres
export PGDATABASE=postgres

# SQL Server
export SQL_SERVER=localhost
export SQL_DATABASE=master
```

### Load Environment Variables
```bash
# Add to ~/.bashrc or ~/.zshrc
source /path/to/.env

# Or load on demand
set -a
source .env
set +a
```

---

## Verify Setup

### AWS Verification
```bash
aws sts get-caller-identity          # Check identity
aws rds describe-db-instances        # List RDS instances
aws s3 ls                            # List S3 buckets
```

### Azure Verification
```bash
az account show                      # Show current account
az sql server list                   # List SQL servers
az cosmosdb list                     # List CosmosDB accounts
```

### GCP Verification
```bash
gcloud config list                  # Show configuration
gcloud sql instances list           # List Cloud SQL instances
gcloud projects list               # List projects
```

### PostgreSQL Verification
```bash
psql -U postgres -c "SELECT version();"  # Check version
```

### SQL Server Verification
```powershell
Invoke-Sqlcmd -Query "SELECT @@VERSION" -ServerInstance localhost
```

---

## Troubleshooting

### AWS CLI Issues
```bash
# Reset credentials
rm -rf ~/.aws
aws configure

# Check region
aws configure get region
```

### Azure CLI Issues
```bash
# Clear cache
rm -rf ~/.azure
az login

# Check subscription
az account show
```

### GCP SDK Issues
```bash
# Reinitialize
gcloud init

# Check authentication
gcloud auth list
```

---

## Next Steps

1. ✅ Install all required tools
2. ✅ Configure cloud credentials
3. ✅ Verify permissions
4. ✅ Test connectivity
5. 📖 Read platform-specific quickstart guides
6. 🚀 Run your first script

See `docs/QUICKSTART.md` for getting started.

---

**Last Updated:** 2026-07-13