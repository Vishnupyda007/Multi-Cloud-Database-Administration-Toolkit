DECLARE @ObjectName NVARCHAR(128) = 'SFDC_Account_STG_CURR'; -- Replace with your object name
DECLARE @ObjectSchema NVARCHAR(128) = 'dbo'; -- Replace with your object schema

SELECT 
    referencing_schema_name = OBJECT_SCHEMA_NAME(referencing_id),
    referencing_object_name = OBJECT_NAME(referencing_id),
    referencing_object_type_desc = o.type_desc
FROM 
    sys.dm_sql_referencing_entities(@ObjectSchema + '.' + @ObjectName, 'OBJECT') d
    JOIN sys.objects o ON d.referencing_id = o.object_id;


------------------to get for next levels of the view of a table -------

DECLARE @ObjectName NVARCHAR(128) = 'SFDC_Account_STG_CURR'; -- Replace with your object name
DECLARE @ObjectSchema NVARCHAR(128) = 'dbo'; -- Replace with your object schema
 
SELECT 
    referencing_schema_name = OBJECT_SCHEMA_NAME(referencing_id),
    referencing_object_name = OBJECT_NAME(referencing_id),
    referencing_object_type_desc = o.type_desc,
    referenced_schema_name = referenced_schema_name,
    referenced_object_name = referenced_entity_name,
    referenced_object_type_desc = ro.type_desc
FROM 
    sys.sql_expression_dependencies d
    JOIN sys.objects o ON d.referencing_id = o.object_id
    JOIN sys.objects ro ON d.referenced_id = ro.object_id
where referenced_entity_name in ('ObjectName','ViewName') --to get next levels of the referenced object

--WHERE 
--    referenced_entity_name = @ObjectName
--    AND referenced_schema_name = @ObjectSchema; -- to get the first level of the referenced object which is direct use