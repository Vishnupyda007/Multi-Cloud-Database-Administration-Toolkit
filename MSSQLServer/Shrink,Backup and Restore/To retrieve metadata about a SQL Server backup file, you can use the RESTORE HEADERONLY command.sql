To retrieve metadata about a SQL Server backup file, you can use the RESTORE HEADERONLY command. This provides detailed information such as backup type, database name, backup start and end times, and more.


------Query-------
RESTORE HEADERONLY 
FROM DISK = 'C:\Backups\YourBackupFile.bak';

