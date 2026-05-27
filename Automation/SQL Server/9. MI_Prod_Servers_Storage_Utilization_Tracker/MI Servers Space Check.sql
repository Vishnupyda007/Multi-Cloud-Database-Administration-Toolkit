USE [Master]
GO
SELECT TOP 1 resource_name,reserved_storage_mb/1024 as reserved_storage_GB, storage_space_used_mb/1024 as storage_space_used_GB , 
(reserved_storage_mb/1024 - storage_space_used_mb/1024) as Free_Space_GB,  
CAST( (storage_space_used_mb * 100. / reserved_storage_mb) as DECIMAL(9,2)) as [ReservedStoragePercentage]
       FROM master.sys.server_resource_stats
       ORDER BY end_time DESC;


----------- OR- Best query to us --------------


USE [Master]
GO
SELECT TOP 1 @@SERVERNAME as ServerName,reserved_storage_mb/1024/1024 as Total_TB, CAST((storage_space_used_mb/1024/1024) as DECIMAL(9,2)) as Used_TB  , 
cast((reserved_storage_mb/1024 - storage_space_used_mb/1024) as DECIMAL(9,2)) as Available_GB,  
CAST( ((reserved_storage_mb - storage_space_used_mb)/reserved_storage_mb*100) as DECIMAL(9,2)) as [Percent]
       FROM master.sys.server_resource_stats with(nolock)
       ORDER BY end_time DESC;



------------ OR -----------------

select @@SERVERNAME as ServerName,Total_TB =cast(min((total_bytes+available_bytes)/1024./1024/1024/1024) 
as numeric(8,1)),Used_TB =cast(min(total_bytes/1024./1024/1024/1024) as numeric(8,1)),
Available_GB =cast(min(available_bytes/1024./1024/1024) 
as numeric(8,1))from sys.master_files as f cross  apply
sys.dm_os_volume_stats(f.database_id, f.file_id)group by volume_mount_point;