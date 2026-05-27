# Contributing Guidelines

Thank you for your interest in contributing! This guide will help you understand how to submit scripts and improvements.

## 📋 Before You Start

- Read [README.md](./README.md) for project overview
- Review [SECURITY.md](./SECURITY.md) for security requirements
- Check existing issues/PRs to avoid duplicates
- Ensure your script works in target environment

## 🚀 How to Contribute

### 1. Fork and Clone

```bash
git clone https://github.com/YOUR_USERNAME/multi-cloud-db-scripts-Automation-Scripts.git
cd multi-cloud-db-scripts-Automation-Scripts
git checkout -b feature/your-script-name
```

### 2. Add Your Script

Follow the folder structure:

```
AWS/
├── tsql/
│   ├── backup-rds-database.sql
│   ├── monitor-queries.sql
│   └── README.md
├── powershell/
│   ├── Backup-RDSDatabase.ps1
│   └── README.md
└── javascript/
    ├── rds-manager.js
    └── README.md
```

### 3. Script Requirements

#### SQL Files (`.sql`)

```sql
/**
 * Script Purpose: Brief description (1 line)
 * Author: Your Name
 * Date: YYYY-MM-DD
 * Version: 1.0
 * 
 * Description:
 * Detailed explanation of what this script does.
 * Include:
 * - What problem it solves
 * - When to use it
 * - Prerequisites
 * 
 * Usage:
 * sqlcmd -S server_name -d database_name -i script.sql
 * 
 * Parameters:
 * @DatabaseName NVARCHAR(MAX) - Name of target database
 * 
 * Returns:
 * Status message indicating success/failure
 * 
 * Notes:
 * - Important considerations
 * - Potential impacts
 * - Performance implications
 * 
 * Changes:
 * 1.0 - Initial version
 */

-- Example SQL script
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Your script code
SELECT 'Your script here' AS Result;
```

#### PowerShell Scripts (`.ps1`)

```powershell
<#
.SYNOPSIS
    Brief one-line description

.DESCRIPTION
    Detailed description of what the script does.
    Include:
    - Purpose
    - Prerequisites
    - Required modules/tools

.PARAMETER DatabaseName
    The name of the target database

.PARAMETER ServerName
    SQL Server instance name

.EXAMPLE
    PS> .\YourScript.ps1 -ServerName prod-server -DatabaseName UserDB
    Executes backup on UserDB

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Version: 1.0
    
    Prerequisites:
    - PowerShell 7.0+
    - Az PowerShell module
    - Appropriate permissions

.LINK
    https://github.com/Vishnupyda007/multi-cloud-db-scripts-Automation-Scripts
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$DatabaseName,
    
    [Parameter(Mandatory = $true)]
    [string]$ServerName
)

# Your script code here
Write-Host "Starting operation..."
```

#### JavaScript Files (`.js`)

```javascript
/**
 * Script: Description of what it does
 * Author: Your Name
 * Date: YYYY-MM-DD
 * Version: 1.0
 * 
 * Purpose:
 * What this script accomplishes
 * 
 * Prerequisites:
 * - Node.js 14+
 * - Required modules: module1, module2
 * 
 * Usage:
 * node script.js --param value
 * 
 * Environment Variables:
 * DB_HOST, DB_USER, DB_PASSWORD
 */

// Your code here
console.log('Starting script...');
```

### 4. Documentation

Create `README.md` in your script's folder:

```markdown
# [Script Category] Scripts

## Overview
What these scripts do and when to use them.

## Available Scripts

### Script Name 1
**Purpose:** What it does  
**Usage:** How to run it  
**Frequency:** Daily/Weekly/Manual  
**Impact:** What it changes

### Script Name 2
[Similar format]

## Prerequisites
- Required tools
- Required permissions
- Environment setup

## Configuration
How to configure scripts (without credentials):
```yaml
backup_path: /backups
retention_days: 30
```

## Troubleshooting
Common issues and solutions.
```

### 5. Security Review

Before submitting:

```bash
# Check for hardcoded credentials
grep -r "password\|secret\|key" your_script.*

# Verify no sensitive data in comments
grep -r "server=\|user=\|uid=" your_script.*
```

### 6. Testing

Test your script:

- ✅ In non-production environment
- ✅ With different data sets
- ✅ Error handling
- ✅ Permission restrictions
- ✅ Backup/recovery procedures

Create a test report in PR description.

### 7. Commit & Push

```bash
git add your_script.sql
git commit -m "Add: Brief description of script"
# Commit message format:
# Add: New feature/script
# Fix: Bug fix
# Improve: Performance improvement
# Update: Documentation update

git push origin feature/your-script-name
```

### 8. Create Pull Request

Include in PR description:

```markdown
## Description
Brief description of the script(s) added.

## Type of Change
- [ ] New script
- [ ] Bug fix
- [ ] Performance improvement
- [ ] Documentation update

## Script Details
- **Cloud Provider:** AWS/Azure/GCP/On-Premises
- **Database:** SQL Server/PostgreSQL
- **Category:** Backup/Monitoring/Security/etc.
- **Language:** SQL/PowerShell/JavaScript

## Testing Done
- [ ] Tested in non-production environment
- [ ] Verified error handling
- [ ] Checked security (no hardcoded credentials)
- [ ] Tested backup/recovery procedures

## Checklist
- [ ] Code follows style guidelines
- [ ] Added comments/documentation
- [ ] No hardcoded credentials or sensitive data
- [ ] Tested successfully
- [ ] Updated relevant README files
- [ ] No breaking changes
```

## ✅ Naming Conventions

### SQL Files
```
action-resource-environment.sql
Examples:
- backup-database-production.sql
- monitor-queries-azure.sql
- setup-user-rds.sql
```

### PowerShell Files
```
Verb-Noun.ps1 (PascalCase)
Examples:
- Backup-RDSDatabase.ps1
- Monitor-AzureSQLServer.ps1
- Restore-Database.ps1
```

### JavaScript Files
```
camelCase with description
Examples:
- rdsBackupManager.js
- azureSqlMonitor.js
- gcpCloudSqlAdmin.js
```

## 📁 Folder Organization

### SQL Scripts
```
tsql/
├── administration/         # User, role, permission management
├── backup-recovery/        # Backup and restore procedures
├── monitoring/            # Performance monitoring queries
├── security/              # Security and compliance
├── maintenance/           # Index, stats, cleanup
└── README.md
```

### PowerShell Scripts
```
powershell/
├── Backup-*.ps1
├── Monitor-*.ps1
├── Manage-*.ps1
├── Configure-*.ps1
└── README.md
```

### JavaScript Scripts
```
javascript/
├── managers/              # Manager classes
├── utils/                 # Utility functions
├── config/                # Configuration handling
├── index.js              # Entry point
└── README.md
```

## 🔍 Code Review Process

1. Maintainer reviews PR for:
   - Security (no credentials/sensitive data)
   - Code quality and standards
   - Completeness of documentation
   - Testing evidence

2. Feedback provided in PR comments

3. Make requested changes in new commits

4. PR merged after approval

## ⚠️ Common Issues & Rejections

Your PR may be rejected if:

- ❌ Contains hardcoded credentials or secrets
- ❌ Missing documentation/README
- ❌ Not tested in non-production environment
- ❌ No error handling or validation
- ❌ Inconsistent naming conventions
- ❌ Missing comments in complex code
- ❌ Breaking changes without explanation
- ❌ Incomplete or unclear PR description

## 🎯 What We're Looking For

✅ **Scripts that:**
- Solve real database administration problems
- Include comprehensive documentation
- Have proper error handling
- Follow cloud best practices
- Are tested and verified
- Improve on existing scripts
- Support multiple environments
- Include helpful comments

## 🏆 Best Practices

1. **Document Everything**
   - Purpose, parameters, usage
   - Prerequisites and dependencies
   - Expected output

2. **Error Handling**
   - Validate inputs
   - Catch exceptions
   - Provide meaningful error messages

3. **Performance**
   - Efficient queries
   - Avoid infinite loops
   - Consider scalability

4. **Security**
   - Never hardcode credentials
   - Use parameterized queries
   - Validate user input

5. **Maintainability**
   - Clear variable names
   - Comment complex logic
   - Follow conventions
   - Keep scripts focused

## 📞 Questions?

- Create a discussion in GitHub
- Review existing documentation
- Check similar scripts for patterns

## 📄 License

By contributing, you agree that your contributions will be licensed under the same terms as the project.

---

**Thank you for contributing!** Your scripts help the community manage multi-cloud databases effectively.
