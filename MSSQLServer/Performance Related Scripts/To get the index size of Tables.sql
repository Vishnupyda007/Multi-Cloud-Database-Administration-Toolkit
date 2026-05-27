SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    SUM(sdm.used_page_count) * 8 AS IndexSizeKB,
    SUM(sdm.used_page_count) * 8 / 1024 AS IndexSizeMB,
    SUM(sdm.used_page_count) * 8 / 1024 / 1024 AS IndexSizeGB
FROM 
    sys.indexes AS i
    JOIN sys.tables AS t ON i.object_id = t.object_id
    JOIN sys.schemas AS s ON t.schema_id = s.schema_id
    JOIN sys.dm_db_partition_stats AS sdm ON i.object_id = sdm.object_id AND i.index_id = sdm.index_id
WHERE 
    t.name = 'YourTableName'
GROUP BY 
    s.name, t.name, i.name, i.type_desc
ORDER BY 
    IndexSizeKB DESC;
