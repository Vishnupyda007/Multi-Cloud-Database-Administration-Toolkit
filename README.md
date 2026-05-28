# 🌐 Multi-Cloud Database Scripts & Automation

[![TSQL](https://img.shields.io/badge/TSQL-63.8%25-blue?style=flat-square&logo=microsoft-sql-server)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![PLpgSQL](https://img.shields.io/badge/PLpgSQL-32.1%25-green?style=flat-square&logo=postgresql)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![JavaScript](https://img.shields.io/badge/JavaScript-2.4%25-yellow?style=flat-square&logo=javascript)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![PowerShell](https://img.shields.io/badge/PowerShell-1.3%25-red?style=flat-square&logo=powershell)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![Python](https://img.shields.io/badge/Python-0.4%25-purple?style=flat-square&logo=python)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)

[![AWS](https://img.shields.io/badge/AWS-RDS%20%7C%20DynamoDB-FF9900?style=flat-square&logo=amazon-aws)](./AWS/README.md)
[![Azure](https://img.shields.io/badge/Azure-SQL%20%7C%20CosmosDB-0078D4?style=flat-square&logo=microsoft-azure)](./Azure/README.md)
[![GCP](https://img.shields.io/badge/GCP-Cloud%20SQL-4285F4?style=flat-square&logo=google-cloud)](./GCP/README.md)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts?style=flat-square)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)

Database administration scripts for **AWS**, **Azure**, and **GCP** including automation tools for managing SQL Server, PostgreSQL, and other cloud databases.

---

## 📚 Table of Contents

| Section | Links |
|---------|-------|
| **Getting Started** | [Quick Start](#-quick-start) • [Prerequisites](#-prerequisites) • [Setup Guide](./GETTING-STARTED.md) |
| **Documentation** | [Features](#-features) • [Structure](#-repository-structure) • [FAQ](#-faq) |
| **Cloud Providers** | [AWS](./AWS/README.md) • [Azure](./Azure/README.md) • [GCP](./GCP/README.md) |
| **Resources** | [Security](./SECURITY.md) • [Contributing](./CONTRIBUTING.md) • [Changelog](./CHANGELOG.md) |

---

## ✨ Features

- ✅ **Multi-Cloud Support** - AWS, Azure, GCP, and On-Premises databases
- ✅ **5 Programming Languages** - T-SQL (63.8%), PLpgSQL (32.1%), JavaScript (2.4%), PowerShell (1.3%), Python (0.4%)
- ✅ **Production-Ready Scripts** - Tested, documented, and battle-proven
- ✅ **Security-First Approach** - Built-in best practices and credential protection
- ✅ **Complete Documentation** - Every script thoroughly explained
- ✅ **Cloud Automation** - AWS CLI, Azure CLI, and GCP SDK integration
- ✅ **Performance Optimization** - Database tuning and query optimization
- ✅ **Backup & Recovery** - Full, differential, and point-in-time recovery solutions
- ✅ **CI/CD Ready** - GitHub Actions validation pipeline included

---

## 📊 Language Composition

```
TSQL (T-SQL)           ████████████████████████████ 63.8%  SQL Server Administration
PLpgSQL (PostgreSQL)   ████████████████████ 32.1%         Database Procedures
JavaScript             █ 2.4%                             Cloud Automation
PowerShell             █ 1.3%                             Azure Management
Python                 0.4%                               Utility Scripts
```

---

## 🏗️ Repository Structure

```
multi-cloud-db-scripts-Automation-Scripts/
│
├── 📁 AWS/                                 # Amazon Web Services
│   ├── RDS/                                # SQL Server & PostgreSQL on RDS
│   ├── DynamoDB/                           # NoSQL Database Management
│   ├── CloudFormation/                     # Infrastructure as Code
│   └── README.md                           # AWS Documentation
│
├── 📁 Azure/                               # Microsoft Azure
│   ├── SQL-Database/                       # Azure SQL Database
│   ├── SQL-Managed-Instance/               # Managed Instance Scripts
│   ├── CosmosDB/                           # NoSQL Database
│   ├── PostgreSQL/                         # Azure Database for PostgreSQL
│   └── README.md                           # Azure Documentation
│
├── 📁 GCP/                                 # Google Cloud Platform
│   ├── CloudSQL/                           # Cloud SQL Administration
│   ├── BigQuery/                           # Data Warehouse Operations
│   ├── Firestore/                          # NoSQL Database
│   ├── Deployment-Manager/                 # Infrastructure as Code
│   └── README.md                           # GCP Documentation
│
├── 📁 MSSQLServer/                         # On-Premises SQL Server
│   ├── administration/                     # Instance Management
│   ├── backup-recovery/                    # Backup & Restore Procedures
│   ├── monitoring/                         # Performance Monitoring
│   ├── security/                           # Security & Auditing
│   ├── maintenance/                        # Index & Statistics Management
│   └── README.md
│
├── 📁 PostgreSQL/                          # PostgreSQL Administration
│   ├── administration/                     # User & Database Management
│   ├── backup-recovery/                    # pgDump & Recovery
│   ├── monitoring/                         # Performance Queries
│   ├── maintenance/                        # VACUUM & Optimization
│   ├── Performance Related/                # Advanced Tuning Labs
│   └── README.md
│
├── 📁 Common/                              # Shared Utilities
│   ├── monitoring.sh                       # Cross-Cloud Monitoring
│   ├── alerting.py                         # Alert Management
│   ├── helpers.sh                          # Helper Functions
│   └── README.md
│
├── 📁 .github/workflows/                   # CI/CD Automation
│   └── script-validation.yml               # Automated Validation
│
├── 📋 Configuration & Documentation
├── ├── README.md                           # Main Documentation (You are here!)
│   ├── GETTING-STARTED.md                  # Step-by-Step Setup Guide
│   ├── SECURITY.md                         # Security Best Practices
│   ├── CONTRIBUTING.md                     # How to Contribute
│   ├── CHANGELOG.md                        # Version History
│   ├── .env.example                        # Environment Template
│   ├── .gitignore                          # Git Ignore Patterns
│   └── LICENSE                             # MIT License
```

---

## 🚀 Quick Start

### Step 1: Clone the Repository

```bash
git clone https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts.git
cd multi-cloud-db-scripts-Automation-Scripts
```

### Step 2: Setup Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your credentials
nano .env  # or code .env for VS Code

# Secure the file
chmod 600 .env
```

### Step 3: Choose Your Cloud Provider

**Select your cloud platform:**

- 🔗 **[AWS Scripts](./AWS/README.md)** - RDS, DynamoDB, CloudFormation
- 🔗 **[Azure Scripts](./Azure/README.md)** - SQL Database, Managed Instance, CosmosDB
- 🔗 **[GCP Scripts](./GCP/README.md)** - Cloud SQL, BigQuery, Firestore
- 🔗 **[SQL Server Scripts](./MSSQLServer/README.md)** - On-Premises Administration
- 🔗 **[PostgreSQL Scripts](./PostgreSQL/README.md)** - Database Administration

### Step 4: Read the Setup Guide

👉 **[Complete Getting Started Guide](./GETTING-STARTED.md)** - Detailed instructions for all platforms

---

## 📋 Prerequisites

### System Requirements

- **OS**: Windows, macOS, or Linux
- **Disk Space**: 500 MB minimum
- **Internet**: Required for cloud operations

### Required Tools

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **Git** | 2.30+ | Version control | [git-scm.com](https://git-scm.com) |
| **Bash** | 4.0+ | Shell scripting | Pre-installed on macOS/Linux |
| **PowerShell** | 7.0+ | Windows automation | [PowerShell Docs](https://docs.microsoft.com/powershell/) |
| **Node.js** | 14+ | JavaScript runtime | [nodejs.org](https://nodejs.org) |
| **Python** | 3.7+ | Python scripts | [python.org](https://www.python.org) |
| **sqlcmd** | Latest | SQL Server client | [SSMS](https://docs.microsoft.com/sql/ssms/download-sql-server-management-studio-ssms) |
| **psql** | 12+ | PostgreSQL client | [PostgreSQL](https://www.postgresql.org/download/) |

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

## 💻 Usage Examples

### T-SQL (SQL Server)
```bash
sqlcmd -S server_name -d database_name -U user -P password -i script.sql
```

### PowerShell (Azure/Windows)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\Azure\SQL-Database\backup-sqldb.ps1 -ServerName "myserver" -DatabaseName "mydb"
```

### Bash (AWS/GCP/Linux)
```bash
chmod +x AWS/RDS/backup-rds.sh
./AWS/RDS/backup-rds.sh --instance-id mydb --region us-east-1
```

### JavaScript/Node.js
```bash
cd Azure/CosmosDB
npm install
node management.js --action backup --account myaccount
```

### Python
```bash
pip install -r requirements.txt
python Common/monitoring.py --cloud aws --action health-check
```

---

## 🎯 Script Categories

### 📊 Administration
- User and role management
- Database configuration
- Instance settings
- Permission management

### 💾 Backup & Recovery
- Full backups
- Differential backups
- Log backups
- Point-in-time recovery
- Automated scheduling

### 📈 Monitoring
- Performance metrics
- Wait statistics
- Query execution plans
- Resource utilization
- Custom alerts

### 🔒 Security
- Login auditing
- Permission auditing
- Encryption setup
- Compliance checking
- Vulnerability scanning

### 🔧 Maintenance
- Index defragmentation
- Statistics updates
- Job scheduling
- Database cleanup
- Performance tuning

---

## ❓ FAQ

**Q: Can I use these scripts in production?**
A: Yes, but always test in non-production first and maintain full backups.

**Q: How do I handle credentials securely?**
A: Use `.env` files (in `.gitignore`) with environment variables. Never hardcode credentials.

**Q: Which scripts are for which database?**
A: Each cloud provider folder has specific scripts. Check the cloud-specific README files.

**Q: Can I customize these scripts?**
A: Absolutely! Scripts are provided as-is for modification and adaptation.

**Q: How do I contribute improvements?**
A: See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines and workflow.

**Q: Do these scripts work on all operating systems?**
A: T-SQL and Python work on Windows/macOS/Linux. PowerShell scripts require PowerShell 7.0+. Bash scripts require Linux/macOS/WSL.

---

## ⚙️ CI/CD Pipeline

✅ **Automated Validation**
- Bash script syntax checking
- Python syntax compilation
- SQL syntax validation
- JSON configuration validation
- Security credential scanning
- Automated reports on every push

See [.github/workflows/script-validation.yml](./.github/workflows/script-validation.yml)

---

## 📖 Documentation

### Getting Started
- **[GETTING-STARTED.md](./GETTING-STARTED.md)** - Step-by-step setup guide for all platforms
- **[SECURITY.md](./SECURITY.md)** - Security best practices and guidelines
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - How to contribute to this project
- **[CHANGELOG.md](./CHANGELOG.md)** - Version history and roadmap

### Cloud-Specific Guides
- **[AWS Documentation](./AWS/README.md)** - Complete AWS setup and usage guide
- **[Azure Documentation](./Azure/README.md)** - Complete Azure setup and usage guide
- **[GCP Documentation](./GCP/README.md)** - Complete GCP setup and usage guide

### Database-Specific Guides
- **[MSSQLServer Documentation](./MSSQLServer/README.md)** - SQL Server administration
- **[PostgreSQL Documentation](./PostgreSQL/README.md)** - PostgreSQL administration

---

## 📞 Support & Community

- 🐛 **[Report Issues](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts/issues)** - Report bugs and feature requests
- 💬 **[Discussions](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts/discussions)** - Ask questions and share ideas
- 👤 **[@Vishnupyda007](https://github.com/Vishnupyda007)** - Creator and maintainer
- 📧 **Email Support** - For security issues, please report privately

---

## 🎓 Additional Resources

### Cloud Provider Documentation
- **[AWS RDS Documentation](https://docs.aws.amazon.com/rds/)**
- **[Azure SQL Documentation](https://docs.microsoft.com/azure/azure-sql/)**
- **[GCP Cloud SQL Documentation](https://cloud.google.com/sql/docs)**
- **[SQL Server Documentation](https://docs.microsoft.com/sql/)**
- **[PostgreSQL Documentation](https://www.postgresql.org/docs/)**

### Tools & Technologies
- **[SQL Server Management Studio](https://docs.microsoft.com/sql/ssms/download-sql-server-management-studio-ssms)**
- **[pgAdmin](https://www.pgadmin.org/)**
- **[AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)**
- **[Azure CLI Reference](https://docs.microsoft.com/cli/azure/)**
- **[gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)**

---

## 📜 License

**MIT License** - See [LICENSE](LICENSE) for full details.

Free to use in personal and commercial projects with attribution.

---

## ⚠️ Disclaimer

**Important Security Reminders:**

- ✅ Always test scripts in non-production environments first
- ✅ Review and understand scripts before execution
- ✅ Maintain complete backups before running any scripts
- ✅ Monitor system performance during script execution
- ✅ Follow your organization's change management policies
- ✅ Never commit credentials or secrets to Git
- ✅ Use managed identities and RBAC where possible
- ✅ Rotate credentials regularly

**The authors assume no responsibility for data loss, downtime, or other issues arising from script usage.**

---

## 🌟 Project Stats

| Metric | Value |
|--------|-------|
| **Primary Language** | T-SQL (63.8%) |
| **Secondary Language** | PLpgSQL (32.1%) |
| **Cloud Platforms** | 3+ (AWS, Azure, GCP) |
| **Databases Supported** | 6+ |
| **Script Categories** | 5+ |
| **Version** | 1.1.0 |
| **Last Updated** | 2026-05-28 |

---

<div align="center">

## Made with ❤️ by [Vishnupyda007](https://github.com/Vishnupyda007)

**Multi-Cloud Database Administrator**

[⭐ Star](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts) this repository if you find it helpful!

---

[![GitHub Repo](https://img.shields.io/badge/GitHub-Repo-blue?style=social&logo=github)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![License MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**Last Updated:** 2026-05-28

---

*Database administration scripts for AWS, Azure, GCP including Automation*

</div>