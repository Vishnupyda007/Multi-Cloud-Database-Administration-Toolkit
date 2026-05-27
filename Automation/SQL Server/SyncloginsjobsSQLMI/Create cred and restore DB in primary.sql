CREATE CREDENTIAL [https://ctssqlmiprod.blob.core.windows.net/sqlmidbbkp] 
WITH IDENTITY='SHARED ACCESS SIGNATURE' 
, SECRET = 'sp=racwd&st=2024-12-13T06:16:36Z&se=2025-12-13T14:16:36Z&spr=https&sv=2022-11-02&sr=c&sig=T2ZuJWzgAQc7wCDyHAB8CQWbVa5MToCbHONhpUqQtNE%3D'
Restore DATABASE [DBA_Sync_Internal] FROM URL
= N'https://ctssqlmiprod.blob.core.windows.net/sqlmidbbkp/AgentDB_prim.bak' 