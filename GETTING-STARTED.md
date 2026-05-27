# Getting Started Guide

Welcome to the Multi-Cloud Database Scripts Repository! This comprehensive guide will help you get up and running quickly.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [First Steps](#first-steps)
5. [Cloud Provider Setup](#cloud-provider-setup)
6. [Running Your First Script](#running-your-first-script)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements
- **Operating System**: Windows, macOS, or Linux
- **Disk Space**: At least 500 MB free
- **Internet Connection**: Required for cloud operations

### Required Software

| Software | Version | Install Link |
|----------|---------|--------------|
| **Git** | 2.30+ | [git-scm.com](https://git-scm.com) |
| **PowerShell** | 7.0+ | [PowerShell Docs](https://docs.microsoft.com/en-us/powershell/) |
| **Node.js** | 14+ | [nodejs.org](https://nodejs.org) |
| **Bash** | 4.0+ | Pre-installed on Linux/macOS |

### Cloud CLIs

```bash
# AWS CLI
aws --version

# Azure CLI  
az --version

# Google Cloud SDK
gcloud --version
```

---

## Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts.git
cd multi-cloud-db-scripts-Automation-Scripts
```

### Step 2: Verify Installation

```bash
ls -la          # View files
cat README.md   # Read main documentation
```

---

## Configuration

### Step 1: Create Environment File

```bash
cp .env.example .env
nano .env  # or: code .env (for VS Code)
```

### Step 2: Add Your Credentials

Edit `.env` with your configuration:

```env
# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret

# Azure
AZURE_SUBSCRIPTION_ID=your_id
AZURE_TENANT_ID=your_tenant

# GCP
GCP_PROJECT_ID=your_project

# Database
DB_HOST=your_host
DB_USER=your_user
DB_PASSWORD=your_password
```

### Step 3: Secure Your Credentials

```bash
# Protect .env file (Linux/macOS)
chmod 600 .env

# Verify it's in .gitignore
grep ".env" .gitignore
```

---

## First Steps

### 1. Explore Repository

```bash
# View structure
tree -d -L 2

# Read documentation
cat README.md       # Main guide
cat SECURITY.md     # Security best practices
cat CONTRIBUTING.md # How to contribute
```

### 2. Choose Your Cloud Provider

```bash
cd AWS
cat README.md

# or
cd Azure
cat README.md

# or
cd GCP
cat README.md
```

---

## Cloud Provider Setup

### AWS Setup

```bash
# Install AWS CLI
aws --version

# Configure
aws configure

# Verify
aws sts get-caller-identity
```

### Azure Setup

```bash
# Install Azure CLI
az --version

# Login
az login

# Verify
az account show
```

### GCP Setup

```bash
# Install Cloud SDK
gcloud --version

# Initialize
gcloud init

# Verify
gcloud config list
```

---

## Running Your First Script

### T-SQL (SQL Server)

```bash
sqlcmd -S server_name -d database_name -i script.sql
```

### PowerShell (Azure)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\Azure\powershell\backup-sqldb.ps1
```

### Bash (AWS/GCP)

```bash
chmod +x AWS/RDS/backup-rds.sh
./AWS/RDS/backup-rds.sh
```

### JavaScript (Node.js)

```bash
npm install
node Azure/javascript/sql-admin.js
```

---

## Troubleshooting

### Git Clone Issues

```bash
# Check internet
ping github.com

# Use HTTPS if SSH fails
git clone https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts.git
```

### Permission Denied (Scripts)

```bash
# Make executable
chmod +x script.sh

# Run
./script.sh
```

### PowerShell Issues

```powershell
# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run
.\script.ps1
```

### Cloud CLI Not Found

```bash
# Reinstall
pip install awscli-v2      # AWS
pip install azure-cli      # Azure
# For GCP: Download from cloud.google.com/sdk
```

---

## Next Steps

1. ✅ Read cloud provider README files
2. ✅ Review security guidelines
3. ✅ Test scripts in non-production
4. ✅ Customize for your environment
5. ✅ Set up automation/scheduling

---

## Tips for Success

- ✅ Always test in non-production first
- ✅ Review scripts before execution
- ✅ Maintain backups before running
- ✅ Monitor execution and logs
- ✅ Document all changes
- ✅ Use version control
- ✅ Follow security best practices

---

## Support

- 📖 [README.md](README.md) - Main documentation
- 🔒 [SECURITY.md](SECURITY.md) - Security guidelines
- 🤝 [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute
- 📚 [Cloud Documentation](#cloud-provider-setup) - Setup guides
- 🐛 [GitHub Issues](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts/issues)

---

<div align="center">

**🎉 You're all set!**

Start with your cloud provider's README!

</div>