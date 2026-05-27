# Multi-Cloud Database Scripts & Automation

Database administration scripts for **AWS**, **Azure**, and **GCP** including automation tools for managing SQL Server, PostgreSQL, and other cloud databases.

## 📚 Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Cloud-Specific Documentation](#cloud-specific-documentation)
- [Prerequisites](#prerequisites)
- [Security](#security)
- [Contributing](#contributing)
- [License](#license)

## Overview

This repository contains database administration and automation scripts for multi-cloud environments:

| Cloud Provider | Databases | Languages |
|---|---|---|
| **AWS** | RDS SQL Server, RDS PostgreSQL | T-SQL, PowerShell, JavaScript |
| **Azure** | SQL Database, Managed Instance, PostgreSQL | T-SQL, PowerShell, JavaScript |
| **GCP** | Cloud SQL | T-SQL, PowerShell, JavaScript |
| **On-Premises** | SQL Server, PostgreSQL | T-SQL, PowerShell |

## Repository Structure

```
├── AWS/                          # AWS cloud database scripts
│   ├── tsql/                     # T-SQL for RDS SQL Server
│   ├── powershell/               # AWS PowerShell automation
│   ├── javascript/               # Node.js AWS SDK scripts
│   └── README.md
│
├── Azure/                        # Azure database scripts
│   ├── tsql/                     # T-SQL for Azure SQL
│   ├── powershell/               # Azure PowerShell (Az module)
│   ├── javascript/               # Node.js Azure SDK scripts
│   └── README.md
│
├── GCP/                          # Google Cloud Platform scripts
│   ├── tsql/                     # T-SQL for Cloud SQL
│   ├── powershell/               # GCP PowerShell scripts
│   ├── javascript/               # Node.js GCP scripts
│   └── README.md
│
├── MSSQLServer/                  # On-premises SQL Server
│   ├── administration/           # Instance administration
│   ├── backup-recovery/          # Backup & restore procedures
│   ├── monitoring/               # Performance monitoring
│   ├── security/                 # Security & access control
│   ├── maintenance/              # Index & statistics maintenance
│   ├── concepts/                 # Reference documentation
│   └── README.md
│
├── PostgreSQL/                   # PostgreSQL administration
│   ├── administration/           # Database administration
│   ├── backup-recovery/          # Backup & restore
│   ├── monitoring/               # Performance monitoring
│   ├── maintenance/              # Maintenance tasks
│   └── README.md
│
├── .gitignore                    # Git ignore patterns
├── .env.example                  # Environment variables template
├── SECURITY.md                   # Security guidelines
└── CONTRIBUTING.md              # Contribution guidelines
```

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts.git
cd multi-cloud-db-scripts-Automation-Scripts
```

### 2. Setup Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit with your credentials
nano .env  # or use your preferred editor
```

### 3. Choose Your Cloud Provider

- **[AWS Documentation](./AWS/README.md)** - RDS SQL Server/PostgreSQL
- **[Azure Documentation](./Azure/README.md)** - Azure SQL Database/Managed Instance
- **[GCP Documentation](./GCP/README.md)** - Cloud SQL
- **[SQL Server Documentation](./MSSQLServer/README.md)** - On-premises
- **[PostgreSQL Documentation](./PostgreSQL/README.md)** - PostgreSQL Admin

## Cloud-Specific Documentation

Each cloud provider has specialized scripts organized by function:

### AWS Scripts
- Backup/restore for RDS
- Performance monitoring queries
- Security group management
- Automated failover procedures

### Azure Scripts
- Azure SQL Database management
- Managed Instance configuration
- Backup strategies
- Disaster recovery setup

### GCP Scripts
- Cloud SQL administration
- Instance management
- Backup procedures
- Replication setup

### SQL Server (On-Premises)
- Database maintenance
- Index optimization
- Query performance tuning
- High availability setup

### PostgreSQL
- Database administration
- Backup/recovery
- Monitoring & alerts
- Maintenance procedures

## Prerequisites

### Required Tools

- **SQL Server Management Studio (SSMS)** or similar SQL client
- **PowerShell 7.0+** for automation scripts
- **Node.js 14+** for JavaScript scripts
- **Git** for version control

### Cloud CLI Tools

```bash
# AWS CLI
aws --version

# Azure CLI
az --version

# Google Cloud SDK
gcloud --version
```

### Environment Setup

1. **Create `.env` file from template:**
   ```bash
   cp .env.example .env
   ```

2. **Add your credentials:**
   - Cloud provider credentials
   - Database connection strings
   - Backup paths
   - Logging preferences

3. **Validate configuration:**
   ```bash
   # Test connectivity (scripts include validation)
   ```

## Security

### Important Security Notes

⚠️ **Never commit:**
- Credentials or secrets
- Connection strings with passwords
- Private keys or certificates
- API keys or access tokens

✅ **Always:**
- Use `.env` files (never commit)
- Use environment variables for secrets
- Rotate credentials regularly
- Review scripts before executing
- Test in non-production first
- Use managed identities where possible

See [SECURITY.md](./SECURITY.md) for detailed security guidelines.

## Usage Examples

### Execute T-SQL Script

```bash
# SQL Server
sqlcmd -S server_name -d database_name -i script.sql

# Azure SQL
sqlcmd -S server_name.database.windows.net -d database_name -U user@server -i script.sql
```

### Run PowerShell Script

```bash
# Execute backup script
.\AWS\powershell\backup-rds.ps1

# Run Azure management
.\Azure\powershell\manage-sql-database.ps1
```

### Execute JavaScript Script

```bash
# Run Node.js automation
node AWS/javascript/rds-management.js

# Azure SDK example
node Azure/javascript/sql-admin.js
```

## File Types in Repository

| Extension | Purpose | Location |
|---|---|---|
| `.sql` | T-SQL scripts | All cloud folders |
| `.ps1` | PowerShell automation | All cloud folders |
| `.js` | JavaScript/Node.js | All cloud folders |
| `.md` | Documentation | Root & subdirectories |
| `.txt` | Reference notes | MSSQLServer/concepts |

## Script Categories

### Administration
- User/role management
- Database configuration
- Instance settings

### Backup & Recovery
- Full backups
- Differential backups
- Log backups
- Recovery procedures

### Monitoring
- Performance counters
- Wait statistics
- Query execution plans
- Resource utilization

### Security
- Login auditing
- Permission management
- Encryption configuration
- Compliance checking

### Maintenance
- Index defragmentation
- Statistics updates
- Job scheduling
- Cleanup procedures

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## Support

For issues or questions:
1. Check existing documentation
2. Search existing issues
3. Create a new issue with details
4. Include environment and error information

## License

This repository is provided as-is for database administration purposes.

## Disclaimer

⚠️ **Use with caution:**
- Test all scripts in non-production environments first
- Review scripts before execution
- Maintain backups before running scripts
- Monitor system impact during execution
- Ensure proper change management procedures

---

**Last Updated:** 2026-05-27
**Language Composition:** TSQL (76.5%), JavaScript (17.2%), PowerShell (6.3%)
