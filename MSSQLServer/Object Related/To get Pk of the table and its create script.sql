DECLARE @SchemaName SYSNAME = 'dbo';

SELECT 
    'ALTER TABLE [' + s.name + '].[' + t.name + '] ADD CONSTRAINT [' + kc.name + '] PRIMARY KEY ' +
    CASE i.type
        WHEN 1 THEN 'CLUSTERED'
        WHEN 2 THEN 'NONCLUSTERED'
        ELSE ''
    END + ' (' +
    STRING_AGG('[' + c.name + '] ASC', ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) +
    ') WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ' +
    'IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, ' +
    'OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]' AS CreatePrimaryKeyScript
FROM 
    sys.key_constraints kc
JOIN 
    sys.tables t ON kc.parent_object_id = t.object_id
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
JOIN 
    sys.indexes i ON kc.unique_index_id = i.index_id AND kc.parent_object_id = i.object_id
JOIN 
    sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN 
    sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE 
    kc.type = 'PK'
    AND s.name = @SchemaName
	and t.name in (
'CentralRepository_Chire_CandidateDocument_EDS'
)
GROUP BY 
    s.name, t.name, kc.name, i.type;


