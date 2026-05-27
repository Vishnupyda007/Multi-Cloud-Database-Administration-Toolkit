SELECT dp.name AS UserName,
       dp.type_desc AS UserType,
       CASE WHEN dperm.permission_name = 'ALTER' OR dperm.permission_name = 'CONTROL' THEN 'DDL Access'
            WHEN dperm.permission_name IN ('INSERT', 'UPDATE', 'DELETE') THEN 'DML Access'
            ELSE 'No DDL/DML Access'
       END AS AccessType
FROM sys.database_principals dp
JOIN sys.database_permissions dperm
ON dp.principal_id = dperm.grantee_principal_id
WHERE dp.type IN ('S', 'U', 'G') -- S = SQL user, U = Windows user, G = Windows group
AND dperm.permission_name IN ('ALTER', 'CONTROL', 'INSERT', 'UPDATE', 'DELETE')
AND dp.name NOT LIKE '##%' -- Excluding system users
ORDER BY dp.name;


--------------OR----------------------------


SELECT
dp.name AS UserName,
    CASE
        WHEN dp.type_desc = 'DATABASE_ROLE' THEN 'Role'
        ELSE 'User'
    END AS UserType,
dp2.name AS RoleName,
    CASE
        WHEN dpm.permission_name = 'CONTROL' THEN 'DDL Admin'
        WHEN dpm.permission_name = 'INSERT' OR dpm.permission_name = 'SELECT' OR dpm.permission_name = 'UPDATE' OR dpm.permission_name = 'DELETE' THEN 'DML Access'
        WHEN dpm.permission_name = 'ALTER' OR dpm.permission_name = 'CREATE' OR dpm.permission_name = 'DROP' THEN 'DDL Access'
        ELSE 'Other'
    END AS AccessType
FROM
    sys.database_principals dp
JOIN
    sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
JOIN
    sys.database_principals dp2 ON drm.role_principal_id = dp2.principal_id
JOIN
    sys.database_permissions dpm ON dp.principal_id = dpm.grantee_principal_id
WHERE
    (dpm.permission_name IN ('CONTROL', 'INSERT', 'SELECT', 'UPDATE', 'DELETE', 'ALTER', 'CREATE', 'DROP')
OR dp2.name = 'db_datawriter') -- check for DB_Writer access
    AND dp.type_desc IN ('WINDOWS_GROUP', 'WINDOWS_LOGIN', 'SQL_USER')
ORDER BY
dp.name, AccessType;