

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
      <th>Volume_mount_point</th>
	  <th>Used_gb</th>
      <th>Available_gb</th>
      <th>Total_gb</th>
      <th>Used_Space_GB_%</th>
	  <th>Available_Space_GB_%</th>
    </tr>
  </thead>
  <tbody>' +
CAST(
        (SELECT td = volume_mount_point, '',
				td = used_gb, '',
                td = available_gb, '',
                td = total_gb, '',
				td = [Used_Space_GB_%], '',
				td = [Available_Space_GB_%], ''
        FROM [dbo].[MI_SPACE] where Table_status=1
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
      <th>DatabaseName</th>
      <th>FileName</th>
	  <th>FileType</th>
	  <th>FileSizeGB</th>
	  <th>FreeSpaceGB</th>
      <th>FileMaxSizeGB</th>
      <th>PercentGrowth</th>
      <th>FileGrowthGB</th>
	  <th>SpaceAvailableGB</th>
    </tr>
  </thead>
  <tbody>' +
CAST(
        (SELECT td = DatabaseName, '',
				td = FileName, '',
                td = FileType, '',
                td = FileSizeGB, '',
				td = FreeSpaceGB, '',
				td = FileMaxSizeGB, '',
                td = PercentGrowth, '',
                td = FileGrowthGB, '',
				td = SpaceAvailableGB, ''
        FROM [dbo].[MI_DB_SPACE] where Table_status=1
        FOR XML PATH('tr'), TYPE   
        ) AS nvarchar(max)
    ) +
  N'</tbody>
</table>';

DECLARE @body_content2 nvarchar(max);
set @body_content2 = @body_content + @body_content1
IF EXISTS (select top 1 * from [dbo].[MI_SPACE] where Table_status=1) 
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = 'JBSWIKI',
                                   @body         = @body_content2,
								   @body_format = 'HTML',
                                   @recipients   = 'vijanak@microsoft.com',
                                   @subject      = 'ALERT: Storage Space on Azure SQL Managed Instance is Greater than 90%'; 
   END
SET NOCOUNT OFF