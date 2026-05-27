-- ============================================================

-- Access Backup Script Generator — Azure SQL DB

-- Generates a ready-to-run RESTORE script for a given user

-- Replace @username with the actual user name

-- ============================================================
 
DECLARE @username   NVARCHAR(256) = 'SIICSSaSqlDbTgtNp@cognizant.com'  -- change this

DECLARE @script     NVARCHAR(MAX) = ''

DECLARE @line       NVARCHAR(MAX)
 
-- -------------------------------------------------------

-- HEADER

-- -------------------------------------------------------

SET @script += '-- ============================================================' + CHAR(13)+CHAR(10)

SET @script += '-- Access Restore Script for: ' + @username               + CHAR(13)+CHAR(10)

SET @script += '-- Generated on: ' + CONVERT(VARCHAR, GETDATE(), 120)     + CHAR(13)+CHAR(10)

SET @script += '-- Database: ' + DB_NAME()                                + CHAR(13)+CHAR(10)

SET @script += '-- ============================================================' + CHAR(13)+CHAR(10)

SET @script += CHAR(13)+CHAR(10)
 
-- -------------------------------------------------------

-- STEP 1: CREATE USER

-- -------------------------------------------------------

SELECT @script +=

    '-- Step 1: Create User' + CHAR(13)+CHAR(10) +

    CASE dp.type

        WHEN 'E' THEN 'CREATE USER [' + dp.name + '] FROM EXTERNAL PROVIDER;'

        WHEN 'X' THEN 'CREATE USER [' + dp.name + '] FROM EXTERNAL PROVIDER;'

        WHEN 'S' THEN 'CREATE USER [' + dp.name + '] WITH PASSWORD = ''<restore_password_here>'';'

        ELSE          'CREATE USER [' + dp.name + '];'

    END + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10)

FROM sys.database_principals dp

WHERE dp.name = @username
 
-- -------------------------------------------------------

-- STEP 2: DEFAULT SCHEMA

-- -------------------------------------------------------

SELECT @script +=

    '-- Step 2: Set Default Schema' + CHAR(13)+CHAR(10) +

    'ALTER USER [' + dp.name + '] WITH DEFAULT_SCHEMA = [' + ISNULL(dp.default_schema_name, 'dbo') + '];'

    + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10)

FROM sys.database_principals dp

WHERE dp.name = @username
 
-- -------------------------------------------------------

-- STEP 3: ROLE MEMBERSHIPS

-- -------------------------------------------------------

SET @script += '-- Step 3: Role Memberships' + CHAR(13)+CHAR(10)
 
SELECT @script +=

    'ALTER ROLE [' + rp.name + '] ADD MEMBER [' + dp.name + '];' + CHAR(13)+CHAR(10)

FROM sys.database_role_members drm

JOIN sys.database_principals dp ON dp.principal_id = drm.member_principal_id

JOIN sys.database_principals rp ON rp.principal_id = drm.role_principal_id

WHERE dp.name = @username
 
SET @script += CHAR(13)+CHAR(10)
 
-- -------------------------------------------------------

-- STEP 4: DATABASE LEVEL PERMISSIONS

-- -------------------------------------------------------

SET @script += '-- Step 4: Database Level Permissions' + CHAR(13)+CHAR(10)
 
SELECT @script +=

    CASE perm.state

        WHEN 'G' THEN 'GRANT '

        WHEN 'W' THEN 'GRANT '

        WHEN 'D' THEN 'DENY '

        WHEN 'R' THEN 'REVOKE '

    END

    + perm.permission_name

    + ' TO [' + dp.name + ']'

    + CASE perm.state WHEN 'W' THEN ' WITH GRANT OPTION' ELSE '' END

    + ';' + CHAR(13)+CHAR(10)

FROM sys.database_permissions perm

JOIN sys.database_principals dp ON dp.principal_id = perm.grantee_principal_id

WHERE dp.name   = @username

  AND perm.class = 0              -- database level only
 
SET @script += CHAR(13)+CHAR(10)
 
-- -------------------------------------------------------

-- STEP 5: SCHEMA LEVEL PERMISSIONS

-- -------------------------------------------------------

SET @script += '-- Step 5: Schema Level Permissions' + CHAR(13)+CHAR(10)
 
SELECT @script +=

    CASE perm.state

        WHEN 'G' THEN 'GRANT '

        WHEN 'W' THEN 'GRANT '

        WHEN 'D' THEN 'DENY '

        WHEN 'R' THEN 'REVOKE '

    END

    + perm.permission_name

    + ' ON SCHEMA::[' + SCHEMA_NAME(perm.major_id) + ']'

    + ' TO [' + dp.name + ']'

    + CASE perm.state WHEN 'W' THEN ' WITH GRANT OPTION' ELSE '' END

    + ';' + CHAR(13)+CHAR(10)

FROM sys.database_permissions perm

JOIN sys.database_principals dp ON dp.principal_id = perm.grantee_principal_id

WHERE dp.name    = @username

  AND perm.class = 3              -- schema level
 
SET @script += CHAR(13)+CHAR(10)
 
-- -------------------------------------------------------

-- STEP 6: OBJECT LEVEL PERMISSIONS

--         (tables, views, procedures, functions)

-- -------------------------------------------------------

SET @script += '-- Step 6: Object Level Permissions' + CHAR(13)+CHAR(10)
 
SELECT @script +=

    CASE perm.state

        WHEN 'G' THEN 'GRANT '

        WHEN 'W' THEN 'GRANT '

        WHEN 'D' THEN 'DENY '

        WHEN 'R' THEN 'REVOKE '

    END

    + perm.permission_name

    + ' ON [' + SCHEMA_NAME(obj.schema_id) + '].[' + obj.name + ']'

    + CASE

        WHEN perm.minor_id <> 0

        THEN '([' + col.name + '])'

        ELSE ''

      END

    + ' TO [' + dp.name + ']'

    + CASE perm.state WHEN 'W' THEN ' WITH GRANT OPTION' ELSE '' END

    + ';' + CHAR(13)+CHAR(10)

FROM sys.database_permissions perm

JOIN sys.database_principals dp  ON dp.principal_id  = perm.grantee_principal_id

JOIN sys.objects obj             ON obj.object_id     = perm.major_id

LEFT JOIN sys.columns col        ON col.object_id     = perm.major_id

                                AND col.column_id     = perm.minor_id

WHERE dp.name    = @username

  AND perm.class = 1              -- object level
 
ORDER BY obj.name
 
SET @script += CHAR(13)+CHAR(10)
 
-- -------------------------------------------------------

-- OUTPUT the generated script

-- -------------------------------------------------------

PRINT @script
 
-- Also return as a result set (easier to copy in SSMS)

SELECT @script AS restore_script
 