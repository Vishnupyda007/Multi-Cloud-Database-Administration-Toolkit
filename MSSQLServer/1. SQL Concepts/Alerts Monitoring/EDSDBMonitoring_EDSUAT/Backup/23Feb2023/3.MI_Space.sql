declare @Used_space_threshold int = 85
IF OBJECT_ID(N'tempdb..#MI_Total_space_Usage') IS NOT NULL
BEGIN
DROP TABLE #MI_Total_space_Usage
END
SELECT volume_mount_point, 
  used_gb = cast(min(total_bytes/1024./1024./1024.) as numeric(8,1)), 
  available_gb = cast(min(available_bytes/1024./1024./1024.) as numeric(8,1)), 
  total_gb = cast(min((available_bytes+total_bytes)/1024./1024./1024.) as numeric(8,1))
  into #MI_Total_space_Usage
  FROM sys.master_files AS f CROSS APPLY 
  sys.dm_os_volume_stats(f.database_id, f.file_id)
group by volume_mount_point

select *,cast((used_gb/total_gb)*100 as numeric(8,1)) [Used_Space_GB_%],cast((available_gb/total_gb)*100 as numeric(8,1)) [Available_Space_GB_%],1 [Table_Status],getdate() Date_Collection from #MI_Total_space_Usage where cast((used_gb/total_gb)*100 as numeric(8,1))>@Used_space_threshold

