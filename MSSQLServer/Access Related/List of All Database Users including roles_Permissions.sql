-- Create a temporary table to store results
IF OBJECT_ID('tempdb..#DatabaseUserPermissions') IS NOT NULL
    DROP TABLE #DatabaseUserPermissions;
 
CREATE TABLE #DatabaseUserPermissions (
    DatabaseName NVARCHAR(255),
    UserName NVARCHAR(255),
    UserType NVARCHAR(255),
    AuthenticationType NVARCHAR(255),
    RoleName NVARCHAR(255),
    Permission NVARCHAR(255),
    PermissionState NVARCHAR(255)
);
 
-- Loop through each database and gather user details
EXEC sp_MSforeachdb '
USE [?];
INSERT INTO #DatabaseUserPermissions
SELECT 
    DB_NAME() AS DatabaseName,
    dp.name AS UserName,
    dp.type_desc AS UserType,
    dp.authentication_type_desc AS AuthenticationType,
    rl.name AS RoleName,
    perm.permission_name AS Permission,
    perm.state_desc AS PermissionState
FROM 
    sys.database_principals AS dp
LEFT JOIN 
    sys.database_role_members AS drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN 
    sys.database_principals AS rl ON drm.role_principal_id = rl.principal_id
LEFT JOIN 
    sys.database_permissions AS perm ON dp.principal_id = perm.grantee_principal_id
WHERE 
    dp.type IN (''S'', ''U'', ''G'', ''E'',''X'') -- Only SQL users, Windows users, roles, and external users
AND 
    DB_NAME() NOT IN (''master'', ''tempdb'', ''model'', ''msdb'') -- Exclude system databases
';
 
-- Select results from the temporary table
SELECT distinct * FROM #DatabaseUserPermissions
ORDER BY DatabaseName, UserName, RoleName;
 
-- Drop the temporary table
DROP TABLE #DatabaseUserPermissions;




--------------------hasDBAccess column------------------

-- Create a temporary table to store results
IF OBJECT_ID('tempdb..#DatabaseUserPermissions') IS NOT NULL
    DROP TABLE #DatabaseUserPermissions;
 
CREATE TABLE #DatabaseUserPermissions (
    DatabaseName NVARCHAR(255),
    UserName NVARCHAR(255),
    UserType NVARCHAR(255),
    AuthenticationType NVARCHAR(255),
    RoleName NVARCHAR(255),
    Permission NVARCHAR(255),
    PermissionState NVARCHAR(255),
	DBAccess_Status NVARCHAR(255)
);
 
-- Loop through each database and gather user details
EXEC sp_MSforeachdb '
USE [?];
INSERT INTO #DatabaseUserPermissions
SELECT 
    DB_NAME() AS DatabaseName,
    dp.name AS UserName,
    dp.type_desc AS UserType,
    dp.authentication_type_desc AS AuthenticationType,
    rl.name AS RoleName,
    perm.permission_name AS Permission,
    perm.state_desc AS PermissionState,
	u.hasdbaccess as DBAccess_Status
FROM 
    sys.database_principals AS dp
LEFT JOIN 
    sys.database_role_members AS drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN 
    sys.database_principals AS rl ON drm.role_principal_id = rl.principal_id
LEFT JOIN 
    sys.database_permissions AS perm ON dp.principal_id = perm.grantee_principal_id
left join sys.sysusers u on dp.name=u.name
WHERE 
    dp.type IN (''S'', ''U'', ''G'', ''E'',''X'') -- Only SQL users, Windows users, roles, and external users
AND 
    DB_NAME() NOT IN (''master'', ''tempdb'', ''model'', ''msdb'') -- Exclude system databases
';
 
-- Select results from the temporary table
SELECT distinct * FROM #DatabaseUserPermissions
ORDER BY DatabaseName, UserName, RoleName;
 
-- Drop the temporary table
DROP TABLE #DatabaseUserPermissions;
 
 