-- This script generates the T-SQL commands to recreate server logins,
-- their role memberships, and server-level permissions.
-- CORRECTED FOR COLLATION CONFLICTS.

SET NOCOUNT ON;

-- ************************************************************************************
-- Part 1: Script CREATE LOGIN statements for all SQL and Windows logins
-- ************************************************************************************
PRINT '/*-- Part 1: CREATE LOGIN statements --*/';
DECLARE @login_name sysname, @login_type char(1), @is_disabled bit, @default_db sysname;
DECLARE @sql_command nvarchar(max);
DECLARE @password_hash varbinary(256), @sid varbinary(85);

-- Cursor to iterate through all non-system logins
DECLARE login_cursor CURSOR FOR
    SELECT
        p.name,
        p.type,
        p.is_disabled,
        p.default_database_name,
        l.password_hash,
        p.sid
    FROM
        sys.server_principals p
    LEFT JOIN
        sys.sql_logins l ON p.principal_id = l.principal_id
    WHERE
        p.type IN ('S', 'U', 'G') -- S=SQL, U=Windows User, G=Windows Group
        AND p.name NOT LIKE '##%'
        AND p.principal_id > 1; -- Exclude the 'sa' login by principal_id

OPEN login_cursor;
FETCH NEXT FROM login_cursor INTO @login_name, @login_type, @is_disabled, @default_db, @password_hash, @sid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql_command = 'CREATE LOGIN ' + QUOTENAME(@login_name);

    -- Handle SQL Logins
    IF @login_type = 'S'
    BEGIN
        SET @sql_command = @sql_command + ' WITH PASSWORD = ' + CONVERT(nvarchar(max), @password_hash, 1) + ' HASHED'
                         + ', SID = ' + CONVERT(nvarchar(max), @sid, 1)
                         + ', DEFAULT_DATABASE = ' + QUOTENAME(ISNULL(@default_db, 'master'))
                         + ', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;';
    END
    -- Handle Windows Logins/Groups
    ELSE -- 'U' or 'G'
    BEGIN
        SET @sql_command = @sql_command + ' FROM WINDOWS WITH DEFAULT_DATABASE = ' + QUOTENAME(ISNULL(@default_db, 'master')) + ';';
    END

    -- Handle disabled logins
    IF @is_disabled = 1
    BEGIN
        SET @sql_command = @sql_command + CHAR(13) + CHAR(10) + 'ALTER LOGIN ' + QUOTENAME(@login_name) + ' DISABLE;';
    END

    PRINT @sql_command;
    PRINT ''; -- Add a blank line for readability

    FETCH NEXT FROM login_cursor INTO @login_name, @login_type, @is_disabled, @default_db, @password_hash, @sid;
END

CLOSE login_cursor;
DEALLOCATE login_cursor;
GO

-- ************************************************************************************
-- Part 2: Script Server Role Memberships (Corrected for Collation)
-- ************************************************************************************
PRINT '/*-- Part 2: Add Logins to Server Roles --*/';
SELECT
    'ALTER SERVER ROLE ' + QUOTENAME(roles.name) + ' ADD MEMBER ' + QUOTENAME(members.name COLLATE DATABASE_DEFAULT) + ';' AS [-- Server Role Membership Script --]
FROM
    sys.server_role_members rm
JOIN
    sys.server_principals roles ON rm.role_principal_id = roles.principal_id
JOIN
    sys.server_principals members ON rm.member_principal_id = members.principal_id
WHERE
    members.type IN ('S', 'U', 'G')
    AND members.principal_id > 1;
GO

-- ************************************************************************************
-- Part 3: Script Server-Level Permissions (Corrected for Collation)
-- ************************************************************************************
PRINT '/*-- Part 3: Grant Server-Level Permissions --*/';
SELECT
    p.state_desc + ' ' + p.permission_name + ' TO ' + QUOTENAME(grantee.name COLLATE DATABASE_DEFAULT) + ';' AS [-- Server-Level Permissions Script --]
FROM
    sys.server_permissions p
JOIN
    sys.server_principals grantee ON p.grantee_principal_id = grantee.principal_id
WHERE
    grantee.type IN ('S', 'U', 'G')
    AND grantee.principal_id > 1;
GO
