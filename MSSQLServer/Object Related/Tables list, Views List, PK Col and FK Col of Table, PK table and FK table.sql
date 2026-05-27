--tables list
SELECT * FROM [INFORMATION_SCHEMA].[TABLES]
 
-----views list
SELECT * FROM [INFORMATION_SCHEMA].[VIEWS]
 

----primary key, FK columns in tables
select mm.[name] as 'Table',
pkpk.[pk_name] 'Primary Key',
PKPK.[columns] 'Primary Key Column',
FKFK.FK_NAME 'Foreign Key',
    FKFK.[column] 'Foreign Key Column',
    FKFK.[referenced_table],
    FKFK.[referenced_column]
from sys.tables MM
left join 
(SELECT  obj.name AS FK_NAME,
    sch.name AS [schema_name],
    tab1.name AS [table],
    col1.name AS [column],
    tab2.name AS [referenced_table],
    col2.name AS [referenced_column]
FROM sys.foreign_key_columns fkc
INNER JOIN sys.objects obj
    ON obj.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tab1
    ON tab1.object_id = fkc.parent_object_id
INNER JOIN sys.schemas sch
    ON tab1.schema_id = sch.schema_id
INNER JOIN sys.columns col1
    ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
INNER JOIN sys.tables tab2
    ON tab2.object_id = fkc.referenced_object_id
INNER JOIN sys.columns col2
    ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id) FKFK
on FKFK.[table]=mm.[name]
left join
(select schema_name(tab.schema_id) as [schema_name], 
    tab.[name] as table_name, 
    pk.[name] as pk_name,
    substring(column_names, 1, len(column_names)-1) as [columns]
from sys.tables tab
    left outer join sys.indexes pk
        on tab.object_id = pk.object_id 
        and pk.is_primary_key = 1
   cross apply (select col.[name] + ', '
                    from sys.index_columns ic
                        inner join sys.columns col
                            on ic.object_id = col.object_id
                            and ic.column_id = col.column_id
                    where ic.object_id = tab.object_id
                        and ic.index_id = pk.index_id
                            order by col.column_id
                            for xml path ('') ) D (column_names)) PKPK 
       on PKPK.table_name=mm.[name]
 

---- table,PK col,FK column and its FK reference table
select 
--pkpk.[pk_name] 'Primary Key',
--PKPK.[columns] 'Primary Key Column',
   FKFK.[referenced_table] 'Table',
    FKFK.[referenced_column] 'PrimaryKey',
mm.[name] as 'Referred Table',
--FKFK.FK_NAME 'Foreign Key',
    FKFK.[column] 'Foreign Key Column'
from sys.tables MM
left join 
(SELECT  obj.name AS FK_NAME,
    sch.name AS [schema_name],
    tab1.name AS [table],
    col1.name AS [column],
    tab2.name AS [referenced_table],
    col2.name AS [referenced_column]
FROM sys.foreign_key_columns fkc
INNER JOIN sys.objects obj
    ON obj.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tab1
    ON tab1.object_id = fkc.parent_object_id
INNER JOIN sys.schemas sch
    ON tab1.schema_id = sch.schema_id
INNER JOIN sys.columns col1
    ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id
INNER JOIN sys.tables tab2
    ON tab2.object_id = fkc.referenced_object_id
INNER JOIN sys.columns col2
    ON col2.column_id = referenced_column_id AND col2.object_id = tab2.object_id) FKFK
on FKFK.[table]=mm.[name]
left join
(select schema_name(tab.schema_id) as [schema_name], 
    tab.[name] as table_name, 
    pk.[name] as pk_name,
    substring(column_names, 1, len(column_names)-1) as [columns]
from sys.tables tab
    left outer join sys.indexes pk
        on tab.object_id = pk.object_id 
        and pk.is_primary_key = 1
   cross apply (select col.[name] + ', '
                    from sys.index_columns ic
                        inner join sys.columns col
                            on ic.object_id = col.object_id
                            and ic.column_id = col.column_id
                    where ic.object_id = tab.object_id
                        and ic.index_id = pk.index_id
                            order by col.column_id
                            for xml path ('') ) D (column_names)) PKPK 
       on PKPK.table_name=mm.[name]
 
       where [referenced_table] is not null
       order by [referenced_table] asc
 
