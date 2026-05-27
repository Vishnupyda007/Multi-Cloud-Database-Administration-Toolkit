use tempdb
go

IF OBJECT_ID('tempdb..Temp_CRS_DB_Roles_Table') IS NOT NULL
    DROP TABLE Temp_CRS_DB_Roles_Table
 

 
IF OBJECT_ID('tempdb..Temp_CRS_Users_Create_Table') IS NOT NULL
    DROP TABLE Temp_CRS_Users_Create_Table

 
 
IF OBJECT_ID('tempdb..Temp_CRS_DB_Index_Create_Details_Table') IS NOT NULL
    DROP TABLE Temp_CRS_DB_Index_Create_Details_Table

CREATE TABLE [dbo].[Temp_CRS_DB_Roles_Table](
 [DateT] [datetime] NULL,
 [Servername] [nvarchar](128) NULL,
 [Database_Name] [nvarchar](128) NULL,
 [createrolescript] [nvarchar](max) NULL, 
 [pointer] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

declare @sql nvarchar(max) = ''
declare @Database_Name varchar(200)
DECLARE Primary_cursor CURSOR FOR 
select name from sys.databases where name in ('CentralRepository')
OPEN Primary_cursor  
FETCH NEXT FROM Primary_cursor INTO @Database_Name
WHILE @@FETCH_STATUS = 0  
BEGIN 
   

   set @sql =  'use ['+@Database_Name+']
   
   SET NOCOUNT ON
CREATE TABLE ##tbl_db_principals_statements (stmt varchar(max), result_order decimal(4,1))
IF ((SELECT SUBSTRING(convert(sysname, SERVERPROPERTY(''productversion'')), 1, charindex(''.'',convert(sysname, SERVERPROPERTY(''productversion'')))-1)) > 10)
EXEC (''
INSERT INTO ##tbl_db_principals_statements (stmt, result_order)
       SELECT 
              CASE WHEN rm.authentication_type IN (2, 0) /* 2=contained database user with password, 0 =user without login; create users without logins*/ THEN (''''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '''' + SPACE(1) + '''''''''''''''' + [name] + '''''''''''''''' + '''') BEGIN CREATE USER '''' + SPACE(1) + QUOTENAME([name]) + '''' WITHOUT LOGIN WITH DEFAULT_SCHEMA = '''' + QUOTENAME([default_schema_name]) + SPACE(1) + '''', SID = '''' + CONVERT(varchar(1000), sid) + SPACE(1) + '''' END; '''')
                     ELSE (''''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '''' + SPACE(1) + '''''''''''''''' + [name] + '''''''''''''''' + '''') BEGIN CREATE USER '''' + SPACE(1) + QUOTENAME([name]) + '''' FOR LOGIN '''' + QUOTENAME(suser_sname([sid])) + '''' WITH DEFAULT_SCHEMA = '''' + QUOTENAME(ISNULL([default_schema_name], ''''dbo'''')) + SPACE(1) + ''''END; '''') 
                     END AS [-- SQL STATEMENTS --],
                     3.1 AS [-- RESULT ORDER HOLDER --]
       FROM   sys.database_principals AS rm
       WHERE [type] IN (''''U'''', ''''S'''', ''''G'''',''''E'''',''''X'''')  /* windows users, sql users, windows groups */ AND name <> ''''guest'''''')

ELSE IF ((SELECT SUBSTRING(convert(sysname, SERVERPROPERTY(''productversion'')), 1, charindex(''.'',convert(sysname, SERVERPROPERTY(''productversion'')))-1)) IN (9,10))
EXEC (''
INSERT INTO ##tbl_db_principals_statements (stmt, result_order)
       SELECT (''''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '''' + SPACE(1) + '''''''''''''''' + [name] + '''''''''''''''' + '''') BEGIN CREATE USER '''' + SPACE(1) + QUOTENAME([name]) + '''' FOR LOGIN '''' + QUOTENAME(suser_sname([sid])) + '''' WITH DEFAULT_SCHEMA = '''' + QUOTENAME(ISNULL([default_schema_name], ''''dbo'''')) + SPACE(1) + ''''END; '''') AS [-- SQL STATEMENTS --],
                     3.1 AS [-- RESULT ORDER HOLDER --]
       FROM   sys.database_principals AS rm
       WHERE [type] IN (''''U'''', ''''S'''', ''''G'''',''''E'''',''''X'''') /* windows users, sql users, windows groups */'')

--SELECT * FROM ##tbl_db_principals_statements
DECLARE 
    @sql VARCHAR(2048)
    ,@sort INT 

DECLARE tmp CURSOR FOR


/*********************************************/
/*********   DB CONTEXT STATEMENT    *********/
/*********************************************/
SELECT ''----''+ @@servername + ''----''AS [-- SQL STATEMENTS --], 0.9 AS [-- RESULT ORDER HOLDER --]
UNION

SELECT ''-- [-- DB CONTEXT --] --'' AS [-- SQL STATEMENTS --],
              1 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT ''USE'' + SPACE(1) + QUOTENAME(DB_NAME()) AS [-- SQL STATEMENTS --],
              1.1 AS [-- RESULT ORDER HOLDER --]

UNION

SELECT '''' AS [-- SQL STATEMENTS --],
              2 AS [-- RESULT ORDER HOLDER --]

UNION

/*********************************************/
/*********     DB USER CREATION      *********/
/*********************************************/

       SELECT ''-- [-- DB USERS --] --'' AS [-- SQL STATEMENTS --],
                     3 AS [-- RESULT ORDER HOLDER --]
       UNION

       SELECT 
              [stmt],
                     3.1 AS [-- RESULT ORDER HOLDER --]
       FROM   ##tbl_db_principals_statements
       --WHERE [type] IN (''U'', ''S'', ''G'',''E'',''X'') -- windows users, sql users, windows groups
       WHERE [stmt] IS NOT NULL

UNION


/*********************************************/
/*********    DB ROLE PERMISSIONS    *********/
/*********************************************/
SELECT ''-- [-- DB ROLES --] --'' AS [-- SQL STATEMENTS --],
              5 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT ''EXEC sp_addrolemember @rolename =''
       + SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''''''') + '', @membername ='' + SPACE(1) + QUOTENAME(USER_NAME(rm.member_principal_id), '''''''') AS [-- SQL STATEMENTS --],
              5.1 AS [-- RESULT ORDER HOLDER --]
FROM   sys.database_role_members AS rm
WHERE  USER_NAME(rm.member_principal_id) IN (   
--get user names on the database
SELECT [name]
FROM sys.database_principals
WHERE [principal_id] > 4 -- 0 to 4 are system users/schemas
and [type] IN (''U'', ''S'', ''G'',''E'',''X'') -- S = SQL user, U = Windows user, G = Windows group, E= Externaluser
)
--ORDER BY rm.role_principal_id ASC


UNION

SELECT '''' AS [-- SQL STATEMENTS --],
              7 AS [-- RESULT ORDER HOLDER --]

UNION

/*********************************************/
/*********  OBJECT LEVEL PERMISSIONS *********/
/*********************************************/
SELECT ''-- [-- OBJECT LEVEL PERMISSIONS --] --'' AS [-- SQL STATEMENTS --],
              7.1 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT CASE 
                     WHEN perm.state <> ''W'' THEN perm.state_desc 
                     ELSE ''GRANT''
              END
              + SPACE(1) + perm.permission_name + SPACE(1) + ''ON '' + QUOTENAME(SCHEMA_NAME(obj.schema_id)) + ''.'' + QUOTENAME(obj.name) --select, execute, etc on specific objects
              + CASE
                           WHEN cl.column_id IS NULL THEN SPACE(0)
                           ELSE ''('' + QUOTENAME(cl.name) + '')''
                END
              + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(USER_NAME(usr.principal_id)) COLLATE database_default
              + CASE 
                           WHEN perm.state <> ''W'' THEN SPACE(0)
                           ELSE SPACE(1) + ''WITH GRANT OPTION''
                END
                     AS [-- SQL STATEMENTS --],
              7.2 AS [-- RESULT ORDER HOLDER --]
FROM   
       sys.database_permissions AS perm
              INNER JOIN
       sys.objects AS obj
                     ON perm.major_id = obj.[object_id]
              INNER JOIN
       sys.database_principals AS usr
                     ON perm.grantee_principal_id = usr.principal_id
              LEFT JOIN
       sys.columns AS cl
                     ON cl.column_id = perm.minor_id AND cl.[object_id] = perm.major_id

--ORDER BY perm.permission_name ASC, perm.state_desc ASC


UNION

/*********************************************/
/*********  TYPE LEVEL PERMISSIONS *********/
/*********************************************/
SELECT ''-- [-- TYPE LEVEL PERMISSIONS --] --'' AS [-- SQL STATEMENTS --],
        8 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  CASE 
            WHEN perm.state <> ''W'' THEN perm.state_desc 
            ELSE ''GRANT''
        END
        + SPACE(1) + perm.permission_name + SPACE(1) + ''ON TYPE::'' + QUOTENAME(SCHEMA_NAME(tp.schema_id)) + ''.'' + QUOTENAME(tp.name) --select, execute, etc on specific objects
        + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(USER_NAME(usr.principal_id)) COLLATE database_default
        + CASE 
                WHEN perm.state <> ''W'' THEN SPACE(0)
                ELSE SPACE(1) + ''WITH GRANT OPTION''
          END
            AS [-- SQL STATEMENTS --],
        8.1 AS [-- RESULT ORDER HOLDER --]
FROM    
    sys.database_permissions AS perm
        INNER JOIN
    sys.types AS tp
            ON perm.major_id = tp.user_type_id
        INNER JOIN
    sys.database_principals AS usr
            ON perm.grantee_principal_id = usr.principal_id


UNION

SELECT '''' AS [-- SQL STATEMENTS --],
       9 AS [-- RESULT ORDER HOLDER --]

UNION

/*********************************************/
/*********    DB LEVEL PERMISSIONS   *********/
/*********************************************/
SELECT ''-- [--DB LEVEL PERMISSIONS --] --'' AS [-- SQL STATEMENTS --],
              10 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT CASE 
                     WHEN perm.state <> ''W'' THEN perm.state_desc --W=Grant With Grant Option
                     ELSE ''GRANT''
              END
       + SPACE(1) + perm.permission_name --CONNECT, etc
       + SPACE(1) + ''TO'' + SPACE(1) + ''['' + USER_NAME(usr.principal_id) + '']'' COLLATE database_default --TO <user name>
       + CASE 
                     WHEN perm.state <> ''W'' THEN SPACE(0) 
                     ELSE SPACE(1) + ''WITH GRANT OPTION'' 
         END
              AS [-- SQL STATEMENTS --],
              10.1 AS [-- RESULT ORDER HOLDER --]
FROM   sys.database_permissions AS perm
       INNER JOIN
       sys.database_principals AS usr
       ON perm.grantee_principal_id = usr.principal_id


AND    [perm].[major_id] = 0
       AND [usr].[principal_id] > 4 -- 0 to 4 are system users/schemas
       AND [usr].[type] IN (''U'', ''S'', ''G'',''E'',''X'') -- S = SQL user, U = Windows user, G = Windows group

UNION

SELECT '''' AS [-- SQL STATEMENTS --],
              11 AS [-- RESULT ORDER HOLDER --]

UNION 

SELECT ''-- [--DB LEVEL SCHEMA PERMISSIONS --] --'' AS [-- SQL STATEMENTS --],
              12 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT CASE
                     WHEN perm.state <> ''W'' THEN perm.state_desc --W=Grant With Grant Option
                     ELSE ''GRANT''
                     END
                           + SPACE(1) + perm.permission_name --CONNECT, etc
                           + SPACE(1) + ''ON'' + SPACE(1) + class_desc + ''::'' COLLATE database_default --TO <user name>
                           + QUOTENAME(SCHEMA_NAME(major_id))
                           + SPACE(1) + ''TO'' + SPACE(1) + QUOTENAME(USER_NAME(grantee_principal_id)) COLLATE database_default
                           + CASE
                                  WHEN perm.state <> ''W'' THEN SPACE(0)
                                  ELSE SPACE(1) + ''WITH GRANT OPTION''
                                  END
                     AS [-- SQL STATEMENTS --],
              12.1 AS [-- RESULT ORDER HOLDER --]
from sys.database_permissions AS perm
       inner join sys.schemas s
              on perm.major_id = s.schema_id
       inner join sys.database_principals dbprin
              on perm.grantee_principal_id = dbprin.principal_id
WHERE class = 3 --class 3 = schema


ORDER BY [-- RESULT ORDER HOLDER --]


OPEN tmp
FETCH NEXT FROM tmp INTO @sql, @sort
WHILE @@FETCH_STATUS = 0
BEGIN
        select getdate() Datet, @@servername as Servername, DB_name() DatabaseName,@sql,''1'' as Pointer
        FETCH NEXT FROM tmp INTO @sql, @sort    
END

CLOSE tmp
DEALLOCATE tmp 

DROP TABLE ##tbl_db_principals_statements'

insert into [dbo].[Temp_CRS_DB_Roles_Table]
exec (@sql)
   
FETCH NEXT FROM Primary_cursor INTO @Database_Name
END 
CLOSE Primary_cursor  
DEALLOCATE Primary_cursor 
---------------------------------------------------------------------
---------------------------------------------------------------------

use tempdb
go
CREATE TABLE [dbo].[Temp_CRS_Users_Create_Table](
 [DateT] [datetime] NULL,
 [Servername] [nvarchar](128) NULL,
 [Database_Name] [nvarchar](128) NULL,
 [name] [nvarchar](128) NULL,
 [createscript] [nvarchar](max) NULL, 
 [pointer] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

declare @sql nvarchar(max) = ''
declare @Database_Name varchar(200)
DECLARE Primary_cursor CURSOR FOR 
select name from sys.databases where name in ('CentralRepository')
OPEN Primary_cursor  
FETCH NEXT FROM Primary_cursor INTO @Database_Name
WHILE @@FETCH_STATUS = 0  
BEGIN 

  SET @sql = 'USE [' + @Database_Name + '];
    SELECT GETDATE() AS DateT, @@servername AS Servername, DB_NAME() AS Database_Name, su.name,
    ''-- SQL Server Instance : '' + @@servername + CHAR(13) + CHAR(10) +
    ''USE [' + @Database_Name + '];'' + CHAR(13) + CHAR(10) +
    CASE 
        WHEN (su.issqluser = 1 AND dp.authentication_type_desc = ''None'') THEN ''CREATE USER ['' + su.name + ''] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[dbo];''
        WHEN (su.issqluser = 1 AND dp.authentication_type_desc = ''Instance'' AND dp.sid = l.sid) THEN ''CREATE USER ['' + su.name + ''] FOR LOGIN ['' + l.name + ''] WITH DEFAULT_SCHEMA=[dbo];''
        WHEN (su.issqluser = 0) THEN ''CREATE USER ['' + su.name + ''] FROM EXTERNAL PROVIDER;''
    END AS CreateScript, 1 AS pointer 
    FROM sys.sysusers su 
    JOIN sys.database_principals dp ON su.sid = dp.sid 
    LEFT JOIN sys.syslogins l ON dp.sid = l.sid 
    WHERE su.issqlrole = 0 AND su.hasdbaccess = 1 AND su.name NOT IN (''dbo'') 
    ORDER BY su.name;';

insert into [Temp_CRS_Users_Create_Table]
exec (@sql)
   
FETCH NEXT FROM Primary_cursor INTO @Database_Name
END 
CLOSE Primary_cursor  
DEALLOCATE Primary_cursor 

-----------------------------------------
------------------------------------

use tempdb
go



-- =============================================================================
-- Final Corrected Script to Generate Index Definitions
-- Incorporates all user feedback on formatting and logic.
-- =============================================================================



    CREATE TABLE [dbo].[Temp_CRS_DB_Index_Create_Details_Table](
        [DateT] datetime NULL,
        [Servername] [nvarchar](128) NULL,
        [Database_Name] [nvarchar](128) NULL,
        [Table_Name] [nvarchar](256) NULL,
        [Index_Details] [nvarchar](max) NULL,
        pointer int
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

GO


-- Step 2: Main script execution using a global temporary table for staging.

-- Ensure the staging table is clean before starting.
IF OBJECT_ID('tempdb..##IndexDataStaging') IS NOT NULL
    DROP TABLE ##IndexDataStaging;

-- Create the global temporary table to bridge data between the main script and dynamic SQL.
CREATE TABLE ##IndexDataStaging (
    table_name NVARCHAR(256),
    index_name NVARCHAR(256),
    index_create_statement NVARCHAR(MAX)
);
GO

-- Declare variables for the cursor loop.
DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @Database_Name VARCHAR(200);

-- The cursor iterates through the databases you want to scan.
DECLARE Primary_cursor CURSOR FOR 
SELECT name FROM sys.databases WHERE name IN ('CentralRepository'); -- Target your desired databases here

OPEN Primary_cursor;
FETCH NEXT FROM Primary_cursor INTO @Database_Name;

WHILE @@FETCH_STATUS = 0  
BEGIN 
   
-- This dynamic SQL generates the index script and inserts it into the global temporary table.
SET @sql = 'USE [' + @Database_Name + '];
SET NOCOUNT ON;

INSERT INTO ##IndexDataStaging (table_name, index_name, index_create_statement)
SELECT 
    T.name AS table_name,
    I.name AS index_name,
    '' CREATE '' +
       CASE WHEN I.is_unique = 1 THEN '' UNIQUE '' ELSE '''' END +
       I.type_desc COLLATE DATABASE_DEFAULT + '' INDEX '' + I.name + '' ON '' +
       SCHEMA_NAME(T.schema_id) + ''.'' + T.name + '' ( '' + KeyColumns + '' )  '' +
       ISNULL('' INCLUDE ('' + IncludedColumns + '' ) '', '''') +
       ISNULL('' WHERE  '' + I.filter_definition, '''') + '' WITH ( '' +
       CASE WHEN I.is_padded = 1 THEN '' PAD_INDEX = ON '' ELSE '' PAD_INDEX = OFF '' END + '','' +
       ''FILLFACTOR = '' + CONVERT(CHAR(5), CASE WHEN I.fill_factor = 0 THEN 100 ELSE I.fill_factor END) + '','' +
       ''SORT_IN_TEMPDB = OFF '' + '','' +
       CASE WHEN I.ignore_dup_key = 1 THEN '' IGNORE_DUP_KEY = ON '' ELSE '' IGNORE_DUP_KEY = OFF '' END + '','' +
       CASE WHEN ST.no_recompute = 0 THEN '' STATISTICS_NORECOMPUTE = OFF '' ELSE '' STATISTICS_NORECOMPUTE = ON '' END + '','' +
       '' ONLINE = OFF '' + '','' +
       CASE WHEN I.allow_row_locks = 1 THEN '' ALLOW_ROW_LOCKS = ON '' ELSE '' ALLOW_ROW_LOCKS = OFF '' END + '','' +
       CASE WHEN I.allow_page_locks = 1 THEN '' ALLOW_PAGE_LOCKS = ON '' ELSE '' ALLOW_PAGE_LOCKS = OFF '' END + '' ) ON ['' + DS.name + '']''
FROM   sys.indexes I
       JOIN sys.tables T ON  T.object_id = I.object_id
       JOIN (
                SELECT IC2.object_id, IC2.index_id,
                       STUFF((SELECT '' , '' + C.name + CASE WHEN MAX(CONVERT(INT, IC1.is_descending_key)) = 1 THEN '' DESC '' ELSE '' ASC '' END
                              FROM sys.index_columns IC1 JOIN sys.columns C ON C.object_id = IC1.object_id AND C.column_id = IC1.column_id AND IC1.is_included_column = 0
                              WHERE IC1.object_id = IC2.object_id AND IC1.index_id = IC2.index_id
                              GROUP BY IC1.object_id, C.name, index_id ORDER BY MAX(IC1.key_ordinal) FOR XML PATH('''')), 1, 2, '''') AS KeyColumns
                FROM sys.index_columns IC2 
                GROUP BY IC2.object_id, IC2.index_id
            ) AS tmp4 ON I.object_id = tmp4.object_id AND I.Index_id = tmp4.index_id
       JOIN sys.stats ST ON ST.object_id = I.object_id AND ST.stats_id = I.index_id
       JOIN sys.data_spaces DS ON I.data_space_id = DS.data_space_id
       LEFT JOIN (
                SELECT IC2.object_id, IC2.index_id,
                       STUFF((SELECT '' , '' + C.name
                              FROM sys.index_columns IC1 JOIN sys.columns C ON C.object_id = IC1.object_id AND C.column_id = IC1.column_id AND IC1.is_included_column = 1
                              WHERE IC1.object_id = IC2.object_id AND IC1.index_id = IC2.index_id
                              GROUP BY IC1.object_id, C.name, index_id FOR XML PATH('''')), 1, 2, '''') AS IncludedColumns
                FROM sys.index_columns IC2 
                GROUP BY IC2.object_id, IC2.index_id
            ) AS tmp2 ON tmp2.object_id = I.object_id AND tmp2.index_id = I.index_id
WHERE I.is_primary_key = 0 AND I.is_unique_constraint = 0 AND T.is_ms_shipped = 0;';

    -- Execute the dynamic SQL to populate the global temp table.
    EXEC(@sql);

    -- Now, from the main script, format and insert the data from the staging table into the permanent table.
    INSERT INTO [dbo].[Temp_CRS_DB_Index_Create_Details_Table] (DateT, Servername, Database_Name, Table_Name, Index_Details, pointer)
    SELECT 
        GETDATE() AS DateT,
        @@SERVERNAME AS Servername,
        @Database_Name AS Database_Name,
        table_name,
         -- Added newline after comment
        'USE [' + @Database_name + '];' + CHAR(13) + CHAR(10) +
        'GO' + CHAR(13) + CHAR(10) +
        'IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id = object_id(''' + REPLACE(table_name, '''', '''''') + ''') AND NAME =''' + REPLACE(index_name, '''', '''''') + ''')' + CHAR(13) + CHAR(10) +
        'BEGIN' + CHAR(13) + CHAR(10) +
        '    ' + LTRIM(index_create_statement) + CHAR(13) + CHAR(10) +
        'END;' + CHAR(13) + CHAR(10) +
        'GO'
        AS [Index_Details], 
        1 as pointer 
    FROM ##IndexDataStaging;

    -- Clear the staging table for the next database in the loop.
    TRUNCATE TABLE ##IndexDataStaging;

    FETCH NEXT FROM Primary_cursor INTO @Database_Name;
END;

CLOSE Primary_cursor;
DEALLOCATE Primary_cursor;

-- Clean up the global temporary table at the end of the session.
DROP TABLE ##IndexDataStaging;
GO




