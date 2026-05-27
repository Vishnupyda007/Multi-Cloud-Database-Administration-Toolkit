SELECT
sp.name AS LoginName,
    sp.type_desc AS LoginType,
    sp.create_date AS CreateDate,
    sp.modify_date AS ModifyDate,
sl.name AS DatabaseName
FROM
    sys.server_principals sp
LEFT JOIN
    sys.server_role_members srm ON sp.principal_id = srm.member_principal_id
LEFT JOIN
    sys.server_principals sl ON srm.role_principal_id = sl.principal_id
WHERE
    sp.type IN ('U', 'S', 'G')  -- 'U' for Windows user, 'S' for SQL user, 'G' for Windows group
ORDER BY
    LoginName, DatabaseName;




----------------------SysAdmin-----------------------------------------

select name,hasaccess from sys.syslogins where sysadmin = '1'





---------------------database_principals-------------------------------

select name FROM sys.database_principals WHERE [type] IN ('X','E')