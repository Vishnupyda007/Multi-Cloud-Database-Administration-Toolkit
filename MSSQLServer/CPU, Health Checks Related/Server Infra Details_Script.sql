--1
USE [Master]
GO
SELECT TOP 1 reserved_storage_mb/1024 as reserved_storage_GB, storage_space_used_mb/1024 as storage_space_used_GB , CAST( (storage_space_used_mb * 100. / reserved_storage_mb) as DECIMAL(9,2)) as [ReservedStoragePercentage]
       FROM master.sys.server_resource_stats
       ORDER BY end_time DESC;
 
	   --2
USE [Master]
GO
sp_helpdb
 
	   --3
USE [Master]
GO
select name,dbid,size,	maxsize,	growth,	filename,	fileid,	groupid,	status,	perf
from sys.sysaltfiles
 
--4
USE [Master]
GO
select database_id,name,compatibility_level, collation_name from sys.databases
 
 --5 Job Details


--6 index details
USE [CentralRepository]
GO
SELECT T.name ,' CREATE ' +
       CASE 
            WHEN I.is_unique = 1 THEN ' UNIQUE '
            ELSE ''
       END +
       I.type_desc COLLATE DATABASE_DEFAULT + ' INDEX ' +
       I.name + ' ON ' +
       SCHEMA_NAME(T.schema_id) + '.' + T.name + ' ( ' +
       KeyColumns + ' )  ' +
       ISNULL(' INCLUDE (' + IncludedColumns + ' ) ', '') +
       ISNULL(' WHERE  ' + I.filter_definition, '') + ' WITH ( ' +
       CASE 
            WHEN I.is_padded = 1 THEN ' PAD_INDEX = ON '
            ELSE ' PAD_INDEX = OFF '
       END + ',' +
       'FILLFACTOR = ' + CONVERT(
           CHAR(5),
           CASE 
                WHEN I.fill_factor = 0 THEN 100
                ELSE I.fill_factor
           END
       ) + ',' +
       -- default value 
       'SORT_IN_TEMPDB = OFF ' + ',' +
       CASE 
            WHEN I.ignore_dup_key = 1 THEN ' IGNORE_DUP_KEY = ON '
            ELSE ' IGNORE_DUP_KEY = OFF '
       END + ',' +
       CASE 
            WHEN ST.no_recompute = 0 THEN ' STATISTICS_NORECOMPUTE = OFF '
            ELSE ' STATISTICS_NORECOMPUTE = ON '
       END + ',' +
       ' ONLINE = OFF ' + ',' +
       CASE 
            WHEN I.allow_row_locks = 1 THEN ' ALLOW_ROW_LOCKS = ON '
            ELSE ' ALLOW_ROW_LOCKS = OFF '
       END + ',' +
       CASE 
            WHEN I.allow_page_locks = 1 THEN ' ALLOW_PAGE_LOCKS = ON '
            ELSE ' ALLOW_PAGE_LOCKS = OFF '
       END + ' ) ON [' +
       DS.name + ' ] ' +  CHAR(13) + CHAR(10) + ' ' [CreateIndexScript]
FROM   sys.indexes I
       JOIN sys.tables T
            ON  T.object_id = I.object_id
       JOIN sys.sysindexes SI
            ON  I.object_id = SI.id
            AND I.index_id = SI.indid
       JOIN (
                SELECT *
                FROM   (
                           SELECT IC2.object_id,
                                  IC2.index_id,
                                  STUFF(
                                      (
                                          SELECT ' , ' + C.name + CASE 
                                                                       WHEN MAX(CONVERT(INT, IC1.is_descending_key)) 
                                                                            = 1 THEN 
                                                                            ' DESC '
                                                                       ELSE 
                                                                            ' ASC '
                                                                  END
                                          FROM   sys.index_columns IC1
                                                 JOIN sys.columns C
                                                      ON  C.object_id = IC1.object_id
                                                      AND C.column_id = IC1.column_id
                                                      AND IC1.is_included_column = 
                                                          0
                                          WHERE  IC1.object_id = IC2.object_id
                                                 AND IC1.index_id = IC2.index_id
                                          GROUP BY
                                                 IC1.object_id,
                                                 C.name,
                                                 index_id
                                          ORDER BY
                                                 MAX(IC1.key_ordinal) 
                                                 FOR XML PATH('')
                                      ),
                                      1,
                                      2,
                                      ''
                                  ) KeyColumns
                           FROM   sys.index_columns IC2 
                                  --WHERE IC2.Object_id = object_id('Person.Address') --Comment for all tables
                           GROUP BY
                                  IC2.object_id,
                                  IC2.index_id
                       ) tmp3
            )tmp4
            ON  I.object_id = tmp4.object_id
            AND I.Index_id = tmp4.index_id
       JOIN sys.stats ST
            ON  ST.object_id = I.object_id
            AND ST.stats_id = I.index_id
       JOIN sys.data_spaces DS
            ON  I.data_space_id = DS.data_space_id
       JOIN sys.filegroups FG
            ON  I.data_space_id = FG.data_space_id
       LEFT JOIN (
                SELECT *
                FROM   (
                           SELECT IC2.object_id,
                                  IC2.index_id,
                                  STUFF(
                                      (
                                          SELECT ' , ' + C.name
                                          FROM   sys.index_columns IC1
                                                 JOIN sys.columns C
                                                      ON  C.object_id = IC1.object_id
                                                      AND C.column_id = IC1.column_id
                                                      AND IC1.is_included_column = 
                                                          1
                                          WHERE  IC1.object_id = IC2.object_id
                                                 AND IC1.index_id = IC2.index_id
                                          GROUP BY
                                                 IC1.object_id,
                                                 C.name,
                                                 index_id 
                                                 FOR XML PATH('')
                                      ),
                                      1,
                                      2,
                                      ''
                                  ) IncludedColumns
                           FROM   sys.index_columns IC2 
                                  --WHERE IC2.Object_id = object_id('Person.Address') --Comment for all tables
                           GROUP BY
                                  IC2.object_id,
                                  IC2.index_id
                       ) tmp1
                WHERE  IncludedColumns IS NOT NULL
            ) tmp2
            ON  tmp2.object_id = I.object_id
            AND tmp2.index_id = I.index_id
WHERE  I.is_primary_key = 0
       AND I.is_unique_constraint = 0
           --AND I.Object_id = object_id('Person.Address') --Comment for all tables
           --AND I.name = 'IX_Address_PostalCode' --comment for all indexes
 

--7. Replication tables
--Replication master server
USE [CentralRepository]
GO
SELECT 
pub.name AS [Publication],
art.name as [Article],
serv.name as [Subsriber],
sub.dest_db as [DestinationDB]
FROM dbo.syssubscriptions sub
INNER JOIN sys.servers serv
ON serv.server_id = sub.srvid
INNER JOIN dbo.sysarticles art
ON art.artid = sub.artid
INNER JOIN dbo.syspublications pub
ON pub.pubid = art.pubid
where pub.name = 'Pub_sgntm1_sstfd1' and serv.name ='ctsazsimisgntm1.inso13dfbbbfa2150.database.windows.net'--change the publication name as required
--8 Backup
 
 
--9 View List
USE [CentralRepository]
GO
select * from INFORMATION_SCHEMA.TABLES where TABLE_TYPE='view'
 
--9 user details
USE [Master]
GO
DECLARE @DBuser_sql VARCHAR(4000) 
DECLARE @DBuser_table TABLE (DBName VARCHAR(200), UserName VARCHAR(250), LoginType VARCHAR(500), AssociatedRole VARCHAR(200)) 
SET @DBuser_sql='SELECT ''?'' AS DBName,a.name AS Name,a.type_desc AS LoginType,USER_NAME(b.role_principal_id) AS AssociatedRole FROM ?.sys.database_principals a 
LEFT OUTER JOIN ?.sys.database_role_members b ON a.principal_id=b.member_principal_id 
WHERE a.sid NOT IN (0x01,0x00) AND a.sid IS NOT NULL AND a.type NOT IN (''C'') AND a.is_fixed_role <> 1 AND a.name NOT LIKE ''##%'' AND ''?'' NOT IN (''master'',''msdb'',''model'',''tempdb'') ORDER BY Name'
INSERT @DBuser_table 
EXEC sp_MSforeachdb @command1=@dbuser_sql 
SELECT * FROM @DBuser_table ORDER BY DBName
 
-- 10 UATNCCRS
USE [CentralRepository]
GO

SET NOCOUNT ON
GO
/*Prep statements*/
CREATE TABLE ##tbl_db_principals_statements (stmt varchar(max), result_order decimal(4,1))
IF ((SELECT SUBSTRING(convert(sysname, SERVERPROPERTY('productversion')), 1, charindex('.',convert(sysname, SERVERPROPERTY('productversion')))-1)) > 10)
EXEC ('
INSERT INTO ##tbl_db_principals_statements (stmt, result_order)
                SELECT  
                                CASE WHEN rm.authentication_type IN (2, 0) /* 2=contained database user with password, 0 =user without login; create users without logins*/ THEN (''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '' + SPACE(1) + '''''''' + [name] + '''''''' + '') BEGIN CREATE USER '' + SPACE(1) + QUOTENAME([name]) + '' WITHOUT LOGIN WITH DEFAULT_SCHEMA = '' + QUOTENAME([default_schema_name]) + SPACE(1) + '', SID = '' + CONVERT(varchar(1000), sid) + SPACE(1) + '' END; '')
                                                 ELSE (''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '' + SPACE(1) + '''''''' + [name] + '''''''' + '') BEGIN CREATE USER '' + SPACE(1) + QUOTENAME([name]) + '' FOR LOGIN '' + QUOTENAME(suser_sname([sid])) + '' WITH DEFAULT_SCHEMA = '' + QUOTENAME(ISNULL([default_schema_name], ''dbo'')) + SPACE(1) + ''END; '') 
                                                 END AS [-- SQL STATEMENTS --],
                                                 3.1 AS [-- RESULT ORDER HOLDER --]
                FROM   sys.database_principals AS rm
                WHERE [type] IN (''X'',''S'',''G'',''U'') AND name <> ''guest''/* windows users, sql users, windows groups */')
ELSE IF ((SELECT SUBSTRING(convert(sysname, SERVERPROPERTY('productversion')), 1, charindex('.',convert(sysname, SERVERPROPERTY('productversion')))-1)) IN (9,10))
EXEC ('
INSERT INTO ##tbl_db_principals_statements (stmt, result_order)
                SELECT  (''IF NOT EXISTS (SELECT [name] FROM sys.database_principals WHERE [name] = '' + SPACE(1) + '''''''' + [name] + '''''''' + '') BEGIN CREATE USER '' + SPACE(1) + QUOTENAME([name]) + '' FOR LOGIN '' + QUOTENAME(suser_sname([sid])) + '' WITH DEFAULT_SCHEMA = '' + QUOTENAME(ISNULL([default_schema_name], ''dbo'')) + SPACE(1) + ''END; '') AS [-- SQL STATEMENTS --],
                                                 3.1 AS [-- RESULT ORDER HOLDER --]
                FROM   sys.database_principals AS rm
                WHERE [type] IN (''X'',''S'',''G'',''U'') /* windows users, sql users, windows groups */')
--SELECT * FROM ##tbl_db_principals_statements
 
 
DECLARE 
    @sql VARCHAR(2048)
    ,@sort INT 
DECLARE tmp CURSOR FOR
 
/*********************************************/
/*********   DB CONTEXT STATEMENT    *********/
/*********************************************/
SELECT '-- [-- DB CONTEXT --] --' AS [-- SQL STATEMENTS --],
                                1 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  'USE' + SPACE(1) + QUOTENAME(DB_NAME()) AS [-- SQL STATEMENTS --],
                                1.1 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT '' AS [-- SQL STATEMENTS --],
                                2 AS [-- RESULT ORDER HOLDER --]
UNION
/*********************************************/
/*********     DB USER CREATION      *********/
/*********************************************/
                SELECT '-- [-- DB USERS --] --' AS [-- SQL STATEMENTS --],
                                                 3 AS [-- RESULT ORDER HOLDER --]
                UNION
                SELECT  
                                 [stmt],
                                                 3.1 AS [-- RESULT ORDER HOLDER --]
                FROM   ##tbl_db_principals_statements
                --WHERE [type] IN ('U', 'S', 'G') -- windows users, sql users, windows groups
                WHERE [stmt] IS NOT NULL
UNION
/*********************************************/
/*********    MAP ORPHANED USERS     *********/
/*********************************************/
SELECT '-- [-- ORPHANED USERS --] --' AS [-- SQL STATEMENTS --],
                                4 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  'ALTER USER [' + rm.name + '] WITH LOGIN = [' + rm.name + ']',
                                4.1 AS [-- RESULT ORDER HOLDER --]
FROM   sys.database_principals AS rm
Inner JOIN sys.server_principals as sp
ON rm.name = sp.name COLLATE DATABASE_DEFAULT and rm.sid <> sp.sid
WHERE rm.[type] IN ('X','S','G','U') -- windows users, sql users, windows groups
AND rm.name NOT IN ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys', 'MS_DataCollectorInternalUser')
UNION
/*********************************************/
/*********    DB ROLE PERMISSIONS    *********/
/*********************************************/
SELECT '-- [-- DB ROLES --] --' AS [-- SQL STATEMENTS --],
                                5 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  'EXEC sp_addrolemember @rolename ='
                + SPACE(1) + QUOTENAME(USER_NAME(rm.role_principal_id), '''') + ', @membername =' + SPACE(1) + QUOTENAME(USER_NAME(rm.member_principal_id), '''') AS [-- SQL STATEMENTS --],
                                5.1 AS [-- RESULT ORDER HOLDER --]
FROM   sys.database_role_members AS rm
WHERE USER_NAME(rm.member_principal_id) IN (         
                                                                                                                                                                                                 --get user names on the database
                                                                                                                                                                                                 SELECT [name]
                                                                                                                                                                                                 FROM sys.database_principals
                                                                                                                                                                                                 WHERE [principal_id] > 4 -- 0 to 4 are system users/schemas
                                                                                                                                                                                                 and [type] IN ('X','S') -- S = SQL user, U = Windows user, G = Windows group
                                                                                                                                                                                   )
--ORDER BY rm.role_principal_id ASC
 
UNION
SELECT '' AS [-- SQL STATEMENTS --],
                                7 AS [-- RESULT ORDER HOLDER --]
UNION
/*********************************************/
/*********  OBJECT LEVEL PERMISSIONS *********/
/*********************************************/
SELECT '-- [-- OBJECT LEVEL PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
                                7.1 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  CASE 
                                                 WHEN perm.state <> 'W' THEN perm.state_desc 
                                                 ELSE 'GRANT'
                                 END
                                + SPACE(1) + perm.permission_name + SPACE(1) + 'ON ' + QUOTENAME(SCHEMA_NAME(obj.schema_id)) + '.' + QUOTENAME(obj.name) --select, execute, etc on specific objects
                                + CASE
                                                                 WHEN cl.column_id IS NULL THEN SPACE(0)
                                                                 ELSE '(' + QUOTENAME(cl.name) + ')'
                                   END
                                + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USER_NAME(usr.principal_id)) COLLATE database_default
                                + CASE 
                                                                 WHEN perm.state <> 'W' THEN SPACE(0)
                                                                 ELSE SPACE(1) + 'WITH GRANT OPTION'
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
WHERE usr.name NOT IN ( 'Public','guest')
--ORDER BY perm.permission_name ASC, perm.state_desc ASC
 
UNION
/*********************************************/
/*********  TYPE LEVEL PERMISSIONS *********/
/*********************************************/
SELECT '-- [-- TYPE LEVEL PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
        8 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  CASE 
            WHEN perm.state <> 'W' THEN perm.state_desc 
            ELSE 'GRANT'
        END
        + SPACE(1) + perm.permission_name + SPACE(1) + 'ON TYPE::' + QUOTENAME(SCHEMA_NAME(tp.schema_id)) + '.' + QUOTENAME(tp.name) --select, execute, etc on specific objects
        + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USER_NAME(usr.principal_id)) COLLATE database_default
        + CASE 
                WHEN perm.state <> 'W' THEN SPACE(0)
                ELSE SPACE(1) + 'WITH GRANT OPTION'
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
SELECT '' AS [-- SQL STATEMENTS --],
                9 AS [-- RESULT ORDER HOLDER --]
UNION
/*********************************************/
/*********    DB LEVEL PERMISSIONS   *********/
/*********************************************/
SELECT '-- [--DB LEVEL PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
                                10 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  CASE 
                                                 WHEN perm.state <> 'W' THEN perm.state_desc --W=Grant With Grant Option
                                                 ELSE 'GRANT'
                                 END
                + SPACE(1) + perm.permission_name --CONNECT, etc
                + SPACE(1) + 'TO' + SPACE(1) + '[' + USER_NAME(usr.principal_id) + ']' COLLATE database_default --TO <user name>
                + CASE 
                                                 WHEN perm.state <> 'W' THEN SPACE(0) 
                                                 ELSE SPACE(1) + 'WITH GRANT OPTION' 
                  END
                                AS [-- SQL STATEMENTS --],
                                10.1 AS [-- RESULT ORDER HOLDER --]
FROM   sys.database_permissions AS perm
                INNER JOIN
                sys.database_principals AS usr
                ON perm.grantee_principal_id = usr.principal_id
--WHERE              usr.name = @OldUser
WHERE [perm].[major_id] = 0
                AND [usr].[principal_id] > 4 -- 0 to 4 are system users/schemas
                AND [usr].[type] IN ('X','S','U','G') -- S = SQL user, U = Windows user, G = Windows group
UNION
SELECT '' AS [-- SQL STATEMENTS --],
                                11 AS [-- RESULT ORDER HOLDER --]
UNION 
SELECT '-- [--DB LEVEL SCHEMA PERMISSIONS --] --' AS [-- SQL STATEMENTS --],
                                12 AS [-- RESULT ORDER HOLDER --]
UNION
SELECT  CASE
                                                 WHEN perm.state <> 'W' THEN perm.state_desc --W=Grant With Grant Option
                                                 ELSE 'GRANT'
                                                 END
                                                                 + SPACE(1) + perm.permission_name --CONNECT, etc
                                                                 + SPACE(1) + 'ON' + SPACE(1) + class_desc + '::' COLLATE database_default --TO <user name>
                                                                 + QUOTENAME(SCHEMA_NAME(major_id))
                                                                 + SPACE(1) + 'TO' + SPACE(1) + QUOTENAME(USER_NAME(grantee_principal_id)) COLLATE database_default
                                                                 + CASE
                                                                                 WHEN perm.state <> 'W' THEN SPACE(0)
                                                                                 ELSE SPACE(1) + 'WITH GRANT OPTION'
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
        PRINT @sql
        FETCH NEXT FROM tmp INTO @sql, @sort    
END
CLOSE tmp
DEALLOCATE tmp 
DROP TABLE ##tbl_db_principals_statements
 


-- 11 user permissions
SELECT
   u.name as 'User Name',
  p.Permission_name as 'Permission',
  o.name as 'Object Name'
FROM
   sys.database_permissions p
INNER JOIN
   sys.objects o ON p.major_id = o.object_id
INNER JOIN
   sys.database_principals u ON p.grantee_principal_id = u.principal_id
WHERE
   o.type_desc = 'view'

  ------------or-----------------
  select  princ.name
,       princ.type_desc
,       perm.permission_name
,       perm.state_desc
,       perm.class_desc
,       object_name(perm.major_id)
from    sys.database_principals princ
left join
        sys.database_permissions perm
on      perm.grantee_principal_id = princ.principal_id
where princ.name='give user name here'