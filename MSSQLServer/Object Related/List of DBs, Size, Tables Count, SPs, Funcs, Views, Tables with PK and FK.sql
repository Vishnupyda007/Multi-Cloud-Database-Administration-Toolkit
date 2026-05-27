-- ============================================
-- 1. LIST OF DATABASES AND THEIR SIZES
-- ============================================
SELECT 
    db.name                                                          AS DatabaseName,
    db.state_desc                                                    AS State,
    db.recovery_model_desc                                           AS RecoveryModel,
    CAST(SUM(mf.size) * 8.0 / 1024 AS DECIMAL(18,2))               AS TotalSizeMB,
    CAST(SUM(mf.size) * 8.0 / 1024 / 1024 AS DECIMAL(18,2))        AS TotalSizeGB
FROM sys.databases db
JOIN sys.master_files mf ON db.database_id = mf.database_id
WHERE db.name NOT IN ('master','tempdb','model','msdb')
GROUP BY db.name, db.state_desc, db.recovery_model_desc
ORDER BY TotalSizeMB DESC;


-- ============================================
-- 2. SCHEMA DETAILS - NUMBER OF TABLES PER SCHEMA
-- ============================================
SELECT 
    DB_NAME()                                                        AS DatabaseName,
    s.name                                                           AS SchemaName,
    COUNT(t.object_id)                                               AS NumberOfTables
FROM sys.schemas s
LEFT JOIN sys.tables t ON t.schema_id = s.schema_id
WHERE s.name NOT IN ('sys','INFORMATION_SCHEMA','guest','db_owner',
                     'db_accessadmin','db_securityadmin','db_ddladmin',
                     'db_backupoperator','db_datareader','db_datawriter',
                     'db_denydatareader','db_denydatawriter')
GROUP BY s.name
ORDER BY s.name;


-- ============================================
-- 3. STORED PROCEDURE DETAILS
-- ============================================
SELECT 
    DB_NAME()                                                        AS DatabaseName,
    s.name                                                           AS SchemaName,
    p.name                                                           AS ProcedureName,
    p.create_date                                                    AS CreatedDate,
    p.modify_date                                                    AS LastModifiedDate,
    CASE p.is_ms_shipped 
        WHEN 1 THEN 'System' ELSE 'User Defined' END                AS ProcedureType
FROM sys.procedures p
JOIN sys.schemas s ON p.schema_id = s.schema_id
WHERE p.is_ms_shipped = 0
ORDER BY s.name, p.name;


-- ============================================
-- 4. USER DEFINED FUNCTIONS
-- ============================================
SELECT 
    DB_NAME()                                                        AS DatabaseName,
    s.name                                                           AS SchemaName,
    o.name                                                           AS FunctionName,
    o.create_date                                                    AS CreatedDate,
    o.modify_date                                                    AS LastModifiedDate,
    CASE o.type 
        WHEN 'FN'  THEN 'Scalar Function'
        WHEN 'IF'  THEN 'Inline Table-valued Function'
        WHEN 'TF'  THEN 'Table-valued Function'
        WHEN 'FS'  THEN 'CLR Scalar Function'
        WHEN 'FT'  THEN 'CLR Table-valued Function'
        ELSE o.type_desc 
    END                                                              AS FunctionType
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('FN','IF','TF','FS','FT')
ORDER BY s.name, o.name;


-- ============================================
-- 5. NON-STANDARD / DEPRECATED DATA TYPES
--    (smalldatetime, ntext, image, text, etc.)
-- ============================================
SELECT 
    DB_NAME()                                                        AS DatabaseName,
    s.name                                                           AS SchemaName,
    t.name                                                           AS TableName,
    c.name                                                           AS ColumnName,
    tp.name                                                          AS DataType,
    c.max_length                                                     AS MaxLength,
    c.is_nullable                                                    AS IsNullable
FROM sys.columns c
JOIN sys.tables t      ON c.object_id  = t.object_id
JOIN sys.schemas s     ON t.schema_id  = s.schema_id
JOIN sys.types tp      ON c.user_type_id = tp.user_type_id
WHERE tp.name IN ('smalldatetime','ntext','text','image',
                  'datetime','real','float','money','smallmoney',
                  'tinyint','sql_variant','xml','hierarchyid')
ORDER BY s.name, t.name, c.name;


-- ============================================
-- 6. VIEWS (EXCLUDING VIEWS WITH 'EDS' IN NAME)
-- ============================================
SELECT 
    DB_NAME()                                                        AS DatabaseName,
    s.name                                                           AS SchemaName,
    v.name                                                           AS ViewName,
    v.create_date                                                    AS CreatedDate,
    v.modify_date                                                    AS LastModifiedDate,
    m.definition                                                     AS ViewDefinition
FROM sys.views v
JOIN sys.schemas s       ON v.schema_id  = s.schema_id
JOIN sys.sql_modules m   ON v.object_id  = m.object_id
WHERE v.name NOT LIKE '%EDS%'
AND v.is_ms_shipped = 0
ORDER BY s.name, v.name;


-- ============================================
-- 7A. TABLE-WISE PRIMARY KEY DEFINITIONS
-- ============================================
SELECT 
    DB_NAME()                                                        AS DatabaseName,
    s.name                                                           AS SchemaName,
    t.name                                                           AS TableName,
    kc.name                                                          AS PrimaryKeyName,
    c.name                                                           AS ColumnName,
    ic.key_ordinal                                                   AS KeyOrdinal,
    CASE ic.is_descending_key 
        WHEN 1 THEN 'DESC' ELSE 'ASC' END                           AS SortOrder,
    i.type_desc                                                      AS IndexType
FROM sys.tables t
JOIN sys.schemas s          ON t.schema_id    = s.schema_id
JOIN sys.indexes i          ON t.object_id    = i.object_id
JOIN sys.key_constraints kc ON i.object_id    = kc.parent_object_id
                            AND i.index_id    = kc.unique_index_id
JOIN sys.index_columns ic   ON i.object_id    = ic.object_id
                            AND i.index_id    = ic.index_id
JOIN sys.columns c          ON ic.object_id   = c.object_id
                            AND ic.column_id  = c.column_id
WHERE kc.type = 'PK'
ORDER BY s.name, t.name, ic.key_ordinal;


-- ============================================
-- 7B. TABLE-WISE FOREIGN KEY DEFINITIONS
-- ============================================
SELECT 
    DB_NAME()                                                        AS DatabaseName,
    s.name                                                           AS SchemaName,
    tp.name                                                          AS ParentTable,
    cp.name                                                          AS ParentColumn,
    fk.name                                                          AS ForeignKeyName,
    sr.name                                                          AS ReferencedSchema,
    tr.name                                                          AS ReferencedTable,
    cr.name                                                          AS ReferencedColumn,
    fk.delete_referential_action_desc                               AS OnDelete,
    fk.update_referential_action_desc                               AS OnUpdate,
    fk.is_disabled                                                   AS IsDisabled
FROM sys.foreign_keys fk
JOIN sys.schemas s              ON fk.schema_id          = s.schema_id
JOIN sys.tables tp              ON fk.parent_object_id   = tp.object_id
JOIN sys.tables tr              ON fk.referenced_object_id = tr.object_id
JOIN sys.schemas sr             ON tr.schema_id          = sr.schema_id
JOIN sys.foreign_key_columns fkc ON fk.object_id         = fkc.constraint_object_id
JOIN sys.columns cp             ON fkc.parent_object_id  = cp.object_id
                                AND fkc.parent_column_id = cp.column_id
JOIN sys.columns cr             ON fkc.referenced_object_id  = cr.object_id
                                AND fkc.referenced_column_id = cr.column_id
ORDER BY s.name, tp.name, fk.name;