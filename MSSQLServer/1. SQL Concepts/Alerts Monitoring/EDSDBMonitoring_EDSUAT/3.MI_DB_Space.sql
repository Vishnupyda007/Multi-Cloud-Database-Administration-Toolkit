DROP TABLE IF EXISTS #DBFileFreeSpace;

CREATE TABLE #DBFileFreeSpace
(
    dbName NVARCHAR(128), 
    dbFileName NVARCHAR(128), 
    dbFileDesc NVARCHAR(128),
    CurrentSizeGB DECIMAL(9,3), 
    FreeSpaceGB DECIMAL(9,3)
);
    

DECLARE @sqlCommand NVARCHAR(2000);
DECLARE @dbName NVARCHAR(2000);
DECLARE @sqlFileSpaceCommand NVARCHAR(2000) = 
					'SELECT DB_NAME() AS dbName, name AS dbFileName, 
							type_desc as dbFileDesc,
							size/128.0 / 1024 AS CurrentSizeGB,  
							size/128.0 / 1024 - (CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 / 1024)  AS FreeSpaceGB
					FROM sys.database_files
					WHERE type IN (0,1);'

DECLARE cdb CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY
	FOR 
		SELECT QUOTENAME(name) FROM sys.databases ORDER BY name;

OPEN cdb;

FETCH NEXT FROM cdb 
	INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sqlCommand = CONCAT('USE ', @dbName, ';', @sqlFileSpaceCommand);
	
	INSERT INTO #DBFileFreeSpace(dbName, dbFileName, dbFileDesc, CurrentSizeGB, FreeSpaceGB)
		EXEC sp_executesql @sqlCommand;
            
    FETCH NEXT FROM cdb 
		INTO @dbName;
END

CLOSE cdb;
DEALLOCATE cdb;



SELECT DB_NAME(database_id) as DatabaseName, 
	   name as FileName,
	   type_desc as FileType,
	   CAST(size * 8. / 1024 / 1024  AS DECIMAL(9,3)) as FileSizeGB, 
	   fs.FreeSpaceGB,
	   CASE WHEN max_size = -1 THEN -1 ELSE CAST(max_size * 8. / 1024 / 1024 AS decimal(9,0)) END as FileMaxSizeGB,
	   CASE WHEN mf.is_percent_growth = 1 THEN growth ELSE 0 END as PercentGrowth,
	   CASE WHEN growth = 0 OR mf.is_percent_growth = 1 THEN NULL ELSE CAST(growth * 8. / 1024 / 1024  AS decimal(9,3)) END as FileGrowthGB,
	   CASE WHEN mf.database_id != 2 AND st.ServiceTier = 'GeneralPurpose' 
			THEN st.ReservedStorageGB - st.UsedStorageGB
			ELSE localSpace.LocallyAvailableGB 
	   END as SpaceAvailableGB,1 [Table_Status],getdate() Date_Collection 
	FROM master.sys.master_files mf
	LEFT JOIN #DBFileFreeSpace fs
		ON DB_NAME(mf.database_id) = fs.dbName AND mf.name = fs.dbFileName
	CROSS APPLY( SELECT TOP 1 sku as ServiceTier,
							CAST( reserved_storage_mb / 1024. as DECIMAL(9) ) as ReservedStorageGB, 
							CAST( storage_space_used_mb / 1024. as DECIMAL(9) ) as UsedStorageGB
						FROM [sys].[server_resource_stats] ORDER BY end_time DESC ) as st
	CROSS APPLY( SELECT vs.volume_mount_point as VolumeMountPoint,
						CAST(MIN(available_bytes / 1024. / 1024 / 1024 ) AS NUMERIC(9)) as LocallyAvailableGB
					FROM sys.master_files AS f
						CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id) vs
					WHERE UPPER(vs.volume_mount_point) like 'C:\%' 
					GROUP BY vs.volume_mount_point ) as localSpace
	WHERE type_desc != 'FILESTREAM'
	ORDER BY DB_NAME(database_id), type_desc;