SELECT 'use '+QUOTENAME(name)+ ' exec sp_changedbowner @loginame =''crsdba''' as 'Execute_Script',
 
suser_sname(owner_sid) 'DB_Owner' FROM sys.databases AS d WHERE d.database_id>4  and name not in ('distribution');