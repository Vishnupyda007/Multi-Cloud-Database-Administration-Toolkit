-- Replace 'YourStoredProcedureName' with the name of your stored procedure
DECLARE @ProcedureName NVARCHAR(255) = 'Schema.nameofSP';
-- Query to get stored procedure dependencies
SELECT
    OBJECT_NAME(referencing_id) AS DependentObjectName,
    referencing_class_desc AS DependentObjectType,
    referenced_entity_name AS ReferencedObjectName,
    referenced_class_desc AS ReferencedObjectType
FROM
    sys.sql_expression_dependencies
WHERE
    referencing_id = OBJECT_ID(@ProcedureName);