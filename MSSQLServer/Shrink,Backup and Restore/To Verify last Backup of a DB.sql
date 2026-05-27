
SELECT 
    d.name AS DatabaseName,
    MAX(b.backup_finish_date) AS LastBackupDate,
    b.type AS BackupType,
    CASE b.type
        WHEN 'D' THEN 'Full'
        WHEN 'I' THEN 'Differential'
        WHEN 'L' THEN 'Log'
        ELSE 'Other'
    END AS BackupTypeDescription,
    b.backup_size / 1024 / 1024 AS BackupSizeMB,

    -- Destination classification based on device_type
    CASE MAX(m.device_type)
        WHEN 2   THEN 'Disk'
        WHEN 5   THEN 'Tape'
        WHEN 7   THEN 'Virtual device (VSS/VDI)'
        WHEN 9   THEN 'Azure Storage (Blob URL)'
        WHEN 105 THEN 'Permanent backup device'
        ELSE 'Unknown'
    END AS BackupDestination,

    -- Location: path or URL (may be NULL for MI automated backups)
    MAX(m.physical_device_name) AS BackupLocation
FROM msdb.dbo.backupset AS b
INNER JOIN msdb.dbo.backupmediafamily AS m
    ON b.media_set_id = m.media_set_id
INNER JOIN sys.databases AS d
    ON b.database_name = d.name
WHERE b.database_name = 'Onec_spay'
and b.type = 'D'
GROUP BY d.name, b.type, b.backup_size
ORDER BY LastBackupDate DESC;


