-- Create a temporary table to store results
IF OBJECT_ID('tempdb..#LoginPermissions') IS NOT NULL
    DROP TABLE #LoginPermissions;
 
CREATE TABLE #LoginPermissions (
    LoginName NVARCHAR(255),
    LoginType NVARCHAR(255),
    IsDisabled BIT,
    DatabaseName NVARCHAR(255),
    UserName NVARCHAR(255),
    RoleName NVARCHAR(255),
    Permission NVARCHAR(255),
    PermissionState NVARCHAR(255)
);
 
-- Loop through each database and gather login permissions
EXEC sp_MSforeachdb '
USE [?];
INSERT INTO #LoginPermissions
SELECT
sp.name AS LoginName,
    sp.type_desc AS LoginType,
    sp.is_disabled AS IsDisabled,
    DB_NAME() AS DatabaseName,
dp.name AS UserName,
rl.name AS RoleName,
    perm.permission_name AS Permission,
    perm.state_desc AS PermissionState
FROM
    sys.database_principals AS dp
INNER JOIN
    sys.server_principals AS sp ON dp.sid = sp.sid
LEFT JOIN
    sys.database_role_members AS drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN
    sys.database_principals AS rl ON drm.role_principal_id = rl.principal_id
LEFT JOIN
    sys.database_permissions AS perm ON dp.principal_id = perm.grantee_principal_id
WHERE
    sp.type IN (''S'', ''U'', ''G'',''X'',''E'') -- Only SQL, Windows Logins, and Groups
AND
    DB_NAME() NOT IN (''master'', ''tempdb'', ''model'', ''msdb'') -- Exclude system databases
';
 
-- Select results from temporary table
SELECT distinct * FROM #LoginPermissions
ORDER BY LoginName, DatabaseName, UserName, RoleName;
 
-- Drop the temporary table
DROP TABLE #LoginPermissions;
