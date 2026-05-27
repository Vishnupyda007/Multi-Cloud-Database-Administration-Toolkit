------find tables for views
select distinct schema_name(v.schema_id) as schema_name,
       v.name as view_name,
       schema_name(o.schema_id) as referenced_schema_name,
       o.name as referenced_entity_name,
       o.type_desc as entity_type
from sys.views v
join sys.sql_expression_dependencies d
     on d.referencing_id = v.object_id
     and d.referenced_id is not null
join sys.objects o
     on o.object_id = d.referenced_id
	 --where o.name = 'CentralRepository_Allocation'
order by schema_name,
          view_name;




-----------to get view definition as well--------------

SELECT DISTINCT 
    schema_name(v.schema_id) AS schema_name,
    v.name AS view_name,
    schema_name(o.schema_id) AS referenced_schema_name,
    o.name AS referenced_entity_name,
    o.type_desc AS entity_type,
    m.definition AS view_definition
FROM sys.views v
JOIN sys.sql_expression_dependencies d
    ON d.referencing_id = v.object_id
    AND d.referenced_id IS NOT NULL
JOIN sys.objects o
    ON o.object_id = d.referenced_id
JOIN sys.sql_modules m
    ON m.object_id = v.object_id
WHERE v.name = 'vw_CentralRepository_Horizontal_Master'
ORDER BY schema_name,
         view_name;