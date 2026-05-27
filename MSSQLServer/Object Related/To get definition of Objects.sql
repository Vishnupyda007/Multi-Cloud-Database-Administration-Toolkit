SELECT DISTINCT
CONCAT(
--'IF OBJECT_ID(''',ss.[name],'.',o.[name],''') IS NOT NULL DROP ',
--CASE type WHEN 'V' THEN 'VIEW' 
--WHEN 'IF' THEN 'FUNCTION' WHEN 'FN' THEN 'FUNCTION' WHEN 'P' THEN 'PROCEDURE' END ,' ',ss.[name],'.',o.[name],
--'GO'
--,
replace(replace(replace
(sm.[definition],CHAR(13), ''),
CHAR(10), ''),'',''),
'GO')
FROM sys.objects AS o 
JOIN sys.sql_modules AS sm
    ON o.object_id = sm.object_id  
JOIN sys.schemas AS ss
    ON o.schema_id = ss.schema_id  
 
WHERE 1=1 
--AND o.type = 'V'