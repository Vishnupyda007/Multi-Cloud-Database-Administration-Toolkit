# Enhanced README with Professional Badges

[![TSQL](https://img.shields.io/badge/TSQL-63.8%25-blue?style=flat-square&logo=microsoft-sql-server)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![PLpgSQL](https://img.shields.io/badge/PLpgSQL-32.1%25-green?style=flat-square&logo=postgresql)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![JavaScript](https://img.shields.io/badge/JavaScript-2.4%25-yellow?style=flat-square&logo=javascript)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![PowerShell](https://img.shields.io/badge/PowerShell-1.3%25-red?style=flat-square&logo=powershell)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![Python](https://img.shields.io/badge/Python-0.4%25-purple?style=flat-square&logo=python)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)

[![AWS](https://img.shields.io/badge/AWS-RDS%20%7C%20DynamoDB-FF9900?style=flat-square&logo=amazon-aws)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![Azure](https://img.shields.io/badge/Azure-SQL%20%7C%20CosmosDB-0078D4?style=flat-square&logo=microsoft-azure)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![GCP](https://img.shields.io/badge/GCP-Cloud%20SQL-4285F4?style=flat-square&logo=google-cloud)](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

# 🌐 Multi-Cloud Database Scripts & Automation

Database administration scripts for **AWS**, **Azure**, and **GCP** including automation tools for managing SQL Server, PostgreSQL, and other cloud databases.

---

## 📚 Quick Navigation

| 🔧 | 📖 | 🚀 | ❓ |
|----|----|----|----|  
| [Features](#features) | [Documentation](#documentation) | [Quick Start](#quick-start) | [FAQ](#faq) |
| [Structure](#repository-structure) | [Prerequisites](#prerequisites) | [Usage](#usage-examples) | [Support](#support) |

---

## ✨ Features

- ✅ **Multi-Cloud Support** - AWS, Azure, GCP, and On-Premises
- ✅ **Multiple Languages** - T-SQL (63.8%), PLpgSQL (32.1%), JavaScript (2.4%), PowerShell (1.3%), Python (0.4%)
- ✅ **Production-Ready Scripts** - Tested and documented
- ✅ **Security-Focused** - Best practices included
- ✅ **Comprehensive Documentation** - Every script explained
- ✅ **Automation Tools** - Cloud SDK integration
- ✅ **Performance Optimization** - Database tuning expertise
- ✅ **Backup & Disaster Recovery** - Complete solutions
- ✅ **CI/CD Pipeline** - GitHub Actions validation

---

## 📊 Language Composition

```
TSQL (T-SQL)          ████████████████████████████ 63.8%
PLpgSQL (PostgreSQL)  ████████████████████ 32.1%
JavaScript            █ 2.4%
PowerShell            █ 1.3%
Python                0.4%
```

---

## 📋 Cloud Provider Overview

| Cloud Provider | Databases | Languages |
|---|---|---|
| **AWS** | RDS SQL Server, RDS PostgreSQL, DynamoDB | T-SQL, PowerShell, JavaScript, Python |
| **Azure** | SQL Database, Managed Instance, PostgreSQL, CosmosDB | T-SQL, PowerShell, JavaScript, Python |
| **GCP** | Cloud SQL, BigQuery, Firestore | T-SQL, PowerShell, JavaScript, Python |
| **On-Premises** | SQL Server, PostgreSQL | T-SQL, PLpgSQL, PowerShell, Python |

---

## 📁 Repository Structure

```
multi-cloud-db-scripts-Automation-Scripts/
├── AWS/                              # Amazon Web Services
│   ├── RDS/                          # Relational Database Service
│   ├── DynamoDB/                     # NoSQL Database
│   └── README.md
├── Azure/                            # Microsoft Azure
│   ├── SQL-Database/                 # Azure SQL Database
│   ├── SQL-Managed-Instance/         # Azure SQL MI
│   ├── CosmosDB/                     # NoSQL Database
│   └── README.md
├── GCP/                              # Google Cloud Platform
│   ├── CloudSQL/                     # Cloud SQL
│   ├── BigQuery/                     # Data Warehouse
│   └── README.md
├── MSSQLServer/                      # On-Premises SQL Server
├── PostgreSQL/                       # PostgreSQL Administration
├── Common/                           # Shared Utilities
├── .github/workflows/                # CI/CD Automation
├── .gitignore
├── .env.example
├── README.md
├── SECURITY.md
├── CONTRIBUTING.md
├── CHANGELOG.md
└── GETTING-STARTED.md
```

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts.git
cd multi-cloud-db-scripts-Automation-Scripts
```

### 2. Setup Configuration

```bash
cp .env.example .env
nano .env  # Edit with your credentials
```

### 3. Choose Your Cloud Provider

- **🔗 [AWS Documentation](./AWS/README.md)** - RDS, DynamoDB
- **🔗 [Azure Documentation](./Azure/README.md)** - SQL Database, Managed Instance
- **🔗 [GCP Documentation](./GCP/README.md)** - Cloud SQL, BigQuery
- **🔗 [SQL Server](./MSSQLServer/README.md)** - On-Premises
- **🔗 [PostgreSQL](./PostgreSQL/README.md)** - Administration & Performance

### 4. Read Getting Started Guide

👉 **[Complete Setup Guide](./GETTING-STARTED.md)**

---

## 📖 Documentation

- **[GETTING-STARTED.md](./GETTING-STARTED.md)** - Complete onboarding guide
- **[README.md](./README.md)** - Main documentation
- **[SECURITY.md](./SECURITY.md)** - Security guidelines
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - How to contribute
- **[CHANGELOG.md](./CHANGELOG.md)** - Version history

---

## 📋 Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Git** | 2.30+ | Version control |
| **Bash** | 4.0+ | Shell scripting |
| **PowerShell** | 7.0+ | Automation |
| **Node.js** | 14+ | JavaScript runtime |
| **Python** | 3.7+ | Python scripts |

### Cloud CLIs

```bash
aws --version      # AWS CLI
az --version       # Azure CLI
gcloud --version   # Google Cloud SDK
```

---

## 💻 Usage Examples

### T-SQL Script
```bash
sqlcmd -S server_name -d database_name -i script.sql
```

### PowerShell Script
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\script.ps1
```

### Bash Script
```bash
chmod +x script.sh
./script.sh
```

### JavaScript/Node.js
```bash
npm install && node script.js
```

### Python Script
```bash
pip install -r requirements.txt && python script.py
```

---

## ⚙️ CI/CD Pipeline

- ✅ GitHub Actions workflow for script validation
- ✅ Bash, Python, SQL, and JSON syntax checking
- ✅ Security credential scanning
- ✅ Automated validation on every push/PR

See [.github/workflows/script-validation.yml](.github/workflows/script-validation.yml)

---

## ❓ FAQ

**Q: Can I use these in production?**
A: Yes, but test in non-production first and maintain backups.

**Q: How do I secure credentials?**
A: Use `.env` files with environment variables. Never commit credentials.

**Q: Which scripts work where?**
A: Each cloud provider folder has specific scripts. Check cloud-specific READMEs.

**Q: Can I contribute?**
A: Absolutely! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📞 Support

- 🐛 [Report Issues](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts/issues)
- 💬 [Discussions](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts/discussions)
- 👤 [@Vishnupyda007](https://github.com/Vishnupyda007)

---

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

---

## ⚠️ Disclaimer

Test all scripts in non-production environments first. Review scripts before execution. Maintain backups. Follow your organization's policies.

---

<div align="center">

**Made with ❤️ by [Vishnupyda007](https://github.com/Vishnupyda007) — Multi-Cloud Database Administrator**

[⭐ Star this repository](https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts) if you find it helpful!

**Last Updated:** 2026-05-27 | **Language Composition:** TSQL (63.8%), PLpgSQL (32.1%), JavaScript (2.4%), PowerShell (1.3%), Python (0.4%)

</div>