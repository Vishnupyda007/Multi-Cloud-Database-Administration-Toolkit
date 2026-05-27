-- This script checks all databases on the server instance.

-- Create a temporary table to store the results
CREATE TABLE #DiagramDatabases (
    DatabaseName sysname,
    StatusMessage nvarchar(100)
);

-- Use sp_MSforeachdb to execute a command against each database
-- The '?' is a placeholder for the database name
EXEC sp_MSforeachdb '
USE [?];
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = ''sysdiagrams'')
BEGIN
    INSERT INTO #DiagramDatabases (DatabaseName, StatusMessage)
    VALUES (DB_NAME(), ''Diagram objects FOUND'');
END
';

-- Select the results from the temporary table
SELECT * FROM #DiagramDatabases
ORDER BY DatabaseName;

-- Clean up the temporary table
DROP TABLE #DiagramDatabases;



-----------------------------or--------------------

-- This script checks all online, user-created databases.

DECLARE @db_name sysname;
DECLARE @sql_command nvarchar(max);
DECLARE @diagram_databases TABLE (DatabaseName sysname);

-- Create a cursor to loop through all user databases that are online
DECLARE db_cursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE
    database_id > 4 -- Exclude system databases (master, model, msdb, tempdb)
    AND state_desc = 'ONLINE';

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Build the dynamic SQL to check for the sysdiagrams table
    SET @sql_command = N'
    USE ' + QUOTENAME(@db_name) + ';
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = ''sysdiagrams'')
    BEGIN
        SELECT ''' + @db_name + ''';
    END';

    -- Insert the database name into our table variable if the objects exist
    INSERT INTO @diagram_databases (DatabaseName)
    EXEC sp_executesql @sql_command;

    FETCH NEXT FROM db_cursor INTO @db_name;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Display the final list
SELECT
    DatabaseName,
    'Diagram objects FOUND' AS StatusMessage
FROM
    @diagram_databases
ORDER BY
    DatabaseName;

