

DECLARE @body_content nvarchar(max);
SET @body_content = N'
<style>
table.GeneratedTable {
  width: 100%;
  background-color: #D3D3D3;
  border-collapse: collapse;
  border-width: 2px;
  border-color: #A9A9A9;
  border-style: solid;
  color: #000000;
}

table.GeneratedTable td, table.GeneratedTable th {
  border-width: 2px;
  border-color: #A9A9A9;
  border-style: solid;
  padding: 3px;
}

table.GeneratedTable thead {
  background-color: #A9A9A9;
}
</style>


<table class="GeneratedTable">
  <thead>
    <tr>
      <th>CollectionTime</th>
      <th>Avg_CPU_percent</th>	  
    </tr>
  </thead>
  <tbody>' +
CAST(
        (SELECT td = [EndTime], '',
				td = [Avg_CPU_percent], ''
        FROM [dbo].[CPU_Percent]
        FOR XML PATH('tr'), TYPE   
        ) AS nvarchar(max)
    ) +
  N'</tbody>
</table>';

DECLARE @body_content1 nvarchar(max);
SET @body_content1 = N'
<style>
table.GeneratedTable {
  width: 100%;
  background-color: #D3D3D3;
  border-collapse: collapse;
  border-width: 2px;
  border-color: #A9A9A9;
  border-style: solid;
  color: #000000;
}

table.GeneratedTable td, table.GeneratedTable th {
  border-width: 2px;
  border-color: #A9A9A9;
  border-style: solid;
  padding: 3px;
}

table.GeneratedTable thead {
  background-color: #A9A9A9;
}
</style>

<table class="GeneratedTable">
  <thead>
    <tr>
      <th>[dd hh:mm:ss.mss]</th>
		<th>[start_time]</th>
		<th>[session_id]</th>
		<th>[sql_text]</th>
		<th>a.[Parent Query]</th>
		<th>[status]</th>
		<th>[wait_info]</th>
		<th>[CPU]</th>
		<th>[tempdb_allocations]</th>
		<th>[tempdb_current]</th>
		<th>[reads]</th>
		<th>[writes]</th>
		<th>[host_name]</th>
		<th>[database_name]</th>
		<th>[program_name]</th>
    </tr>
  </thead>
  <tbody>' +
CAST(
        (select 
		td = b.[dd hh:mm:ss.mss], '',
		td = b.[start_time], '',
		td = b.[session_id], '',
		td = convert(varchar(max),b.[sql_text]), '',
		td = a.[Parent Query], '',
		td = b.[status], '',
		td = case 
		WHEN (b.[wait_info] IS NULL) THEN '-'
		ELSE b.[wait_info]
		END, '',
		td = b.[CPU], '',
		td = b.[tempdb_allocations], '',
		td = b.[tempdb_current], '',
		td = b.[reads], '',
		td = b.[writes], '',
		td = b.[host_name], '',
		td = b.[database_name], '',
		td = b.[program_name], ''
		from EDSMonitoring.dbo.What_is_Running a 
		INNER JOIN EDSMonitoring.dbo.whoisactive_cpu b 
		on a.spid=b.session_id 
		and a.program=b.program_name and a.hostname=b.host_name and a.start_time=b.start_time
		and a.[Database]=b.database_name 
		where program NOT IN ('TdService') and a.ecid=0
        FOR XML PATH('tr'), TYPE   
        ) AS nvarchar(max)
    ) +
  N'</tbody>
</table>';

DECLARE @body_content2 nvarchar(max);
set @body_content2 = @body_content + @body_content1
IF EXISTS (select top 1 * from [dbo].[CPU_Percent]) 
   
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBA',
                                   @body         = @body_content2,
								   @body_format = 'HTML',
                                   @recipients   = 'edmdba@cognizant.com',
								   @subject      = 'ALERT: Azure SQL Managed Instance CPU utilization is above 90%'; 
   END
SET NOCOUNT OFF