# SQL Server Security & Encryption

Scripts for enabling encryption, SSL/TLS configuration, auditing, and implementing security best practices.

---

## Scripts in This Category

### Transparent Data Encryption (TDE)
- **enable-tde.sql** - Enable database encryption
- **TDE and Encryption Key/** - TDE management
- **verify-tde-status.sql** - Check encryption status

### SSL/TLS Configuration
- **ssl-configuration.txt** - Configure SSL for connections
- **To Determine the SSL Version used by cloud SQL Server.txt** - Check SSL version
- **certificate-management.sql** - Manage certificates

### Auditing
- **audit-setup.sql** - Enable SQL Server audit
- **audit-queries.sql** - Query audit logs
- **compliance-reporting.sql** - Generate compliance reports

### Credentials & Keys
- **Latest_Cloud_Backup_Key_credentials_Prod&NonProd_Recreate.sql** - Cloud credentials
- **Cloud Credential Key.txt** - Setup cloud credentials
- **Name of Asymmetric key, thumbprint of the asymmetric key.txt** - Key management

### Database Security
- **to check System mails sent, unsent, failure Query.sql** - Database mail security
- **Script to get user Object access list, permissions in whole the server.txt** - Permission audit
- **Server Level Logins and their DB access & DB permissions List.sql** - Access audit

---

## Security Fundamentals

### Authentication
- **Windows Authentication:** Integrated security (recommended)
- **SQL Authentication:** SQL Server logins (use strong passwords)
- **Service Accounts:** Application service principals

### Encryption Levels
1. **Transport Encryption (SSL/TLS):** Encrypts data in transit
2. **Database Encryption (TDE):** Encrypts data at rest
3. **Column-Level Encryption:** Individual columns encrypted
4. **Always Encrypted:** Client-side encryption

### Defense in Depth
- Authentication (who)
- Authorization (what they can do)
- Encryption (protect data)
- Auditing (track access)
- Monitoring (detect attacks)

---

## Common Tasks

### Enable Transparent Data Encryption (TDE)
```sql
-- Step 1: Create Database Master Key (in master database)
USE master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';

-- Step 2: Create Certificate
CREATE CERTIFICATE TDECert
WITH SUBJECT = 'TDE Certificate';

-- Step 3: Create Encryption Key in user database
USE YourDatabase;
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDECert;

-- Step 4: Enable Encryption
ALTER DATABASE YourDatabase SET ENCRYPTION ON;

-- Verify encryption is enabled
SELECT name, is_encrypted FROM sys.databases WHERE name = 'YourDatabase';
```

### Configure SSL/TLS
```sql
-- Step 1: Generate or import certificate (Windows)
-- - Use Certificate Manager or IIS
-- - Install in "Local Computer" > "Personal"
-- - Thumbprint: ABC123...

-- Step 2: Configure SQL Server (using T-SQL)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'ssl', 1;
RECONFIGURE;
EXEC sp_configure 'force encryption', 1;  -- Require SSL
RECONFIGURE;

-- Step 3: Restart SQL Server for changes to take effect

-- Verify SSL enabled
SELECT name, value FROM sys.configurations WHERE name LIKE '%ssl%';
```

### Enable SQL Server Audit
```sql
-- Step 1: Create Audit Object
CREATE SERVER AUDIT [ServerAudit]
TO FILE (FILEPATH = N'C:\Audits\', MAXSIZE = 10 MB);

-- Step 2: Enable Audit
ALTER SERVER AUDIT [ServerAudit] WITH (STATE = ON);

-- Step 3: Create Audit Specification
CREATE SERVER AUDIT SPECIFICATION [AuditLogins]
FOR SERVER AUDIT [ServerAudit]
ADD (SUCCESSFUL_LOGIN_GROUP, FAILED_LOGIN_GROUP);

-- Step 4: Enable Audit Specification
ALTER SERVER AUDIT SPECIFICATION [AuditLogins] WITH (STATE = ON);
```

### Query Audit Logs
```sql
-- View audit events
SELECT 
    event_time,
    server_principal_name,
    action_id,
    statement
FROM sys.fn_get_audit_file('C:\Audits\*.sqlaudit', DEFAULT, DEFAULT)
ORDER BY event_time DESC;
```

### Restrict User Permissions
```sql
-- Check current permissions
SELECT * FROM fn_my_permissions(NULL, 'SERVER');

-- Grant minimal permissions (not admin)
USE YourDatabase;
CREATE USER appuser FOR LOGIN appuser;
ALTER ROLE db_datareader ADD MEMBER appuser;
ALTER ROLE db_datawriter ADD MEMBER appuser;

-- Grant specific table permissions
GRANT SELECT, INSERT, UPDATE ON dbo.SpecificTable TO appuser;
```

### Audit User Access
```sql
-- Find users with elevated permissions
SELECT 
    p.name AS PrincipalName,
    r.name AS RoleName
FROM sys.database_role_members m
JOIN sys.database_principals p ON m.member_principal_id = p.principal_id
JOIN sys.database_principals r ON m.role_principal_id = r.principal_id
WHERE r.name IN ('db_owner', 'db_ddladmin', 'db_securityadmin')
ORDER BY p.name;

-- Find unused logins
SELECT 
    name,
    last_login_time = (
        SELECT MAX(last_login_time)
        FROM sys.dm_exec_sessions
        WHERE login_name = sp.name
    )
FROM sys.server_principals sp
WHERE type IN ('S', 'U')
    AND name NOT IN ('sa', 'DOMAIN\ServiceAccount')
ORDER BY last_login_time;
```

---

## Azure Security

### Cloud Credentials
```sql
-- Create credential for Azure backup
CREATE CREDENTIAL [AzureBackupCred]
WITH IDENTITY = 'YourStorageAccount',
    SECRET = 'StorageAccountKey';

-- Backup to Azure
BACKUP DATABASE YourDatabase
TO URL = 'https://yourstorage.blob.core.windows.net/backups/backup.bak'
WITH CREDENTIAL = 'AzureBackupCred',
    COMPRESSION,
    STATS = 10;
```

---

## Security Best Practices

### Encryption
- ✅ Enable TDE on all databases
- ✅ Use AES-256 encryption
- ✅ Backup encryption keys securely
- ✅ Rotate keys periodically
- ✅ Use Always Encrypted for sensitive data
- ❌ Don't store keys on same server as database
- ❌ Don't ignore certificate expiration

### Authentication
- ✅ Use Windows authentication when possible
- ✅ Enforce strong password policies
- ✅ Disable default sa account (or rename)
- ✅ Use service accounts (not user accounts)
- ✅ Implement multi-factor authentication
- ❌ Don't hardcode credentials
- ❌ Don't share login credentials

### Authorization
- ✅ Follow principle of least privilege
- ✅ Grant only needed permissions
- ✅ Review permissions monthly
- ✅ Remove unused logins
- ✅ Separate read/write/admin roles
- ❌ Don't grant sa role unnecessarily
- ❌ Don't use admin accounts for applications

### Auditing
- ✅ Enable auditing in production
- ✅ Monitor login attempts
- ✅ Track permission changes
- ✅ Archive audit logs
- ✅ Review logs regularly
- ❌ Don't ignore failed login attempts
- ❌ Don't disable audit on suspicious activity

---

## Troubleshooting

### SSL Not Working
```sql
-- Check SSL configuration
SELECT name, value FROM sys.configurations WHERE name LIKE '%ssl%';

-- Check certificate
SELECT 
    pvt_key_encryption_type_desc,
    issuer_name,
    issuer_common_name,
    subject_name
FROM sys.dm_server_registry
WHERE registry_key = 'SYSTEM\\CurrentControlSet\\Services\\MSSQLSERVER\\SuperSocketNetLib\\Certificate';
```

### Can't Enable TDE
```sql
-- Check master key exists
USE master;
SELECT name FROM sys.symmetric_keys;

-- Check certificate exists
SELECT name FROM sys.certificates;

-- Recreate if missing
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword123!';
```

### Audit Disk Full
```sql
-- Check audit file size
EXEC sp_get_audit_file_info;

-- Increase max size or archive old files
ALTER SERVER AUDIT [ServerAudit]
TO FILE (FILEPATH = N'C:\\AuditArchive\\', MAXSIZE = 100 MB);
```

---

## Related Files

- **Administration:** `../administration/`
- **Backup & Recovery:** `../backup-recovery/`
- **Monitoring:** `../monitoring/`
- **Troubleshooting:** `../troubleshooting/`

---

**Last Updated:** 2026-07-13  
**Versions:** SQL Server 2016+  
**Status:** Production-Ready