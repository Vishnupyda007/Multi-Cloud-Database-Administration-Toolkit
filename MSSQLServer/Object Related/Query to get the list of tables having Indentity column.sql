SELECT 
    TableName       = o.name,
    ColumnName      = c.name,
    IdentityCurrent = IDENT_CURRENT( o.name ) ,
    TypeName        = t.name
FROM sys.objects AS o
JOIN sys.columns AS c
    ON c.object_id = o.object_id
    AND c.is_identity = 1
JOIN sys.types AS t
    ON t.system_type_id = c.system_type_id
WHERE o.type = 'U' and c.is_identity = 1 and o.is_ms_shipped = 0;


------OR-----------------


SELECT 
    SCHEMA_NAME(t.schema_id) AS SchemaName,
    t.name AS TableName,
    c.name AS IdentityColumn
FROM sys.tables t
JOIN sys.columns c ON t.object_id = c.object_id
WHERE c.is_identity = 1
AND t.is_ms_shipped = 0 order by t.name;