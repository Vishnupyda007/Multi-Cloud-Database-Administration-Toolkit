
-- ==========================================
-- SQL Server ? PostgreSQL 17 DDL Generator (ad-hoc, multi-table)
-- SQL Server 2022+ (uses STRING_AGG; ordered aggs isolated via CROSS APPLY)
-- ==========================================

SET NOCOUNT ON;

DECLARE 
    @Schema         SYSNAME        = 'dbo',   -- NULL = all schemas; e.g., 'dbo'
    @TableList      NVARCHAR(MAX)  = 'SFDC_Financial_Ultimate_Parent_Account_STG_CURR',    -- comma-separated: 'TABLE_A,TABLE_B'; NULL = all tables in @Schema filter
    @CRLF           NVARCHAR(2)    = CHAR(13) + CHAR(10),
    @SepCols        NVARCHAR(10)   = ',' + CHAR(13) + CHAR(10),  -- separator inside CREATE TABLE (...)
    @SepList        NVARCHAR(2)    = ', ',                       -- separator for PK column list
    @UsePgcrypto    BIT            = 1;       -- 1 = gen_random_uuid(); 0 = uuid_generate_v4()

IF OBJECT_ID('tempdb..#T') IS NOT NULL DROP TABLE #T;

;WITH TableFilter AS (
    SELECT t.object_id, s.name AS SchemaName, t.name AS TableName
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE (@Schema IS NULL OR s.name = @Schema)
      AND (
           @TableList IS NULL 
           OR EXISTS (
               SELECT 1 FROM string_split(@TableList, ',') sp
               WHERE LTRIM(RTRIM(sp.value)) = t.name
           )
      )
)
SELECT tf.object_id, tf.SchemaName, tf.TableName
INTO #T
FROM TableFilter tf;

IF NOT EXISTS (SELECT 1 FROM #T)
BEGIN
    RAISERROR('No tables matched the specified filters.', 10, 1);
    RETURN;
END

;WITH Cols AS (
    SELECT 
        t.object_id,
        c.column_id,
        SchemaName = s.name,
        TableName  = t.name,
        ColumnName = c.name,
        DataType   = ty.name,
        c.max_length,
        c.precision,
        c.scale,
        c.is_nullable,
        c.is_identity,
        dc.definition AS DefaultValue,
        ic.seed_value,
        ic.increment_value,
        c.is_computed,
        cc.definition AS ComputedDefinition
    FROM #T tt
    JOIN sys.tables t        ON t.object_id     = tt.object_id
    JOIN sys.schemas s       ON s.schema_id     = t.schema_id
    JOIN sys.columns c       ON c.object_id     = t.object_id
    JOIN sys.types ty        ON ty.user_type_id = c.user_type_id
    LEFT JOIN sys.default_constraints dc 
        ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    LEFT JOIN sys.identity_columns ic 
        ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    LEFT JOIN sys.computed_columns cc 
        ON cc.object_id = c.object_id AND cc.column_id = c.column_id
),
Mapped AS (
    SELECT
        object_id,
        column_id,
        SchemaName,
        TableName,
        ColumnName,
        PostgresType =
            CASE DataType
                WHEN 'int'            THEN 'integer'
                WHEN 'bigint'         THEN 'bigint'
                WHEN 'smallint'       THEN 'smallint'
                WHEN 'tinyint'        THEN 'smallint'                 -- optional: add CHECK 0..255 if you want
                WHEN 'bit'            THEN 'boolean'
                WHEN 'money'          THEN 'numeric(19,4)'
                WHEN 'smallmoney'     THEN 'numeric(10,4)'
                WHEN 'decimal'        THEN 'decimal(' + CAST(ISNULL(precision,18) AS VARCHAR(10)) + ',' + CAST(ISNULL(scale,0) AS VARCHAR(10)) + ')'
                WHEN 'numeric'        THEN 'numeric(' + CAST(ISNULL(precision,18) AS VARCHAR(10)) + ',' + CAST(ISNULL(scale,0) AS VARCHAR(10)) + ')'
                WHEN 'float'          THEN 'double precision'
                WHEN 'real'           THEN 'real'
                WHEN 'datetime'       THEN 'timestamp without time zone'
                WHEN 'datetime2'      THEN 'timestamp without time zone'
                WHEN 'smalldatetime'  THEN 'timestamp without time zone'
                WHEN 'datetimeoffset' THEN 'timestamptz'
                WHEN 'date'           THEN 'date'
                WHEN 'time'           THEN 'time without time zone'
                WHEN 'uniqueidentifier' THEN 'uuid'
                WHEN 'binary'         THEN 'bytea'
                WHEN 'varbinary'      THEN 'bytea'
                WHEN 'image'          THEN 'bytea'
                WHEN 'xml'            THEN 'xml'
                WHEN 'nvarchar'       THEN CASE WHEN max_length = -1 THEN 'text' ELSE 'varchar(' + CAST(max_length/2 AS VARCHAR(10)) + ')' END
                WHEN 'varchar'        THEN CASE WHEN max_length = -1 THEN 'text' ELSE 'varchar(' + CAST(max_length AS VARCHAR(10)) + ')' END
                WHEN 'nchar'          THEN 'char(' + CAST(max_length/2 AS VARCHAR(10)) + ')'
                WHEN 'char'           THEN 'char(' + CAST(max_length AS VARCHAR(10)) + ')'
                WHEN 'text'           THEN 'text'
                WHEN 'ntext'          THEN 'text'
                WHEN 'sql_variant'    THEN 'jsonb'                     -- approximation
                ELSE DataType
            END,
        is_nullable,
        is_identity,
        seed_value,
        increment_value,
        DefaultValue,
        is_computed,
        ComputedDefinition
    FROM Cols
)

SELECT 
    DDL_With_PK =
        'CREATE TABLE ' + QUOTENAME(s.name, '"') + '.' + QUOTENAME(t.name, '"') + ' (' + @CRLF +
        CACols.cols_text +
        CASE WHEN CAPK.pk_text IS NOT NULL THEN @SepCols + CAPK.pk_text ELSE '' END +
        @CRLF + ');',
    PK_Constraint_Text = CAPK.pk_text
FROM #T tt
JOIN sys.tables t  ON t.object_id = tt.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id

-- Columns aggregation per table (isolated ordered aggregate)
CROSS APPLY (
    SELECT cols_text =
        STRING_AGG(
            '  ' + QUOTENAME(M.ColumnName, '"') + ' ' + M.PostgresType +
            CASE WHEN M.is_computed = 1 AND M.ComputedDefinition IS NOT NULL THEN
                 ' GENERATED ALWAYS AS (' + 
                 REPLACE(REPLACE(REPLACE(REPLACE(M.ComputedDefinition,'[',''),']',''),'GETDATE()','now()'),'SYSDATETIME()','now()') + 
                 ') STORED'
                 ELSE '' END +
            CASE WHEN M.is_identity = 1 THEN
                 ' GENERATED BY DEFAULT AS IDENTITY (START WITH ' + CAST(ISNULL(M.seed_value,1) AS VARCHAR(20)) + 
                 ' INCREMENT BY ' + CAST(ISNULL(M.increment_value,1) AS VARCHAR(20)) + ')'
                 ELSE '' END +
            -- DEFAULTs (boolean 0/1 handled first to avoid duplicate DEFAULT)
            CASE 
                WHEN M.PostgresType = 'boolean' 
                     AND M.DefaultValue IS NOT NULL 
                     AND (REPLACE(REPLACE(M.DefaultValue,'(','') ,')','') IN ('0','1'))
                THEN CASE REPLACE(REPLACE(M.DefaultValue,'(','') ,')','')
                        WHEN '1' THEN ' DEFAULT true'
                        WHEN '0' THEN ' DEFAULT false'
                     END
                WHEN M.DefaultValue IS NOT NULL THEN
                     ' DEFAULT ' + 
                     REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(M.DefaultValue,'(','') ,')',''),'N''',''''),'GETDATE()','now()'),
                         CASE WHEN @UsePgcrypto = 1 THEN 'NEWID()' ELSE '__X__' END,
                         CASE WHEN @UsePgcrypto = 1 THEN 'gen_random_uuid()' ELSE 'uuid_generate_v4()' END
                     )
                ELSE '' 
            END +
            CASE WHEN M.is_nullable = 0 THEN ' NOT NULL' ELSE '' END
        , @SepCols) WITHIN GROUP (ORDER BY M.column_id)
    FROM Mapped AS M
    WHERE M.object_id = t.object_id
) AS CACols

-- PK constraint text per table (isolated scope, uses FOR XML for stable ordering)
CROSS APPLY (
    SELECT pk_text =
        CASE WHEN EXISTS (
            SELECT 1 
            FROM sys.key_constraints AS k
            WHERE k.parent_object_id = t.object_id
              AND k.type = 'PK'
        )
        THEN
            (SELECT TOP(1)
                 'CONSTRAINT ' + QUOTENAME(k.name, '"') + ' PRIMARY KEY (' +
                 STUFF((
                     SELECT @SepList + QUOTENAME(c.name, '"')
                     FROM sys.index_columns AS ic
                     JOIN sys.columns AS c
                       ON c.object_id = ic.object_id
                      AND c.column_id = ic.column_id
                     WHERE ic.object_id = k.parent_object_id
                       AND ic.index_id = k.unique_index_id
                     ORDER BY ic.key_ordinal
                     FOR XML PATH(''), TYPE
                 ).value('.', 'nvarchar(max)'), 1, LEN(@SepList), '') + ')'
             FROM sys.key_constraints AS k
             WHERE k.parent_object_id = t.object_id AND k.type = 'PK'
             ORDER BY k.name)
        ELSE NULL END
) AS CAPK

ORDER BY s.name, t.name;

IF OBJECT_ID('tempdb..#T') IS NOT NULL DROP TABLE #T;
