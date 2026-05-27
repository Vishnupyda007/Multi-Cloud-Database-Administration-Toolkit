-- ============================================
-- TABLES WITH BOTH PK AND FK DEFINITIONS
-- ACROSS ALL USER DATABASES
-- ============================================

CREATE TABLE #PKFKDetails
(
    DatabaseName        NVARCHAR(128),
    SchemaName          NVARCHAR(128),
    TableName           NVARCHAR(128),
    PrimaryKeyName      NVARCHAR(128),
    PKColumn            NVARCHAR(128),
    PKOrdinal           TINYINT,
    PKSortOrder         NVARCHAR(10),
    PKIndexType         NVARCHAR(60),
    ForeignKeyName      NVARCHAR(128),
    FKColumn            NVARCHAR(128),
    ParentSchemaName    NVARCHAR(128),
    ParentTableName     NVARCHAR(128),
    ParentColumn        NVARCHAR(128),
    OnDelete            NVARCHAR(60),
    OnUpdate            NVARCHAR(60),
    IsFKDisabled        BIT
);

DECLARE @dbname NVARCHAR(128);
DECLARE @sql    NVARCHAR(MAX);

DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases
WHERE name NOT IN ('master','tempdb','model','msdb')
AND state_desc = 'ONLINE';

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbname;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    INSERT INTO #PKFKDetails
    SELECT DISTINCT
        ''' + @dbname + '''                                 AS DatabaseName,
        s.name                                              AS SchemaName,
        t.name                                              AS TableName,
        kc.name                                             AS PrimaryKeyName,
        pkc.name                                            AS PKColumn,
        ic.key_ordinal                                      AS PKOrdinal,
        CASE ic.is_descending_key 
            WHEN 1 THEN ''DESC'' ELSE ''ASC'' END           AS PKSortOrder,
        i.type_desc                                         AS PKIndexType,
        fk.name                                             AS ForeignKeyName,
        fkcp.name                                           AS FKColumn,
        sr.name                                             AS ParentSchemaName,
        tr.name                                             AS ParentTableName,
        fkcr.name                                           AS ParentColumn,
        fk.delete_referential_action_desc                   AS OnDelete,
        fk.update_referential_action_desc                   AS OnUpdate,
        fk.is_disabled                                      AS IsFKDisabled

    FROM [' + @dbname + '].sys.tables t
    JOIN [' + @dbname + '].sys.schemas s              ON t.schema_id              = s.schema_id
    JOIN [' + @dbname + '].sys.indexes i              ON t.object_id              = i.object_id
                                                      AND i.is_primary_key        = 1
    JOIN [' + @dbname + '].sys.key_constraints kc     ON i.object_id              = kc.parent_object_id
                                                      AND i.index_id              = kc.unique_index_id
    JOIN [' + @dbname + '].sys.index_columns ic       ON i.object_id              = ic.object_id
                                                      AND i.index_id              = ic.index_id
    JOIN [' + @dbname + '].sys.columns pkc            ON ic.object_id             = pkc.object_id
                                                      AND ic.column_id            = pkc.column_id
    JOIN [' + @dbname + '].sys.foreign_keys fk        ON t.object_id              = fk.parent_object_id
    JOIN [' + @dbname + '].sys.foreign_key_columns fkc ON fk.object_id            = fkc.constraint_object_id
    JOIN [' + @dbname + '].sys.columns fkcp           ON fkc.parent_object_id     = fkcp.object_id
                                                      AND fkc.parent_column_id    = fkcp.column_id
    JOIN [' + @dbname + '].sys.tables tr              ON fk.referenced_object_id  = tr.object_id
    JOIN [' + @dbname + '].sys.schemas sr             ON tr.schema_id             = sr.schema_id
    JOIN [' + @dbname + '].sys.columns fkcr           ON fkc.referenced_object_id = fkcr.object_id
                                                      AND fkc.referenced_column_id= fkcr.column_id
    WHERE t.is_ms_shipped = 0';

    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @dbname;
END;

CLOSE db_cursor;
DEALLOCATE db_cursor;

SELECT
    DatabaseName,
    SchemaName,
    TableName,
    PrimaryKeyName,
    PKColumn,
    PKOrdinal        AS PKColumnOrder,
    PKSortOrder,
    PKIndexType,
    ForeignKeyName,
    FKColumn,
    ParentSchemaName,
    ParentTableName,
    ParentColumn,
    OnDelete,
    OnUpdate,
    IsFKDisabled
FROM #PKFKDetails
ORDER BY 
    DatabaseName, 
    SchemaName, 
    TableName, 
    PrimaryKeyName, 
    PKOrdinal,
    ForeignKeyName;

DROP TABLE #PKFKDetails;