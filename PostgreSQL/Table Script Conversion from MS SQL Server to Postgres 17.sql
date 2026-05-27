
SET NOCOUNT ON;

DECLARE 
    @Schema SYSNAME = 'dbo',
    @Table  SYSNAME = 'SFDC_Financial_Ultimate_Parent_Account_STG_CURR',
    @CRLF   NVARCHAR(2) = CHAR(13) + CHAR(10),
    @SepCols NVARCHAR(10) = ',' + CHAR(13) + CHAR(10),  -- separator for CREATE TABLE body
    @SepList NVARCHAR(2)  = ', ',                       -- separator for PK column list
    @UsePgcrypto BIT = 1;  -- 1 = gen_random_uuid(), 0 = uuid_generate_v4()

IF OBJECT_ID(@Schema + '.' + @Table) IS NULL
BEGIN
    RAISERROR('Table not found: %s.%s', 16, 1, @Schema, @Table);
    RETURN;
END

-- Build PK text in a variable (no APPLY required)
DECLARE @PkText NVARCHAR(MAX) = NULL;

IF EXISTS (
    SELECT 1 
    FROM sys.key_constraints AS k
    WHERE k.parent_object_id = OBJECT_ID(@Schema + '.' + @Table)
      AND k.type = 'PK'
)
BEGIN
    DECLARE @PkName SYSNAME;
    SELECT TOP(1) @PkName = k.name
    FROM sys.key_constraints AS k
    WHERE k.parent_object_id = OBJECT_ID(@Schema + '.' + @Table)
      AND k.type = 'PK';

    DECLARE @PkCols NVARCHAR(MAX) =
        STUFF((
            SELECT @SepList + QUOTENAME(c.name, '"')
            FROM sys.index_columns AS ic
            JOIN sys.columns AS c
              ON c.object_id = ic.object_id
             AND c.column_id = ic.column_id
            WHERE ic.object_id = OBJECT_ID(@Schema + '.' + @Table)
              AND ic.index_id = (
                  SELECT k.unique_index_id
                  FROM sys.key_constraints AS k
                  WHERE k.parent_object_id = OBJECT_ID(@Schema + '.' + @Table)
                    AND k.type = 'PK'
              )
            ORDER BY ic.key_ordinal
            FOR XML PATH(''), TYPE
        ).value('.', 'nvarchar(max)'), 1, LEN(@SepList), '');

    SET @PkText = 'CONSTRAINT ' + QUOTENAME(@PkName, '"') + ' PRIMARY KEY (' + ISNULL(@PkCols, '') + ')';
END

;WITH Cols AS (
    SELECT 
        c.column_id, c.name AS ColumnName, t.name AS DataType,
        c.max_length, c.precision, c.scale, c.is_nullable, c.is_identity,
        dc.definition AS DefaultValue, ic.seed_value, ic.increment_value,
        c.is_computed, cc.definition AS ComputedDefinition
    FROM sys.columns c
    JOIN sys.types t ON c.user_type_id = t.user_type_id
    LEFT JOIN sys.default_constraints dc 
        ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    LEFT JOIN sys.identity_columns ic 
        ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    LEFT JOIN sys.computed_columns cc 
        ON cc.object_id = c.object_id AND cc.column_id = c.column_id
    WHERE c.object_id = OBJECT_ID(@Schema + '.' + @Table)
),
Mapped AS (
    SELECT *,
        CASE DataType
            WHEN 'int' THEN 'integer'
            WHEN 'bigint' THEN 'bigint'
            WHEN 'smallint' THEN 'smallint'
            WHEN 'tinyint' THEN 'smallint'
            WHEN 'bit' THEN 'boolean'
            WHEN 'money' THEN 'numeric(19,4)'
            WHEN 'smallmoney' THEN 'numeric(10,4)'
            WHEN 'decimal' THEN 'decimal(' + CAST(ISNULL(precision,18) AS VARCHAR(10)) + ',' + CAST(ISNULL(scale,0) AS VARCHAR(10)) + ')'
            WHEN 'numeric' THEN 'numeric(' + CAST(ISNULL(precision,18) AS VARCHAR(10)) + ',' + CAST(ISNULL(scale,0) AS VARCHAR(10)) + ')'
            WHEN 'float' THEN 'double precision'
            WHEN 'real' THEN 'real'
            WHEN 'datetime' THEN 'timestamp without time zone'
            WHEN 'datetime2' THEN 'timestamp without time zone'
            WHEN 'smalldatetime' THEN 'timestamp without time zone'
            WHEN 'datetimeoffset' THEN 'timestamptz'
            WHEN 'date' THEN 'date'
            WHEN 'time' THEN 'time without time zone'
            WHEN 'uniqueidentifier' THEN 'uuid'
            WHEN 'binary' THEN 'bytea'
            WHEN 'varbinary' THEN 'bytea'
            WHEN 'image' THEN 'bytea'
            WHEN 'xml' THEN 'xml'
            WHEN 'nvarchar' THEN CASE WHEN max_length = -1 THEN 'text' ELSE 'varchar(' + CAST(max_length/2 AS VARCHAR(10)) + ')' END
            WHEN 'varchar' THEN CASE WHEN max_length = -1 THEN 'text' ELSE 'varchar(' + CAST(max_length AS VARCHAR(10)) + ')' END
            WHEN 'nchar' THEN 'char(' + CAST(max_length/2 AS VARCHAR(10)) + ')'
            WHEN 'char' THEN 'char(' + CAST(max_length AS VARCHAR(10)) + ')'
            WHEN 'text' THEN 'text'
            WHEN 'ntext' THEN 'text'
            ELSE DataType
        END AS PostgresType
    FROM Cols
)
SELECT 
    -- Full CREATE TABLE with PK included
    DDL_With_PK =
        'CREATE TABLE ' + QUOTENAME(@Schema, '"') + '.' + QUOTENAME(@Table, '"') + ' (' + @CRLF +
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
            CASE WHEN M.DefaultValue IS NOT NULL THEN
                 ' DEFAULT ' + 
                 REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(M.DefaultValue,'(','') ,')',''),'N''',''''),'GETDATE()','now()'),
                     CASE WHEN @UsePgcrypto = 1 THEN 'NEWID()' ELSE '__X__' END,
                     CASE WHEN @UsePgcrypto = 1 THEN 'gen_random_uuid()' ELSE 'uuid_generate_v4()' END
                 )
                 ELSE '' END +
            CASE WHEN M.PostgresType = 'boolean' AND M.DefaultValue IS NOT NULL 
                      AND (REPLACE(REPLACE(M.DefaultValue,'(','') ,')','') IN ('0','1'))
                 THEN CASE REPLACE(REPLACE(M.DefaultValue,'(','') ,')','')
                         WHEN '1' THEN ' DEFAULT true' WHEN '0' THEN ' DEFAULT false' END
                 ELSE '' END +
            CASE WHEN M.is_nullable = 0 THEN ' NOT NULL' ELSE '' END
        , @SepCols) WITHIN GROUP (ORDER BY M.column_id)
        + CASE WHEN @PkText IS NOT NULL THEN @SepCols + @PkText ELSE '' END
        + @CRLF + ');',

    -- PK as plain text (separate column)
    PK_Constraint_Text = @PkText

FROM Mapped AS M;
