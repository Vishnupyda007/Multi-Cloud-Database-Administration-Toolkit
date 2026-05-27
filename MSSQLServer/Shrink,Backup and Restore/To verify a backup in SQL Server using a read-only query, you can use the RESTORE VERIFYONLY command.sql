To verify a backup in SQL Server using a read-only query, you can use the RESTORE VERIFYONLY command. This command checks whether a backup file is readable and complete, but does not restore the database.

------Query------

RESTORE VERIFYONLY 
FROM DISK = 'C:\Backups\YourBackupFile.bak';




--------------

DECLARE @BackupFiles TABLE (BackupPath NVARCHAR(260));

-- Add your backup file paths here
INSERT INTO @BackupFiles (BackupPath)
VALUES 
    (N'C:\Backups\Backup1.bak'),
    (N'C:\Backups\Backup2.bak'),
    (N'C:\Backups\Backup3.bak');

DECLARE @BackupPath NVARCHAR(260);
DECLARE @SQL NVARCHAR(MAX);

DECLARE BackupCursor CURSOR FOR
SELECT BackupPath FROM @BackupFiles;

OPEN BackupCursor;
FETCH NEXT FROM BackupCursor INTO @BackupPath;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'RESTORE VERIFYONLY FROM DISK = N''' + @BackupPath + ''';';
    PRINT 'Verifying: ' + @BackupPath;
    EXEC sp_executesql @SQL;

    FETCH NEXT FROM BackupCursor INTO @BackupPath;
END

CLOSE BackupCursor;
DEALLOCATE BackupCursor;
