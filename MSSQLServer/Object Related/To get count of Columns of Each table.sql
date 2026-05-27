
SELECT 
    t.name AS TableName,
    COUNT(c.column_id) AS ColumnCount
FROM 
    sys.tables AS t
INNER JOIN 
    sys.columns AS c ON t.object_id = c.object_id
where t.name='CentralRepository_EAM_Current_bal_MIG'
GROUP BY 
    t.name
ORDER BY 
    ColumnCount DESC;
