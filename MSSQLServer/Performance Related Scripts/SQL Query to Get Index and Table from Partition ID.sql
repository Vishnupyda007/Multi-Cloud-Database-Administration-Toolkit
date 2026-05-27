SQL Query to Get Index and Table from Partition ID:
SELECT 
    OBJECT_NAME(p.object_id) AS TableName,
    i.name AS IndexName,
    p.partition_id,
    p.index_id
FROM 
    sys.partitions p
JOIN 
    sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
WHERE 
    p.partition_id = 72057595913240576;  -- Replace with your actual partition ID