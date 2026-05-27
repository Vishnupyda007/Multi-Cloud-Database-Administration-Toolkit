SELECT
    dp.name AS DatabaseRole,
    dp.type_desc AS RoleType,
    msp.name AS MemberName,
    msp.type_desc AS MemberType
FROM sys.database_role_members drm
JOIN sys.database_principals dp ON drm.role_principal_id = dp.principal_id
JOIN sys.database_principals msp ON drm.member_principal_id = msp.principal_id
WHERE msp.name = '<AAD_User_or_Group_Name>'
ORDER BY dp.name;