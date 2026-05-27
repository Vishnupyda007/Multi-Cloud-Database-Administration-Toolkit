SELECT 
    OBJECT_NAME(object_id) AS StoredProcedure,
    definition AS ProcedureDefinition
FROM 
    sys.sql_modules
WHERE 
    definition LIKE '%ObjectName%'

    --OR definition LIKE '%vw_CentralRepository_Associate_Details%'
    --OR definition LIKE '%vw_CentralRepository_Contacts%'
    --OR definition LIKE '%vw_CentralRepository_GSMS_AssociateSeatInfo%'
    --OR definition LIKE '%vw_CentralRepository_Designation%'
    --OR definition LIKE '%vw_CentralRepository_Project%';
