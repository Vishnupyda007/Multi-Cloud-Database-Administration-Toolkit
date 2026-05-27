use master
go

IF OBJECT_ID('master..Temp_CRS_DB_Roles_Table') IS NOT NULL
    DROP TABLE Temp_CRS_DB_Roles_Table
	

 
IF OBJECT_ID('master..Temp_CRS_Users_Create_Table') IS NOT NULL
    DROP TABLE Temp_CRS_Users_Create_Table

	
 
IF OBJECT_ID('master..Temp_CRS_DB_Index_Create_Details_Table') IS NOT NULL
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
       WHERE [type] IN (''''U'''', ''''S'''', ''''G'''',''''E'''',''''X'''')  AND Name = ''''OneC_2166''''/* windows users, sql users, windows groups */ AND name <> ''''guest'''''')

ELSE IF ((SELECT SUBSTRING(convert(sysname, SERVERPROPERTY(''productversion'')), 1, charindex(''.'',convert(sysname, SERVERPROPERTY(''productversion'')))-1)) IN (9,10))
EXEC (''
INSERT INTO ##tbl_db_principals_statements (stmt, result_order)
       SELECT (''''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '''' + SPACE(1) + '''''''''''''''' + [name] + '''''''''''''''' + '''') BEGIN CREATE USER '''' + SPACE(1) + QUOTENAME([name]) + '''' FOR LOGIN '''' + QUOTENAME(suser_sname([sid])) + '''' WITH DEFAULT_SCHEMA = '''' + QUOTENAME(ISNULL([default_schema_name], ''''dbo'''')) + SPACE(1) + ''''END; '''') AS [-- SQL STATEMENTS --],
                     3.1 AS [-- RESULT ORDER HOLDER --]
       FROM   sys.database_principals AS rm
       WHERE [type] IN (''''U'''', ''''S'''', ''''G'''',''''E'''',''''X'''')  AND Name = ''''OneC_2166''''/* windows users, sql users, windows groups */'')

--SELECT * FROM ##tbl_db_principals_statements
DECLARE 
    @sql VARCHAR(2048)
    ,@sort INT 

DECLARE tmp CURSOR FOR


/*********************************************/
/*********   DB CONTEXT STATEMENT    *********/
/*********************************************/
SELECT ''----**SQL Server Instance : ctsazsimibcapps1.inso1a101c37461fa.database.windows.net**----''AS [-- SQL STATEMENTS --], 0.9 AS [-- RESULT ORDER HOLDER --]
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

use master
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

----------------------------------------------------------
---------------------------------------------------------

use master
go
CREATE TABLE [dbo].[Temp_CRS_DB_Index_Create_Details_Table](
 [DateT] datetime NULL,
 [Servername] [nvarchar](128) NULL,
 [Database_Name] [nvarchar](128) NULL,
 [Index_Details] [nvarchar](max) NULL,
 pointer int
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
SELECT 
    DB_NAME() AS database_name,
    sc.name + N''.'' + t.name AS table_name,
    (SELECT MAX(user_reads) 
        FROM (VALUES (last_user_seek), (last_user_scan), (last_user_lookup)) AS value(user_reads)) AS last_user_read,
    last_user_update,
    CASE si.index_id WHEN 0 THEN N''/* No create statement (Heap) */''
    ELSE 
        CASE is_primary_key WHEN 1 THEN
            N''ALTER TABLE '' + QUOTENAME(sc.name) + N''.'' + QUOTENAME(t.name) + N'' ADD CONSTRAINT '' + QUOTENAME(si.name) + N'' PRIMARY KEY '' +
                CASE WHEN si.index_id > 1 THEN N''NON'' ELSE N'''' END + N''CLUSTERED ''
            ELSE N''CREATE '' + 
                CASE WHEN si.is_unique = 1 then N''UNIQUE '' ELSE N'''' END +
                CASE WHEN si.index_id > 1 THEN N''NON'' ELSE N'''' END + N''CLUSTERED '' +
                N''INDEX '' + QUOTENAME(si.name) + N'' ON '' + QUOTENAME(sc.name) + N''.'' + QUOTENAME(t.name) + N'' ''
        END +
        /* key def */ N''('' + key_definition + N'')'' +
        /* includes */ CASE WHEN include_definition IS NOT NULL THEN 
            N'' INCLUDE ('' + include_definition + N'')''
            ELSE N''''
        END +
        /* filters */ CASE WHEN filter_definition IS NOT NULL THEN 
            N'' WHERE '' + filter_definition ELSE N''''
        END +
        /* with clause - compression goes here */
        CASE WHEN row_compression_partition_list IS NOT NULL OR page_compression_partition_list IS NOT NULL 
            THEN N'' WITH ('' +
                CASE WHEN row_compression_partition_list IS NOT NULL THEN
                    N''DATA_COMPRESSION = ROW '' + CASE WHEN psc.name IS NULL THEN N'''' ELSE + N'' ON PARTITIONS ('' + row_compression_partition_list + N'')'' END
                ELSE N'''' END +
                CASE WHEN row_compression_partition_list IS NOT NULL AND page_compression_partition_list IS NOT NULL THEN N'', '' ELSE N'''' END +
                CASE WHEN page_compression_partition_list IS NOT NULL THEN
                    N''DATA_COMPRESSION = PAGE '' + CASE WHEN psc.name IS NULL THEN N'''' ELSE + N'' ON PARTITIONS ('' + page_compression_partition_list + N'')'' END
                ELSE N'''' END
            + N'')''
            ELSE N''''
        END +
        /* ON where? filegroup? partition scheme? */
        '' ON '' + CASE WHEN psc.name is null 
            THEN ISNULL(QUOTENAME(fg.name),N'''')
            ELSE psc.name + N'' ('' + partitioning_column.column_name + N'')'' 
            END
        + N'';''
    END AS index_create_statement,
    si.index_id,
    si.name AS index_name,
    partition_sums.reserved_in_row_GB,
    partition_sums.reserved_LOB_GB,
    partition_sums.row_count,
    stat.user_seeks,
    stat.user_scans,
    stat.user_lookups,
    user_updates AS queries_that_modified,
    partition_sums.partition_count,
    si.allow_page_locks,
    si.allow_row_locks,
    si.is_hypothetical,
    si.has_filter,
    si.fill_factor,
    si.is_unique,
    ISNULL(pf.name, ''/* Not partitioned */'') AS partition_function,
    ISNULL(psc.name, fg.name) AS partition_scheme_or_filegroup,
    t.create_date AS table_created_date,
    t.modify_date AS table_modify_date into #Temp_CRS_DB_Index_Create_Details_Table
FROM sys.indexes AS si
JOIN sys.tables AS t ON si.object_id=t.object_id
JOIN sys.schemas AS sc ON t.schema_id=sc.schema_id
LEFT JOIN sys.dm_db_index_usage_stats AS stat ON 
    stat.database_id = DB_ID() 
    and si.object_id=stat.object_id 
    and si.index_id=stat.index_id
LEFT JOIN sys.partition_schemes AS psc ON si.data_space_id=psc.data_space_id
LEFT JOIN sys.partition_functions AS pf ON psc.function_id=pf.function_id
LEFT JOIN sys.filegroups AS fg ON si.data_space_id=fg.data_space_id
/* Key list */ OUTER APPLY ( SELECT STUFF (
    (SELECT N'', '' + QUOTENAME(c.name) +
        CASE ic.is_descending_key WHEN 1 then N'' DESC'' ELSE N'''' END
    FROM sys.index_columns AS ic 
    JOIN sys.columns AS c ON 
        ic.column_id=c.column_id  
        and ic.object_id=c.object_id
    WHERE ic.object_id = si.object_id
        and ic.index_id=si.index_id
        and ic.key_ordinal > 0
    ORDER BY ic.key_ordinal FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,2,'''')) AS keys ( key_definition )
/* Partitioning Ordinal */ OUTER APPLY (
    SELECT MAX(QUOTENAME(c.name)) AS column_name
    FROM sys.index_columns AS ic 
    JOIN sys.columns AS c ON 
        ic.column_id=c.column_id  
        and ic.object_id=c.object_id
    WHERE ic.object_id = si.object_id
        and ic.index_id=si.index_id
        and ic.partition_ordinal = 1) AS partitioning_column
/* Include list */ OUTER APPLY ( SELECT STUFF (
    (SELECT N'', '' + QUOTENAME(c.name)
    FROM sys.index_columns AS ic 
    JOIN sys.columns AS c ON 
        ic.column_id=c.column_id  
        and ic.object_id=c.object_id
    WHERE ic.object_id = si.object_id
        and ic.index_id=si.index_id
        and ic.is_included_column = 1
    ORDER BY c.name FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,2,'''')) AS includes ( include_definition )
/* Partitions */ OUTER APPLY ( 
    SELECT 
        COUNT(*) AS partition_count,
        CAST(SUM(ps.in_row_reserved_page_count)*8./1024./1024. AS NUMERIC(32,1)) AS reserved_in_row_GB,
        CAST(SUM(ps.lob_reserved_page_count)*8./1024./1024. AS NUMERIC(32,1)) AS reserved_LOB_GB,
        SUM(ps.row_count) AS row_count
    FROM sys.partitions AS p
    JOIN sys.dm_db_partition_stats AS ps ON
        p.partition_id=ps.partition_id
    WHERE p.object_id = si.object_id
        and p.index_id=si.index_id
    ) AS partition_sums
/* row compression list by partition */ OUTER APPLY ( SELECT STUFF (
    (SELECT N'', '' + CAST(p.partition_number AS VARCHAR(32))
    FROM sys.partitions AS p
    WHERE p.object_id = si.object_id
        and p.index_id=si.index_id
        and p.data_compression = 1
    ORDER BY p.partition_number FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,2,'''')) AS row_compression_clause ( row_compression_partition_list )
/* data compression list by partition */ OUTER APPLY ( SELECT STUFF (
    (SELECT N'', '' + CAST(p.partition_number AS VARCHAR(32))
    FROM sys.partitions AS p
    WHERE p.object_id = si.object_id
        and p.index_id=si.index_id
        and p.data_compression = 2
    ORDER BY p.partition_number FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,2,'''')) AS page_compression_clause ( page_compression_partition_list )
WHERE 
    si.type IN (0,1,2) /* heap, clustered, nonclustered */
ORDER BY table_name, si.index_id
    OPTION (RECOMPILE);

insert into [master].[dbo].[Temp_CRS_DB_Index_Create_Details_Table]
select getdate() DateT, @@Servername as Servername,db_name() as Database_Name,''-- SQL Server Instance : '' + @@servername + CHAR(13) + CHAR(10) +
    ''USE [' + @Database_Name + '];'' + CHAR(13) + CHAR(10) +''IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id = object_id(''''''+table_name+'''''') AND NAME =''''''+index_name+'''''')'' + '' ''+index_create_statement as [Index_Details], 1 as pointer from #Temp_CRS_DB_Index_Create_Details_Table  where index_create_statement like ''CREATE%'' 

drop table #Temp_CRS_DB_Index_Create_Details_Table'
exec(@sql)
   
FETCH NEXT FROM Primary_cursor INTO @Database_Name
END 
CLOSE Primary_cursor  
DEALLOCATE Primary_cursor 


