-- This script must be run from the 'master' database.
USE master;
GO

SET NOCOUNT ON;

-- **********************************************************************************
-- ***** SCRIPT LOGIC (Fully Automated with Dynamic Server Name)                *****
-- **********************************************************************************
DECLARE @loginPrefix sysname = N'sdbsecadmin@'; -- The fixed part of the login name
DECLARE @aadLoginName sysname;
DECLARE @dbName sysname;
DECLARE @sqlCommand nvarchar(MAX);

PRINT 'Step 1: Dynamically constructing the login name for this server...';

-- Automatically construct the full login name using the server's actual name.
SET @aadLoginName = @loginPrefix + @@SERVERNAME;

PRINT '-> Target login name for this server is: [' + @aadLoginName + ']';

PRINT 'Step 2: Validating that this login exists on the server...';

-- Validate that the constructed login name actually exists on this server.
IF NOT EXISTS (
    SELECT 1
    FROM sys.server_principals
    WHERE name = @aadLoginName AND type IN ('E', 'X','S') -- 'E'=User, 'X'=Group
)
BEGIN
    -- If the login doesn't exist, raise a specific error and stop.
    RAISERROR('FATAL ERROR: The expected login ''%s'' was not found on this server. Please ensure the AAD principal is created. Script cannot continue.', 16, 1, @aadLoginName);
    RETURN;
END;

PRINT '-> Login validated successfully.';
PRINT '----------------------------------------------------------------------------------';
PRINT 'Step 3: Starting to grant db_datareader access where needed in user databases...';
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
        CREATE USER [' + @aadLoginName + '] FOR LOGIN [' + @aadLoginName + '];
    END
    ELSE
    BEGIN
        PRINT ''   -> User already exists.'';
    END

    -- Check if the user is already in the db_datareader role.
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
