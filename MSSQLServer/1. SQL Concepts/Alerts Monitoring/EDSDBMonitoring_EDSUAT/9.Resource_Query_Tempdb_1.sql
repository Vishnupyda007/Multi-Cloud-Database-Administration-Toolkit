SET NOCOUNT ON
USE tempdb;
declare @Tempdb_size_threshold_in_GB decimal(18,2)=250
IF OBJECT_ID(N'tempdb..#DB_Size') IS NOT NULL
BEGIN
DROP TABLE #DB_Size
END
SELECT @@servername as 'ServerName',db_name() as DBName,[name], file_id, physical_name, [size]/128 AS 
'Total Size in MB', 
[size]/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS 'Available Space In MB', 
CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0 AS 'Used Space In MB', 
(100-((([size]/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0)/([size]/128.0))*100.0)) AS 'percentage Used' INTO #DB_Size
FROM sys.database_files

select convert(decimal(18,2),sum([Total Size in MB])/1024.) as Tempdb_Size from #DB_Size 
GROUP BY ServerName,DBName
HAVING sum([Total Size in MB])/1024. > @Tempdb_size_threshold_in_GB

