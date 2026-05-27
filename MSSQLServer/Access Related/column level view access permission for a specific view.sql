

DECLARE @ViewName NVARCHAR(200) = 'vw_CentralRepository_SFDC_Opportunity';

SELECT
    princ.name AS LoginName,
    obj.name AS ViewName,
    CASE
        WHEN perm.minor_id = 0 THEN 'Full Access'
        ELSE col.name
    END AS ColumnAccess
FROM sys.database_permissions perm
INNER JOIN sys.database_principals princ ON perm.grantee_principal_id = princ.principal_id
INNER JOIN sys.objects obj ON perm.major_id = obj.object_id
LEFT JOIN sys.columns col ON col.object_id = obj.object_id AND col.column_id = perm.minor_id
WHERE obj.type_desc = 'VIEW'
  AND obj.name = @ViewName
  AND perm.permission_name = 'SELECT'
  AND perm.state_desc = 'GRANT'
  AND NOT EXISTS (
        SELECT 1
        FROM sys.database_permissions d
        WHERE d.major_id = obj.object_id
          AND d.grantee_principal_id = princ.principal_id
          AND d.permission_name = 'SELECT'
          AND d.state_desc = 'DENY'
    )
ORDER BY princ.name, ColumnAccess;