USE [CentralRepository] -- Replace with your database name
GO
 
DECLARE @TableName NVARCHAR(128) = 'CentralRepository_HCM_ClusterMapping'; -- Replace with your table name
DECLARE @SchemaName NVARCHAR(128) = 'dbo'; -- Replace with your schema name if different
 
SELECT
    dp.state_desc AS PermissionState,
    dp.permission_name AS PermissionType,
    OBJECT_NAME(dp.major_id) AS ObjectName,
s.name AS SchemaName,
p.name AS PrincipalName,
    p.type_desc AS PrincipalType
FROM
    sys.database_permissions AS dp
JOIN
    sys.objects AS o ON dp.major_id = o.object_id
JOIN
    sys.schemas AS s ON o.schema_id = s.schema_id
JOIN
    sys.database_principals AS p ON dp.grantee_principal_id = p.principal_id
WHERE
o.name = @TableName
AND s.name = @SchemaName
ORDER BY
    PrincipalName,
    PermissionType;
