-- Create a temporary table to store results
IF OBJECT_ID('tempdb..#DatabaseUserPermissions') IS NOT NULL
    DROP TABLE #DatabaseUserPermissions;
 
CREATE TABLE #DatabaseUserPermissions (
    DatabaseName NVARCHAR(255),
	Login_At_Server_Level NVARCHAR(255),
	Login_type Nvarchar(255),
    UserName NVARCHAR(255),
    UserType NVARCHAR(255),
    AuthenticationType NVARCHAR(255),
    RoleName NVARCHAR(255),
    Permission NVARCHAR(255),
	DBAccess_Status NVARCHAR(255),
	is_disabled_Status_Server_Level NVARCHAR(255)
);
 
-- Loop through each database and gather user details
EXEC sp_MSforeachdb '
USE [?];
INSERT INTO #DatabaseUserPermissions
SELECT 
    DB_NAME() AS DatabaseName,
	sp.name as Login_At_Server_Level,
	sp.type as Login_type,
    dp.name AS UserName,
    dp.type_desc AS UserType,
    dp.authentication_type_desc AS AuthenticationType,
    rl.name AS RoleName,
    perm.permission_name AS Permission,
	case 
	when u.hasdbaccess=1 then ''Enabled''
	else ''Disabled'' 
	end as DBAccess_Status,
	case
	when sp.is_disabled=''1'' then ''Disabled'' 
	else ''Enabled'' 
	end as is_disabled_Status_Server_Level
	from
    sys.database_principals AS dp
LEFT JOIN 
    sys.database_role_members AS drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN 
    sys.database_principals AS rl ON drm.role_principal_id = rl.principal_id
LEFT JOIN 
    sys.database_permissions AS perm ON dp.principal_id = perm.grantee_principal_id
left join sys.sysusers u on dp.name=u.name
left join sys.Server_Principals sp on dp.name= sp.name
WHERE 
    dp.type IN (''S'', ''U'', ''G'', ''E'') -- Only SQL users, Windows users, roles, and external users
AND dp.authentication_type_desc !=''EXTERNAL'' and dp.name not in (''sdbsecadmin@ctsazsimiptm1.293366d454bb.database.windows.net'',''deploytool'') and sp.type !=''Null'' and 
    DB_NAME() NOT IN (''master'', ''tempdb'', ''model'', ''msdb'') -- Exclude system databases
';
 
-- Select results from the temporary table
SELECT distinct * FROM #DatabaseUserPermissions
ORDER BY DatabaseName, UserName, RoleName;
 
-- Drop the temporary table
DROP TABLE #DatabaseUserPermissions;
 