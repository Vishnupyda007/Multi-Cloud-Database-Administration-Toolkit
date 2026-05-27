SELECT 
    t.name AS TableName,
    COUNT(c.column_id) AS ColumnCount
FROM 
    sys.tables t
JOIN 
    sys.columns c ON t.object_id = c.object_id
	where t.name in (name)
GROUP BY 
    t.name
ORDER BY 
    ColumnCount DESC;


----------------------------------------


SELECT COUNT(*) AS ColumnCount
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'vw_CentralRepository_SFDC_Opportunity' --AND TABLE_SCHEMA = 'YourSchemaName';
