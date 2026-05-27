Use master
GO
SELECT    name,DEK.*
FROM      sys.databases D
JOIN      sys.dm_database_encryption_keys DEK
ON        DEK.database_id = D.database_id
ORDER BY  name