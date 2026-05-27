How to find backupfile properties:
 
• Restore headeronly from disk =’path’ 
It returns a result containing all the backup header information for all backup sets on a backup device. 
It gives backup type (1-full, 2-log, 5-diff), device type, backup size, username, server name, database name.
 
• Restore verifyonly from disk = ‘backup stored path’ 
It verifies the backup but does not restore it. It checks whether the backup set is readable or not from backup device. If output is 0— backup file is invalid or unusable and If output is 1-backup file is valid. 
 
• Restore filelistonly from disk =’path’ file = 3 (by default = 1) 
It gives size in bytes, file logical name, physical name, file type (data-d, log-l) 
 
Useful Commands: 
• Select * from msdb..restorehistory 
Restore-date, destination_dbname, restore_type, recovery, replaces stop-at. 
• Select * from msdb..restorefile 
File number, restore history id, destination physical device, destination physical name 
• Select * from msdb..restorefilegroup 
Restore history_id, filegroup_name