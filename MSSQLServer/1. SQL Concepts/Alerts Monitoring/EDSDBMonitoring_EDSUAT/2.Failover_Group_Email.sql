

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
		<th>Repli_endpoint_url</th>
		<th>Last_Hardened_Lsn</th>
		<th>Last_Redone_Lsn</th>
		<th>Redo_Queue_Size</th>
		<th>Catchup_Progress</th>
		<th>End_of_log_lsn</th>
		<th>internal_state_desc</th>
		<th>database_state_desc</th>
		<th>partner_database</th>
		<th>ReplicationLag</th>
		<th>displaySeverity</th>
    </tr>
  </thead>
  <tbody>' +
CAST(
        (SELECT td = Repli_endpoint_url, '',
				td = Last_Hardened_Lsn, '',
				td = Last_Redone_Lsn, '',
				td = Redo_Queue_Size, '',
				td = Catchup_Progress, '',
				td = End_of_log_lsn, '',
				td = internal_state_desc, '',
				td = database_state_desc, '',
				td = partner_database, '',
				td = ReplicationLag, '',
				td = displaySeverity, ''
        FROM [Managed_Instance_Failover_Group_Lag] where table_status=1
        FOR XML PATH('tr'), TYPE   
        ) AS nvarchar(max)
    ) +
  N'</tbody>
</table>';

								
IF EXISTS (select top 1 * FROM [Managed_Instance_Failover_Group_Lag] where table_status=1) 
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = 'JBSWIKI',
                                   @body         = @body_content,
								   @body_format = 'HTML',
                                   @recipients   = 'vijanak@microsoft.com',
                                   @subject      = 'ALERT: Failover group replication lag is above accepted threshold'; 
   END
SET NOCOUNT OFF
