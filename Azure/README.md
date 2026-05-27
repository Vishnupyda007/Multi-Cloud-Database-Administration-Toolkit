# Azure Database Scripts

Comprehensive database administration scripts for Microsoft Azure.

## 📋 Table of Contents

- [Overview](#overview)
- [Azure SQL Database Scripts](#azure-sql-database-scripts)
- [Azure CosmosDB Scripts](#azure-cosmosdb-scripts)
- [Azure PowerShell Automation](#azure-powershell-automation)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Best Practices](#best-practices)

---

## Overview

This folder contains scripts for managing various Azure database services:

| Service | Type | Scripts |
|---------|------|---------|
| **Azure SQL Database** | RDBMS | Backup, Restore, Management |
| **Azure SQL Managed Instance** | RDBMS | Instance management, Configuration |
| **Azure Database for PostgreSQL** | RDBMS | Backup, Monitoring, Maintenance |
| **Azure CosmosDB** | NoSQL | Document, Graph, Key-Value databases |

---

## Azure SQL Database Scripts

### Directory Structure
```
SQL-Database/
├── backup-sqldb.ps1           # Automated backup
├── restore-sqldb.ps1          # Restore procedure
├── maintenance.ps1            # Maintenance tasks
├── monitoring.sql             # Performance queries
└── README.md                  # Documentation
```

### Usage

```powershell
# Create automated backup
.\backup-sqldb.ps1 -ServerName "myserver" -DatabaseName "mydb" `
  -ResourceGroupName "myresourcegroup"

# Restore database
.\restore-sqldb.ps1 -ServerName "myserver" -DatabaseName "mydb-restored" `
  -SourceDatabaseName "mydb"

# Run maintenance
.\maintenance.ps1 -ServerName "myserver" -DatabaseName "mydb"
```

---

## Azure CosmosDB Scripts

### Directory Structure
```
CosmosDB/
├── backup-cosmos.ps1          # CosmosDB backup
├── restore-cosmos.ps1         # CosmosDB restore
├── export-cosmos.ps1          # Export data
├── management.js              # Node.js management
└── README.md                  # Documentation
```

### Usage

```powershell
# Create backup
.\backup-cosmos.ps1 -AccountName "myaccount" -ResourceGroupName "myresourcegroup"

# Restore from backup
.\restore-cosmos.ps1 -AccountName "myaccount-restored"

# Export data
.\export-cosmos.ps1 -AccountName "myaccount" -ContainerName "mycontainer"
```

---

## Azure PowerShell Automation

### Directory Structure
```
PowerShell/
├── backup-rds.ps1            # AWS RDS backup (for Azure users)
├── manage-sql-database.ps1   # SQL Database management
├── setup-replication.ps1     # Geo-replication setup
└── README.md                 # Documentation
```

### Usage

```powershell
# Manage SQL Database
.\manage-sql-database.ps1 -Action "CreateDatabase" `
  -ServerName "myserver" -DatabaseName "newdb"

# Setup geo-replication
.\setup-replication.ps1 -ServerName "myserver" -DatabaseName "mydb" `
  -ReplicaRegion "westus"
```

---

## ARM Templates & Bicep

### Directory Structure
```
ARM-Templates/
├── sql-database.json          # SQL Database template
├── cosmos-template.bicep      # CosmosDB Bicep template
└── README.md                  # Template documentation
```

### Usage

```powershell
# Deploy with PowerShell
New-AzResourceGroupDeployment -ResourceGroupName "myresourcegroup" `
  -TemplateFile "./sql-database.json" `
  -TemplateParameterFile "./parameters.json"

# Deploy Bicep template
az deployment group create --resource-group myresourcegroup `
  --template-file cosmos-template.bicep
```

---

## Prerequisites

### Azure Setup

```powershell
# Install Azure CLI
az --version

# Or install Azure PowerShell
Install-Module -Name Az -AllowClobber

# Login to Azure
az login
# or
Connect-AzAccount
```

### Required Permissions

Your Azure user needs these roles:

- **SQL Database**: SQL DB Contributor
- **CosmosDB**: CosmosDB Account Contributor
- **Resource Groups**: Contributor
- **Backups**: Backup Contributor

### Tools Required

- Azure CLI 2.0+
- Azure PowerShell Module
- PowerShell 7.0+
- Node.js 14+ (for JavaScript scripts)
- sqlcmd (for T-SQL scripts)

---

## Quick Start

### 1. Configure Azure CLI

```bash
# Login
az login

# Set default subscription
az account set --subscription "SUBSCRIPTION_ID"

# Verify
az account show
```

### 2. Configure Azure PowerShell

```powershell
# Connect to Azure
Connect-AzAccount

# View subscriptions
Get-AzSubscription

# Set default subscription
Set-AzContext -SubscriptionId "SUBSCRIPTION_ID"
```

### 3. Run Your First Script

```powershell
# Example: Create a backup
.\SQL-Database\backup-sqldb.ps1 `
  -ServerName "myserver" `
  -DatabaseName "mydatabase" `
  -ResourceGroupName "myresourcegroup"
```

---

## Best Practices

### Security

- ✅ Use Azure Managed Identities instead of credentials
- ✅ Enable Azure AD authentication
- ✅ Use Azure Key Vault for secrets
- ✅ Enable Transparent Data Encryption (TDE)
- ✅ Configure firewall rules
- ✅ Enable audit logging
- ✅ Use Virtual Network service endpoints

### Performance

- ✅ Choose appropriate service tier
- ✅ Use Read Replicas for scaling
- ✅ Enable Query Performance Insight
- ✅ Monitor DTU/vCore usage
- ✅ Optimize queries and indexes
- ✅ Use connection pooling

### Cost Optimization

- ✅ Use Reserved Capacity (RI) for predictable workloads
- ✅ Enable auto-pause for serverless databases
- ✅ Monitor unused resources
- ✅ Use Hybrid Benefit if you have SQL Server licenses
- ✅ Optimize backup retention
- ✅ Right-size your tier

### Disaster Recovery

- ✅ Enable automated backups
- ✅ Use geo-replication for critical databases
- ✅ Test failover procedures
- ✅ Create disaster recovery runbooks
- ✅ Monitor backup status
- ✅ Document RTO and RPO

---

## Troubleshooting

### Common Issues

**Issue: Azure CLI command not found**
```bash
# Solution: Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Issue: Access Denied**
```powershell
# Solution: Check role assignments
Get-AzRoleAssignment -SignInName youremail@example.com
```

**Issue: PowerShell execution policy**
```powershell
# Solution: Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Support

- 📖 [Azure SQL Database Documentation](https://docs.microsoft.com/en-us/azure/azure-sql/)
- 📖 [Azure CosmosDB Documentation](https://docs.microsoft.com/en-us/azure/cosmos-db/)
- 📖 [Azure PowerShell Reference](https://docs.microsoft.com/en-us/powershell/azure/)
- 💬 [Azure Support](https://azure.microsoft.com/en-us/support/)

---

**Last Updated:** 2026-05-27