SELECT DISTINCT
    P.state_desc COLLATE DATABASE_DEFAULT + ' '
    + P.[permission_name] COLLATE DATABASE_DEFAULT + ' TO '
    + R.[name] COLLATE DATABASE_DEFAULT + ';'
FROM sys.server_principals R
    JOIN sys.server_permissions P
        ON R.principal_id = P.grantee_principal_id
WHERE R.type_desc = 'SERVER_ROLE'
    AND R.[name] = 'dbareadonly';
 


----------------------------------------------


SELECT
    spr.name AS ServerRoleName,
    sprm.state_desc AS PermissionState,
    sprm.permission_name AS PermissionName
FROM
    sys.server_principals AS spr
JOIN
    sys.server_permissions AS sprm ON spr.principal_id = sprm.grantee_principal_id
WHERE
    spr.type_desc = 'SERVER_ROLE' -- Filter for server roles
    AND spr.name = 'YourServerRoleName' -- Replace with the name of your server role
ORDER BY
    spr.name, sprm.permission_name;
 