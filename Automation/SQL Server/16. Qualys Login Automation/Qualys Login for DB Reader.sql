-- This script must be run from the 'master' database.
USE master;
GO

SET NOCOUNT ON;

-- ****************************
-- ***** SCRIPT VARIABLES *****
-- ****************************
-- Define the AAD login name here for easy modification.
DECLARE @aadLoginName sysname = N'sdbsecadmin@ctsazsimidevdq01.inso13dfbbbfa2150.database.windows.net';


-- ******************************************************
-- ***** SCRIPT LOGIC (Corrected Version) *****
-- ******************************************************
DECLARE @dbName sysname;
DECLARE @sqlCommand nvarchar(MAX);

PRINT 'Starting to grant db_datareader access to [' + @aadLoginName + '] in all user databases...';
PRINT '----------------------------------------------------------------------------------';

-- Create a cursor to loop through all online user databases.
DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE
    database_id > 4 and name !='distribution'      -- Exclude system databases
    AND state_desc = 'ONLINE'  -- Process only online databases
    AND is_read_only = 0;      -- Process only writeable databases

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '-- Processing database: ' + QUOTENAME(@dbName);

    -- Build the dynamic SQL command to be executed in each database.
    -- Note the single quotes are doubled up ('') to escape them within the string.
    SET @sqlCommand = N'
    USE ' + QUOTENAME(@dbName) + N';

    -- Step 1: Create the user from the external provider (AAD login) if it does not already exist.
    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = ''' + @aadLoginName + ''')
    BEGIN
        PRINT ''   -> User not found. Creating user...'';
        CREATE USER [' + @aadLoginName + '] For login [' + @aadLoginName + '];
    END
    ELSE
    BEGIN
        PRINT ''   -> User already exists.'';
    END

    -- Step 2: Add the user to the db_datareader role.
    PRINT ''   -> Adding user to db_datareader role...'';
    ALTER ROLE db_datareader ADD MEMBER [' + @aadLoginName + '];
    ';

    -- Execute the dynamic SQL command.
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
