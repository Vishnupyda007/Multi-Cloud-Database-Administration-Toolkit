

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
      <th>MI_Instance</th>
	  <th>DatabaseName</th>
      <th>Log_Size_in_MB</th>
      <th>Log_Space_Used_%</th>
      <th>Log_reuse_wait_desc</th>
    </tr>
  </thead>
  <tbody>' +
CAST(
        (SELECT td = [MI], '',
				td = [DatabaseName], '',
                td = [Log_Size_in_MB], '',
                td = [Log_Space_Used_%], '',
				td = [Log_reuse_wait_desc], ''
        FROM [dbo].[EDS_Log_Usage] where Table_status=1
        FOR XML PATH('tr'), TYPE   
        ) AS nvarchar(max)
    ) +
  N'</tbody>
</table>';


IF EXISTS (select top 1 * from [dbo].[EDS_Log_Usage] where Table_status=1) 
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = 'JBSWIKI',
                                   @body         = @body_content,
								   @body_format = 'HTML',
                                   @recipients   = 'edmdba@cognizant.com',
                                   @subject      = 'ALERT: EDS QA User Database Log Used % is Greater than 60%'; 
   END
SET NOCOUNT OFF
