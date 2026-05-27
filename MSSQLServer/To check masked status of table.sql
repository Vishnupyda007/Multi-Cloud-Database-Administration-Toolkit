SELECT
c.name AS ColumnName,
    CASE
        WHEN mc.column_id IS NULL THEN 'Not Masked'
        ELSE 'Masked'
    END AS MaskStatus
FROM
    sys.columns c
LEFT JOIN
    sys.masked_columns mc ON c.object_id = mc.object_id AND c.column_id = mc.column_id
WHERE
    c.object_id = OBJECT_ID('CentralRepository_Associate_Details');