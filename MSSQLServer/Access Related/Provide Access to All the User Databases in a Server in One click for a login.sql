-- =================================================================================
-- Script to:
-- 1. Create Service Account Logins at the Server Level.
-- 2. Grant SecurityAdmin server role.
-- 3. Create corresponding Users in all non-system user databases.
-- 4. Grant db_owner and db_securityadmin database roles to the new users.
-- =================================================================================

USE [master];
GO

-- =================================================================================
-- PART 1: Create Server-Level Logins
-- =================================================================================
-- Create the login for the Managed Service Identity (MSI) or Windows Account
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = '257-MSI-NP')
    BEGIN
        CREATE LOGIN [257-MSI-NP] FROM external provider;
        PRINT 'Login [257-MSI-NP] created.';
    END
    ELSE
    BEGIN
        PRINT 'Login [257-MSI-NP] already exists.';
    END
END
GO

-- Create the login for the Azure Active Directory account
-- NOTE: This requires Azure AD integration to be enabled on your SQL instance.
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'SSDBReadAccessDev@cognizant.com')
    BEGIN
        CREATE LOGIN [SSDBReadAccessDev@cognizant.com] FROM EXTERNAL PROVIDER;
        PRINT 'Login [SSDBReadAccessDev@cognizant.com] created.';
    END
    ELSE
    BEGIN
        PRINT 'Login [SSDBReadAccessDev@cognizant.com] already exists.';
    END
END
GO

-- =================================================================================
-- PART 2: Grant Server-Level SecurityAdmin Role
-- =================================================================================
-- Add both logins to the SecurityAdmin fixed server role.
ALTER SERVER ROLE [securityadmin] ADD MEMBER [257-MSI-NP];
PRINT 'Granted SecurityAdmin server role to [257-MSI-NP].';

ALTER SERVER ROLE [securityadmin] ADD MEMBER [SSDBReadAccessDev@cognizant.com];
PRINT 'Granted SecurityAdmin server role to [SSDBReadAccessDev@cognizant.com].';
GO

-- =================================================================================
-- PART 3: Create Users and Grant Permissions in All User Databases
-- =================================================================================
-- Use a cursor to iterate through all user databases, excluding system databases
-- and the distribution database.
DECLARE @dbName NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE
    database_id > 4 -- Exclude master, tempdb, model, msdb
    AND name NOT IN ('distribution') -- Explicitly exclude the distribution database
    AND state_desc = 'ONLINE'; -- Only process online databases

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '-----------------------------------------------------------------';
    PRINT 'Processing Database: ' + QUOTENAME(@dbName);
    PRINT '-----------------------------------------------------------------';

    -- Build the dynamic SQL command to be executed in the context of each database.
    -- This corrected version simplifies the PRINT statements to avoid syntax errors.
    SET @sql = N'USE ' + QUOTENAME(@dbName) + N';

    -- Create user for [257-MSI-NP]
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''257-MSI-NP'')
    BEGIN
        CREATE USER [257-MSI-NP] FOR LOGIN [257-MSI-NP];
        PRINT N''  -> User [257-MSI-NP] created.'';
    END
    ELSE
    BEGIN
        PRINT N''  -> User [257-MSI-NP] already exists.'';
    END

    -- Create user for [SSDBReadAccessDev@cognizant.com]
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N''SSDBReadAccessDev@cognizant.com'')
    BEGIN
        CREATE USER [SSDBReadAccessDev@cognizant.com] FOR LOGIN [SSDBReadAccessDev@cognizant.com];
        PRINT N''  -> User [SSDBReadAccessDev@cognizant.com] created.'';
    END
    ELSE
    BEGIN
        PRINT N''  -> User [SSDBReadAccessDev@cognizant.com] already exists.'';
    END

    -- Grant db_owner and db_securityadmin roles to [257-MSI-NP]
    ALTER ROLE [db_owner] ADD MEMBER [257-MSI-NP];
    ALTER ROLE [db_securityadmin] ADD MEMBER [257-MSI-NP];
    PRINT N''  -> Granted db_owner and db_securityadmin to [257-MSI-NP].'';

    -- Grant db_owner and db_securityadmin roles to [SSDBReadAccessDev@cognizant.com]
    ALTER ROLE [db_owner] ADD MEMBER [SSDBReadAccessDev@cognizant.com];
    ALTER ROLE [db_securityadmin] ADD MEMBER [SSDBReadAccessDev@cognizant.com];
    PRINT N''  -> Granted db_owner and db_securityadmin to [SSDBReadAccessDev@cognizant.com].'';
    ';

    -- Execute the dynamic SQL
    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @dbName;
END;

CLOSE db_cursor;
DEALLOCATE db_cursor;

PRINT '=================================================================';
PRINT 'Script execution completed successfully.';
PRINT '=================================================================';
GO
