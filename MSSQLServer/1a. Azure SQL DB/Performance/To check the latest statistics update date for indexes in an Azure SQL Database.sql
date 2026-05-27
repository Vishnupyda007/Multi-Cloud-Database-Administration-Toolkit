SELECT
    OBJECT_NAME(s.[object_id]) AS TableName,
    i.name AS IndexName,
    s.name AS StatsName,
    STATS_DATE(s.[object_id], s.stats_id) AS LastUpdated
FROM 
    sys.stats AS s
JOIN 
    sys.objects AS o ON s.object_id = o.object_id
LEFT JOIN 
    sys.indexes AS i ON s.object_id = i.object_id AND s.name = i.name
WHERE 
    o.type = 'U'  -- Only user tables
ORDER BY 
    LastUpdated DESC;



