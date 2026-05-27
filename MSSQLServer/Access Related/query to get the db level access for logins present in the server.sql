-- Create temp table to store results
CREATE TABLE #DbRoleDetails (
    DatabaseName SYSNAME,
    UserName SYSNAME,
    LoginName SYSNAME,
    IsDbOwner VARCHAR(3),
    IsDbReader VARCHAR(3),
    IsDbWriter VARCHAR(3),
    HasExecutePermission VARCHAR(3)
);

-- Loop through all databases
EXEC sp_MSforeachdb '
USE [?];
IF DB_ID() NOT IN (1, 2, 3, 4) AND DB_NAME() NOT IN (''CentralRepository'')
BEGIN
    -- Get role membership
    WITH RoleStatus AS (
        SELECT 
            dp.name AS UserName,
            sp.name AS LoginName,
            MAX(CASE WHEN dr.name = ''db_owner'' THEN 1 ELSE 0 END) AS IsDbOwner,
            MAX(CASE WHEN dr.name = ''db_datareader'' THEN 1 ELSE 0 END) AS IsDbReader,
            MAX(CASE WHEN dr.name = ''db_datawriter'' THEN 1 ELSE 0 END) AS IsDbWriter
        FROM 
            sys.database_role_members drm
        JOIN 
            sys.database_principals dp ON drm.member_principal_id = dp.principal_id
        JOIN 
            sys.database_principals dr ON drm.role_principal_id = dr.principal_id
        LEFT JOIN 
            sys.server_principals sp ON dp.sid = sp.sid
        WHERE 
            dr.name IN (''db_owner'', ''db_datareader'', ''db_datawriter'')
            AND sp.name IS NOT NULL
            AND sp.name NOT IN (''crsdba'', ''deploytool'')
        GROUP BY 
            dp.name, sp.name
    ),
    ExecuteStatus AS (
        SELECT 
            dp.name AS UserName,
            MAX(CASE WHEN perm.permission_name = ''EXECUTE'' THEN 1 ELSE 0 END) AS HasExecute
        FROM 
            sys.database_permissions perm
        JOIN 
            sys.database_principals dp ON perm.grantee_principal_id = dp.principal_id
        GROUP BY dp.name
    )
    INSERT INTO #DbRoleDetails
    SELECT 
        DB_NAME() AS DatabaseName,
        r.UserName,
        r.LoginName,
        CASE WHEN r.IsDbOwner = 1 THEN ''Yes'' ELSE ''No'' END AS IsDbOwner,
        CASE WHEN r.IsDbReader = 1 THEN ''Yes'' ELSE ''No'' END AS IsDbReader,
        CASE WHEN r.IsDbWriter = 1 THEN ''Yes'' ELSE ''No'' END AS IsDbWriter,
        CASE WHEN e.HasExecute = 1 THEN ''Yes'' ELSE ''No'' END AS HasExecutePermission
    FROM RoleStatus r
    LEFT JOIN ExecuteStatus e ON r.UserName = e.UserName;
END';

-- Show results
SELECT * FROM #DbRoleDetails;

-- Clean up
DROP TABLE #DbRoleDetails;
