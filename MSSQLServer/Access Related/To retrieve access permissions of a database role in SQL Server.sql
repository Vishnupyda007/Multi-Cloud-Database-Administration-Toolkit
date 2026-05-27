SELECT 
    dp.name AS DatabaseRole,
    dp.type_desc AS RoleType,
    perm.permission_name,
    perm.state_desc AS PermissionState,
    perm.class_desc,
    OBJECT_NAME(perm.major_id) AS ObjectName
FROM 
    sys.database_permissions AS perm
JOIN 
    sys.database_principals AS dp ON perm.grantee_principal_id = dp.principal_id
WHERE 
    dp.name = 'YourDatabaseRoleName';  -- Replace with your role name