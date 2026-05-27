SELECT TOP 5
    @@SERVERNAME AS PublisherServerName,
    S.name AS SchemaName,
    O.name AS TableName,
    COUNT(*) AS TotalLogRecords,
    -- Breakdown of DML Operation types
    COUNT(CASE WHEN L.[Operation] = 'LOP_INSERT_ROWS' THEN 1 END) AS InsertCount,
    COUNT(CASE WHEN L.[Operation] IN ('LOP_MODIFY_ROW', 'LOP_MODIFY_COLUMNS') THEN 1 END) AS UpdateCount,
    COUNT(CASE WHEN L.[Operation] = 'LOP_DELETE_ROWS' THEN 1 END) AS DeleteCount,
	getdate() as CapturedDate
FROM
    fn_dblog(NULL, NULL) AS L 
LEFT JOIN
    sys.allocation_units AS AU with(nolock) ON L.AllocUnitId = AU.allocation_unit_id
LEFT JOIN
    sys.partitions AS P with(nolock) ON AU.container_id = P.hobt_id
LEFT JOIN
    sys.objects AS O with(nolock) ON P.object_id = O.object_id
LEFT JOIN
    sys.schemas AS S with(nolock) ON O.schema_id = S.schema_id
WHERE
    AU.type_desc = 'IN_ROW_DATA'
    AND O.is_ms_shipped = 0
    AND O.name IS NOT NULL
    AND L.[Operation] IN ('LOP_INSERT_ROWS', 'LOP_DELETE_ROWS', 'LOP_MODIFY_ROW', 'LOP_MODIFY_COLUMNS')
GROUP BY
    S.name,
    O.name
ORDER BY
    TotalLogRecords DESC;

