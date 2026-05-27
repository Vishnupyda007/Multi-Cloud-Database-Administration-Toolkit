-- This script must be run from the 'master' database.
USE master;
GO

SET NOCOUNT ON;

-- **********************************************************************************
-- ***** SCRIPT LOGIC (Final Automated & Idempotent Version)                    *****
-- **********************************************************************************
DECLARE @loginNamePattern sysname = N'sdbsecadmin@%'; -- The pattern to find the login
DECLARE @aadLoginName sysname;
DECLARE @dbName sysname;
DECLARE @sqlCommand nvarchar(MAX);
DECLARE @loginCount INT;

PRINT 'Step 1: Dynamically finding the login to permission...';
PRINT 'Searching for a login with the pattern: ''' + @loginNamePattern + '''';

-- Find the AAD login on this server that matches the pattern.
SELECT @aadLoginName = name
FROM sys.server_principals
WHERE
    name LIKE @loginNamePattern
    AND type IN ('E', 'X','S'); -- 'E' = External User, 'X' = External Group

SELECT @loginCount = @@ROWCOUNT;

IF @loginCount = 0
BEGIN
    RAISERROR('FATAL ERROR: No AAD login or group found on this server matching the pattern ''%s''. Script cannot continue.', 16, 1, @loginNamePattern);
    RETURN;
END;

IF @loginCount > 1
BEGIN
    RAISERROR('FATAL ERROR: Multiple AAD logins/groups found matching the pattern ''%s''. Please make the pattern more specific. Script cannot continue.', 16, 1, @loginNamePattern);
    RETURN;
END;

PRINT '-> Found unique login/group: [' + @aadLoginName + ']';
PRINT '----------------------------------------------------------------------------------';
PRINT 'Step 2: Starting to grant db_datareader access where needed in user databases...';
PRINT '----------------------------------------------------------------------------------';

-- Create a cursor to loop through all applicable databases.
DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE
    database_id > 4            -- Excludes master, tempdb, model, msdb
    AND name <> 'distribution' -- Excludes distribution database
    AND state_desc = 'ONLINE'
    AND is_read_only = 0;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '-- Processing database: ' + QUOTENAME(@dbName);

    -- Build the dynamic SQL command with all necessary checks.
    SET @sqlCommand = N'
    USE ' + QUOTENAME(@dbName) + N';

    DECLARE @TargetUser sysname = ''' + @aadLoginName + ''';

    -- Step 1: Create the user from the external provider if it does not already exist.
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @TargetUser)
    BEGIN
        PRINT ''   -> User not found. Creating user...'';
        -- **CRITICAL FIX**: Using FROM EXTERNAL PROVIDER for AAD principals.
        CREATE USER [' + @aadLoginName + '] FOR Login [' + @aadLoginName + '];
    END
    ELSE
    BEGIN
        PRINT ''   -> User already exists.'';
    END

    -- **IDEMPOTENT CHECK**: Check if the user is already in the db_datareader role.
    IF NOT EXISTS (
        SELECT 1
        FROM sys.database_role_members drm
        JOIN sys.database_principals role_p ON drm.role_principal_id = role_p.principal_id
        JOIN sys.database_principals member_p ON drm.member_principal_id = member_p.principal_id
        WHERE role_p.name = ''db_datareader'' AND member_p.name = @TargetUser
    )
    BEGIN
        -- Step 2: Add the user to the role only if they are not already a member.
        PRINT ''   -> User is not in db_datareader. Adding...'';
        ALTER ROLE db_datareader ADD MEMBER [' + @aadLoginName + '];
    END
    ELSE
    BEGIN
        PRINT ''   -> User is already a member of db_datareader. No action needed.'';
    END
    ';

    -- Execute the dynamic SQL command with error handling.
    BEGIN TRY
        EXEC sp_executesql @sqlCommand;
        PRINT '   -> SUCCESS: Completed processing for ' + QUOTENAME(@dbName) + '.';
    END TRY
    BEGIN CATCH
        PRINT '   -> ERROR: Failed to process ' + QUOTENAME(@dbName) + '. Error message: ' + ERROR_MESSAGE();
    END CATCH
    
    PRINT ''; -- Add a blank line for readability

    FETCH NEXT FROM db_cursor INTO @dbName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

PRINT '----------------------------------------------------------------------------------';
PRINT 'Script execution complete.';
GO
