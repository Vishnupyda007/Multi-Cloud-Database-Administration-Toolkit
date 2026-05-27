SELECT distinct(volume_mount_point), 
  total_bytes/1048576*0.001 as Size_in_GB, 
  available_bytes/1048576*0.001 as Free_in_GB,
  (select ((available_bytes/1048576* 1.0)/(total_bytes/1048576* 1.0) *100)) as FreePercentage
FROM sys.master_files AS f CROSS APPLY 
   sys.dm_os_volume_stats(f.database_id, f.file_id)
group by volume_mount_point, total_bytes/1048576, 
  available_bytes/1048576 order by 1



------OnPrem Servers Space----------


xp_fixeddrives