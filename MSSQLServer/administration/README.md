# SQL Server Administration Scripts

Scripts for user management, login creation, permissions, database setup, and configuration.

---

## Scripts in This Category

### User & Login Management
- **List of all AD logins and @logins.sql** - Show all logins on server
- **List of All Database Users including roles_Permissions.sql** - Database-level users
- **To get the create script used for the creation of any user.txt** - Recreate user

### Database Management
- **DB_Name and DB_Size_Server.sql** - List databases and sizes
- **To get list of all online and offline databases in a server.sql** - Database status
- **To change DB_Owner of DB.txt** - Change database owner

### Permission & Access
- **To check DDL or DML access of users in a DB.sql** - Check user permissions
- **Server Level Logins and their DB access & DB permissions List.sql** - Login permissions
- **Model_Access_List_for_E2E_Monitoring_of_Servers.sql** - Monitoring role setup

### Configuration
- **IP_Address_Port_Number, Server Version, ipconfig.txt** - Server information
- **Compatibility set and query optimizer fixes.txt** - Database compatibility
- **To check if trustworthy enable or not and set trustworthy on.txt** - Trustworthy flag

---

## Common Tasks

### Create a New Login
```sql
-- SQL Server login (SQL authentication)
CREATE LOGIN newuser WITH PASSWORD = 'SecurePassword123!';

-- Windows/AD login
CREATE LOGIN [DOMAIN\Username] FROM WINDOWS;
```

### Create Database User
```sql
USE YourDatabase;
CREATE USER newuser FOR LOGIN newuser;
```

### Grant Permissions
```sql
-- Grant SELECT, INSERT, UPDATE to specific table
GRANT SELECT, INSERT, UPDATE ON dbo.YourTable TO newuser;

-- Grant database-level permissions
GRANT SELECT ON SCHEMA::dbo TO newuser;

-- Grant server-level permissions
GRANT VIEW SERVER STATE TO newuser;
```

### List All Users
```sql
USE YourDatabase;
SELECT name, type_desc, create_date 
FROM sys.database_principals 
WHERE type IN ('U', 'S', 'G');
```

### Check User Permissions
```sql
-- Check what user can do
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');
```

### Create Database
```sql
CREATE DATABASE YourDatabase
    ON PRIMARY
    (
        NAME = YourDatabase,
        FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\YourDatabase.mdf',
        SIZE = 100MB,
        MAXSIZE = 1000MB,
        FILEGROWTH = 10MB
    )
    LOG ON
    (
        NAME = YourDatabase_Log,
        FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\YourDatabase_log.ldf',
        SIZE = 50MB,
        MAXSIZE = 500MB,
        FILEGROWTH = 5MB
    );
```

### Change Database Owner
```sql
ALTER AUTHORIZATION ON DATABASE::YourDatabase TO [DOMAIN\NewOwner];
```

### Check Database Status
```sql
SELECT name, state_desc, recovery_model_desc 
FROM sys.databases 
ORDER BY name;
```

---

## Prerequisites

- SQL Server 2016 SP2+
- sysadmin or db_owner role
- SSMS or sqlcmd
- Appropriate permissions:
  - CREATE LOGIN (server-level)
  - ALTER ANY LOGIN (server-level)
  - CREATE USER (database-level)
  - CONTROL (database-level)

---

## Best Practices

### Security
- ✅ Use strong passwords (12+ chars, complexity)
- ✅ Use Windows authentication when possible
- ✅ Principle of least privilege
- ✅ Review permissions quarterly
- ❌ Never share login credentials
- ❌ Don't use sa account for applications

### Performance
- ✅ Create logins before users
- ✅ Test in non-production first
- ✅ Monitor resource usage
- ✅ Keep audit logs

### Maintenance
- ✅ Document all changes
- ✅ Keep change log
- ✅ Review user access monthly
- ✅ Remove unused logins
- ✅ Archive old permissions

---

## Troubleshooting

### "Login failed for user" error
```sql
-- Check if login exists
SELECT name FROM sys.server_principals WHERE type IN ('S', 'U');

-- Check if user exists in database
USE YourDatabase;
SELECT name FROM sys.database_principals;

-- Verify user mapped to login
SELECT name, type_desc, sid FROM sys.database_principals WHERE name = 'username';
```

### "Cannot create user" error
```sql
-- Verify login exists first
SELECT name FROM sys.server_principals WHERE name = 'username';

-- Create user and map to login
USE YourDatabase;
CREATE USER username FOR LOGIN username;
```

### Orphaned user (user with no login)
```sql
-- Find orphaned users
USE YourDatabase;
EXEC sp_change_users_login 'Report';

-- Fix orphaned user
EXEC sp_change_users_login 'Auto_Fix', 'username';
```

---

## Usage Examples

### Example 1: Create new application user
```sql
-- Create login
CREATE LOGIN appuser WITH PASSWORD = 'ComplexPassword123!';

-- Create user
USE ApplicationDatabase;
CREATE USER appuser FOR LOGIN appuser;

-- Grant minimal permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Users TO appuser;
GRANT EXECUTE ON SCHEMA::dbo TO appuser;

-- Verify
SELECT * FROM fn_my_permissions('dbo.Users', 'OBJECT');
```

### Example 2: Audit user permissions
```sql
-- Find all users with administrative access
SELECT 
    p.name AS PrincipalName,
    r.name AS RoleName
FROM sys.database_role_members m
JOIN sys.database_principals p ON m.member_principal_id = p.principal_id
JOIN sys.database_principals r ON m.role_principal_id = r.principal_id
WHERE r.name IN ('db_owner', 'db_ddladmin', 'db_securityadmin')
ORDER BY p.name;
```

### Example 3: Remove unnecessary logins
```sql
-- Find unused logins (no login in past 90 days)
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

-- Drop unused login (after verification)
-- DROP LOGIN [domain\unuseduser];
```

---

## Related Files

- **Backup & Recovery:** `../backup-recovery/`
- **Performance:** `../performance/`
- **Security:** `../security/`
- **Troubleshooting:** `../troubleshooting/`

---

**Last Updated:** 2026-07-13