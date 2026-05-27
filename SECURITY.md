# Security Guidelines

This document outlines security best practices for using these database scripts in production environments.

## 🔐 Credential Management

### DO NOT

- ❌ Commit credentials to git
- ❌ Store passwords in script files
- ❌ Use hardcoded connection strings
- ❌ Share `.env` files
- ❌ Log sensitive data
- ❌ Use plain-text passwords in backups

### DO

- ✅ Use environment variables (`.env`)
- ✅ Use managed identities (Azure MSI, AWS IAM roles)
- ✅ Rotate credentials regularly
- ✅ Use service principals with minimal permissions
- ✅ Encrypt connection strings
- ✅ Use Azure Key Vault, AWS Secrets Manager, GCP Secret Manager

## 🛡️ Script Security

### Before Running Any Script

```bash
# 1. Review the entire script
cat script_name.sql

# 2. Check for hardcoded credentials
grep -r "password\|secret\|key" script_name.sql

# 3. Test in non-production environment
# 4. Review permissions required
# 5. Check backup procedures
```

### PowerShell Execution Policy

```powershell
# Set appropriate execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Disable unsigned script execution in production
Set-ExecutionPolicy -ExecutionPolicy AllSigned -Scope LocalMachine
```

## 🔑 Cloud Provider Credentials

### AWS

```bash
# Use IAM roles instead of access keys
export AWS_ROLE_ARN=arn:aws:iam::ACCOUNT:role/ROLE_NAME

# Never commit credentials
# Use AWS credentials file: ~/.aws/credentials
# Set permissions: chmod 600 ~/.aws/credentials
```

### Azure

```bash
# Use managed identities (preferred)
az login --identity

# Use service principal with minimal rights
az login --service-principal -u CLIENT_ID -p PASSWORD --tenant TENANT_ID

# Use Azure Key Vault for secrets
az keyvault secret show --name DB-PASSWORD --vault-name KEY_VAULT_NAME
```

### GCP

```bash
# Use service account (JSON file)
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# Restrict file permissions
chmod 600 /path/to/service-account-key.json

# Use Workload Identity in Kubernetes
```

## 📝 `.gitignore` Protection

Ensure these patterns are in `.gitignore`:

```
# Credentials
.env
*.credentials
*.key
*.pem
secrets.json
config.json

# Database backups with embedded credentials
*.sql.backup
*.bak

# Cloud credentials
.aws/credentials
~/.gcloud/
.azure/
```

## 🔐 Database Security

### Connection Security

```sql
-- Always use encrypted connections
-- SQL Server
EXEC sp_configure 'force encryption', 1;

-- Azure SQL (automatic TLS 1.2+)
-- GCP Cloud SQL (automatic SSL)
```

### User Permissions

```sql
-- Use principle of least privilege
-- Create limited scope users
CREATE USER [app_user] FOR LOGIN [app_user];
GRANT SELECT, INSERT, UPDATE ON schema::dbo TO [app_user];

-- Avoid using sa/admin for scripts
-- Use service accounts with minimal permissions
```

### Audit Logging

```sql
-- Enable SQL Server audit
CREATE SERVER AUDIT [DB_Audit] 
TO FILE (FILEPATH = 'C:\Audit\');

ALTER SERVER AUDIT [DB_Audit] WITH (STATE = ON);
```

## 🚨 Sensitive Data Logging

### What NOT to log

```powershell
# DON'T log credentials
Write-Log "Connecting with password: $password"  # ❌ BAD

# DO log securely
Write-Log "Connecting to database: $server"      # ✅ GOOD
```

## 🔄 Backup Security

### Encrypt Backups

```sql
-- SQL Server backup encryption
BACKUP DATABASE [DB_Name] 
TO DISK = 'C:\Backup\DB.bak'
WITH ENCRYPTION 
(ALGORITHM = AES_256, SERVER CERTIFICATE = MyCert);
```

### Restrict Access

```bash
# Backup files should be restricted
chmod 600 backup_file.bak

# Store off-site with encryption
aws s3 cp backup.bak s3://backup-bucket/ \
  --sse AES256 \
  --storage-class STANDARD_IA
```

## 📊 Audit & Monitoring

### Enable Query Audit

```sql
-- Track query execution
sp_configure 'default trace enabled', 1;
RECONFIGURE;

-- Monitor failed logins
SELECT * FROM sys.dm_exec_sessions 
WHERE login_name NOT IN ('sa');
```

### Monitor for Suspicious Activity

```powershell
# Log failed connections attempts
Get-EventLog -LogName Security -InstanceId 4625 | 
  Where-Object {$_.TimeGenerated -gt (Get-Date).AddDays(-7)}

# Review permission changes
Get-EventLog -LogName Security -InstanceId 4781
```

## 🔐 Encryption Standards

### Recommended Encryption

| Component | Algorithm | Size |
|---|---|---|
| Database TDE | AES | 256-bit |
| Backups | AES | 256-bit |
| Transit (TLS) | TLS | 1.2+ |
| Certificates | RSA | 2048-bit+ |

## ✅ Pre-Production Checklist

- [ ] Review all scripts for hardcoded credentials
- [ ] Test in non-production environment
- [ ] Verify backup procedures
- [ ] Check audit logging
- [ ] Review user permissions
- [ ] Enable encryption (TDE, backups, transit)
- [ ] Test disaster recovery
- [ ] Document changes
- [ ] Get approval from security team
- [ ] Plan rollback procedure

## 🛟 Incident Response

If credentials are compromised:

1. **Immediately:**
   - Revoke the compromised credentials
   - Rotate passwords/keys
   - Update `.env` and secrets manager

2. **Within 1 hour:**
   - Review access logs
   - Check for unauthorized changes
   - Verify backup integrity

3. **Within 24 hours:**
   - Complete incident report
   - Update security procedures
   - Notify affected parties

## 📚 References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Microsoft SQL Server Benchmarks](https://www.cisecurity.org/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)
- [GCP Security Guidelines](https://cloud.google.com/docs/authentication)

## 🤝 Reporting Security Issues

If you find a security vulnerability:

1. **DO NOT** create a public GitHub issue
2. **DO** email security concerns to the repository maintainers
3. Include: vulnerability description, affected script, and suggested fix
4. Allow time for response before public disclosure

---

**Last Updated:** 2026-05-27

⚠️ Security is everyone's responsibility. Review this guide regularly and keep credentials safe!
