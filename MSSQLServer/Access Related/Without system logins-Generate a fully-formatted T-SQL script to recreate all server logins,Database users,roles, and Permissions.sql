/*************************************************************************************************
**
**  Description:  ULTIMATE COMBINED SCRIPT - FINAL VERSION
**                Generates a fully-formatted T-SQL script to recreate all server logins,
**                database users, roles, and permissions. This version corrects the dynamic
**                SQL context to ensure permissions are scripted from the correct database.
**
**  Version:      ULTIMATE - V12 (Definitive Context Fix)
**
**####### First convert the Result into text mode ############

*************************************************************************************************/

SET NOCOUNT ON;

PRINT '/*************************************************************************************************';
PRINT '**  PART 1: SERVER-LEVEL LOGINS, ROLES, AND PERMISSIONS';
PRINT '*************************************************************************************************/';
PRINT '';

-- ************************************************************************************
-- Script CREATE LOGIN statements
-- ************************************************************************************
DECLARE @login_name sysname, @login_type char(1), @is_disabled bit, @default_db sysname;
DECLARE @sql_command nvarchar(max);
DECLARE @password_hash varbinary(256), @sid varbinary(85);

DECLARE login_cursor CURSOR FOR
    SELECT p.name, p.type, p.is_disabled, p.default_database_name, l.password_hash, p.sid
    FROM sys.server_principals p
    LEFT JOIN sys.sql_logins l ON p.principal_id = l.principal_id
    WHERE p.type IN ('S', 'U', 'G','E','X') AND p.principal_id > 1 AND p.name NOT LIKE '##%';

OPEN login_cursor;
FETCH NEXT FROM login_cursor INTO @login_name, @login_type, @is_disabled, @default_db, @password_hash, @sid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql_command = 'IF NOT EXISTS (SELECT [name] FROM sys.server_principals WHERE [name] = ' + QUOTENAME(@login_name, '''') + ') BEGIN CREATE LOGIN ' + QUOTENAME(@login_name);

    IF @login_type = 'S'
    BEGIN
        SET @sql_command = @sql_command + ' WITH PASSWORD = ' + CONVERT(nvarchar(max), @password_hash, 1) + ' HASHED'
                         + ', SID = ' + CONVERT(nvarchar(max), @sid, 1)
                         + ', DEFAULT_DATABASE = ' + QUOTENAME(ISNULL(@default_db, 'master'))
                         + ', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF; END;';
    END
     ELSE IF @login_type IN ('U', 'G') -- Windows Login
    BEGIN
        SET @sql_command = @sql_command + ' FROM WINDOWS WITH DEFAULT_DATABASE = ' + QUOTENAME(ISNULL(@default_db, 'master')) + '; END;';
    END
    ELSE IF @login_type IN ('E', 'X') -- External Provider Login (e.g., Azure AD User/Group)
    BEGIN
        SET @sql_command = @sql_command + ' FROM EXTERNAL PROVIDER; END;';
    END

    IF @is_disabled = 1
    BEGIN
        SET @sql_command = @sql_command + CHAR(13) + CHAR(10) + 'ALTER LOGIN ' + QUOTENAME(@login_name) + ' DISABLE;';
    END

    PRINT @sql_command + ' GO';

    FETCH NEXT FROM login_cursor INTO @login_name, @login_type, @is_disabled, @default_db, @password_hash, @sid;
END
CLOSE login_cursor;
DEALLOCATE login_cursor;
GO

-- ************************************************************************************
-- Script Server Role Memberships
-- ************************************************************************************
SELECT
    'EXEC sp_addsrvrolemember @loginame = ' + QUOTENAME(members.name COLLATE DATABASE_DEFAULT, '''') + ', @rolename = ' + QUOTENAME(roles.name, '''') + '; GO'
FROM sys.server_role_members rm
JOIN sys.server_principals roles ON rm.role_principal_id = roles.principal_id
JOIN sys.server_principals members ON rm.member_principal_id = members.principal_id
WHERE members.principal_id > 1 AND members.type IN ('S', 'U', 'G');
GO

-- ************************************************************************************
-- Script Server-Level Permissions
-- ************************************************************************************
SELECT
    p.state_desc + ' ' + p.permission_name + ' TO ' + QUOTENAME(grantee.name COLLATE DATABASE_DEFAULT) + '; GO'
FROM sys.server_permissions p
JOIN sys.server_principals grantee ON p.grantee_principal_id = grantee.principal_id
WHERE grantee.principal_id > 1 AND grantee.type IN ('S', 'U', 'G');
GO

PRINT '';
PRINT '/*************************************************************************************************';
PRINT '**  PART 2: DATABASE-LEVEL USERS, ROLES, AND PERMISSIONS (FOR EACH DATABASE)';
PRINT '*************************************************************************************************/';
PRINT '';

-- ************************************************************************************
-- Loop through databases for DB-level permissions
-- ************************************************************************************
DECLARE @db_name sysname;
DECLARE @sql nvarchar(max);

DECLARE db_cursor CURSOR FOR
    SELECT name
    FROM sys.databases
    WHERE state_desc = 'ONLINE' AND database_id >=0 AND is_read_only = 0;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @db_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '----------------------------------------------------------------------------------------------------';
    PRINT '-- Permissions for Database: ' + QUOTENAME(@db_name);
    PRINT '----------------------------------------------------------------------------------------------------';
    
    PRINT 'USE ' + QUOTENAME(@db_name) + ';';
    PRINT 'GO';
    
    -- DB USERS
    PRINT '-- [-- DB USERS --] --';
    SET @sql = N'USE ' + QUOTENAME(@db_name) + N';
        SELECT
            CASE
                WHEN rm.type = ''E''
                THEN ''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '''''' + rm.name + '''''') BEGIN CREATE USER '' + QUOTENAME(rm.name) + '' FROM EXTERNAL PROVIDER; END''
                WHEN rm.authentication_type IN (2, 0) AND (SELECT SUBSTRING(convert(sysname, SERVERPROPERTY(''productversion'')), 1, charindex(''.'',convert(sysname, SERVERPROPERTY(''productversion'')))-1)) > 10
                THEN ''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '''''' + rm.name + '''''') BEGIN CREATE USER '' + QUOTENAME(rm.name) + '' WITHOUT LOGIN WITH DEFAULT_SCHEMA = '' + QUOTENAME(rm.default_schema_name) + '', SID = '' + CONVERT(varchar(1000), rm.sid) + '' END;''
                ELSE ''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '''''' + rm.name + '''''') BEGIN CREATE USER '' + QUOTENAME(rm.name) + '' FOR LOGIN '' + QUOTENAME(SUSER_SNAME(rm.sid)) + '' WITH DEFAULT_SCHEMA = '' + QUOTENAME(ISNULL(rm.default_schema_name, ''dbo'')) + '' END;''
            END + CHAR(13) + CHAR(10) + ''GO''
        FROM sys.database_principals AS rm
        WHERE rm.type IN (''X'',''S'',''G'',''U'',''E'')  AND rm.name <> ''guest'' --AND rm.principal_id > 4;
        IF @@ROWCOUNT = 0 PRINT ''-- (No user-defined users found)'';';
    EXEC sp_executesql @sql;

    -- ORPHANED USERS
    PRINT '-- [-- ORPHANED USERS (Fix Statements) --] --';
    SET @sql = N'USE ' + QUOTENAME(@db_name) + N';
        SELECT ''ALTER USER '' + QUOTENAME(rm.name COLLATE DATABASE_DEFAULT) + '' WITH LOGIN = '' + QUOTENAME(rm.name COLLATE DATABASE_DEFAULT) + '';'' + CHAR(13) + CHAR(10) + ''GO''
        FROM sys.database_principals AS rm
        JOIN master.sys.server_principals AS sp ON rm.name COLLATE DATABASE_DEFAULT = sp.name COLLATE DATABASE_DEFAULT AND rm.sid <> sp.sid
        WHERE rm.[type] IN (''S'',''U'') AND rm.principal_id > 4;
        IF @@ROWCOUNT = 0 PRINT ''-- (No orphaned users found to fix)'';';
    EXEC sp_executesql @sql;
    
    -- APPLICATION ROLES
    PRINT '-- [-- APPLICATION ROLES --] --';
    SET @sql = N'USE ' + QUOTENAME(@db_name) + N';
        SELECT ''-- NOTE: Application role passwords cannot be scripted. A placeholder password is used.'' + CHAR(13) + CHAR(10) + ''CREATE APPLICATION ROLE '' + QUOTENAME(name COLLATE DATABASE_DEFAULT) + '' WITH DEFAULT_SCHEMA = '' + QUOTENAME(ISNULL(default_schema_name COLLATE DATABASE_DEFAULT, ''dbo'')) + '', PASSWORD = '' + QUOTENAME(''replace_this_password_immediately'', '''''''') + '';'' + CHAR(13) + CHAR(10) + ''GO''
        FROM sys.database_principals WHERE type = ''A'' AND principal_id > 4;
        IF @@ROWCOUNT = 0 PRINT ''-- (No application roles found)'';';
    EXEC sp_executesql @sql;

    -- DB ROLES
    PRINT '-- [-- DB ROLES --] --';
    SET @sql = N'USE ' + QUOTENAME(@db_name) + N';
        SELECT ''EXEC sp_addrolemember @rolename ='' + SPACE(1) + QUOTENAME(roles.name COLLATE DATABASE_DEFAULT, '''''''') + '', @membername ='' + SPACE(1) + QUOTENAME(members.name COLLATE DATABASE_DEFAULT, '''''''') + '';'' + CHAR(13) + CHAR(10) + ''GO''
        FROM sys.database_role_members rm
        JOIN sys.database_principals roles ON rm.role_principal_id = roles.principal_id
        JOIN sys.database_principals members ON rm.member_principal_id = members.principal_id
        WHERE members.principal_id > 4;
        IF @@ROWCOUNT = 0 PRINT ''-- (No role memberships found)'';';
    EXEC sp_executesql @sql;
    
    -- OBJECT AND COLUMN LEVEL PERMISSIONS
    PRINT '-- [-- OBJECT AND COLUMN LEVEL PERMISSIONS --] --';
    SET @sql = N'USE ' + QUOTENAME(@db_name) + N';
        SELECT CASE WHEN perm.state <> ''W'' THEN perm.state_desc ELSE ''GRANT'' END COLLATE DATABASE_DEFAULT + SPACE(1) + perm.permission_name COLLATE DATABASE_DEFAULT + SPACE(1) + ''ON '' + QUOTENAME(sch.name COLLATE DATABASE_DEFAULT) + ''.'' + QUOTENAME(obj.name COLLATE DATABASE_DEFAULT) +
            CASE WHEN col.name IS NOT NULL THEN ''('' + QUOTENAME(col.name COLLATE DATABASE_DEFAULT) + '')'' ELSE '''' END +
            SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(grantee.name COLLATE DATABASE_DEFAULT) +
            CASE WHEN perm.state = ''W'' THEN SPACE(1) + ''WITH GRANT OPTION'' ELSE '''' END + '';'' + CHAR(13) + CHAR(10) + ''GO''
        FROM sys.database_permissions AS perm
        JOIN sys.database_principals AS grantee ON perm.grantee_principal_id = grantee.principal_id
        JOIN sys.objects AS obj ON perm.major_id = obj.object_id
        JOIN sys.schemas AS sch ON obj.schema_id = sch.schema_id
        LEFT JOIN sys.columns AS col ON perm.major_id = col.object_id AND perm.minor_id = col.column_id
        WHERE grantee.principal_id not in (0,2) AND perm.class_desc = ''OBJECT_OR_COLUMN'';
        IF @@ROWCOUNT = 0 PRINT ''-- (No object or column level permissions found)'';';
    EXEC sp_executesql @sql;
    
    -- TYPE LEVEL PERMISSIONS
    PRINT '-- [-- TYPE LEVEL PERMISSIONS --] --';
    SET @sql = N'USE ' + QUOTENAME(@db_name) + N';
        SELECT perm.state_desc COLLATE DATABASE_DEFAULT + '' '' + perm.permission_name COLLATE DATABASE_DEFAULT + '' ON TYPE::'' + QUOTENAME(typ.name COLLATE DATABASE_DEFAULT) + '' TO '' + QUOTENAME(grantee.name COLLATE DATABASE_DEFAULT) +
            CASE WHEN perm.state = ''W'' THEN SPACE(1) + ''WITH GRANT OPTION'' ELSE '''' END + '';'' + CHAR(13) + CHAR(10) + ''GO''
        FROM sys.database_permissions AS perm
        JOIN sys.database_principals AS grantee ON perm.grantee_principal_id = grantee.principal_id
        JOIN sys.types AS typ ON perm.major_id = typ.user_type_id
        WHERE perm.class_desc = ''TYPE'' AND grantee.principal_id not in (0,2);
        IF @@ROWCOUNT = 0 PRINT ''-- (No type level permissions found)'';';
    EXEC sp_executesql @sql;

    -- DB LEVEL PERMISSIONS
    PRINT '-- [-- DB LEVEL PERMISSIONS --] --';
    SET @sql = N'USE ' + QUOTENAME(@db_name) + N';
        SELECT perm.state_desc COLLATE DATABASE_DEFAULT + '' '' + perm.permission_name COLLATE DATABASE_DEFAULT + '' TO '' + QUOTENAME(grantee.name COLLATE DATABASE_DEFAULT) +
            CASE WHEN perm.state = ''W'' THEN SPACE(1) + ''WITH GRANT OPTION'' ELSE '''' END + '';'' + CHAR(13) + CHAR(10) + ''GO''
        FROM sys.database_permissions AS perm
        JOIN sys.database_principals AS grantee ON perm.grantee_principal_id = grantee.principal_id
        WHERE perm.major_id = 0 AND grantee.principal_id > 4;
        IF @@ROWCOUNT = 0 PRINT ''-- (No database level permissions found)'';';
    EXEC sp_executesql @sql;

    -- SCHEMA PERMISSIONS
    PRINT '-- [-- SCHEMA PERMISSIONS --] --';
    SET @sql = N'USE ' + QUOTENAME(@db_name) + N';
        SELECT perm.state_desc COLLATE DATABASE_DEFAULT + '' '' + perm.permission_name COLLATE DATABASE_DEFAULT + '' ON SCHEMA::'' + QUOTENAME(sch.name COLLATE DATABASE_DEFAULT) + '' TO '' + QUOTENAME(grantee.name COLLATE DATABASE_DEFAULT) +
            CASE WHEN perm.state = ''W'' THEN SPACE(1) + ''WITH GRANT OPTION'' ELSE '''' END + '';'' + CHAR(13) + CHAR(10) + ''GO''
        FROM sys.database_permissions AS perm
        JOIN sys.database_principals AS grantee ON perm.grantee_principal_id = grantee.principal_id
        JOIN sys.schemas AS sch ON perm.major_id = sch.schema_id
        WHERE perm.class_desc = ''SCHEMA'' --AND grantee.principal_id > 4;
        IF @@ROWCOUNT = 0 PRINT ''-- (No schema level permissions found)'';';
    EXEC sp_executesql @sql;
    
    FETCH NEXT FROM db_cursor INTO @db_name;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;
GO

PRINT '';
PRINT '----------------------------------------------------------------------------------------------------';
PRINT '-- Script generation complete.';
PRINT '----------------------------------------------------------------------------------------------------';
GO
