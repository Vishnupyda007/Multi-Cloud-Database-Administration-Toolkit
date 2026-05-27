USE [msdb]
GO

/****** Object:  Job [EDS_Monitoring]    Script Date: 01-02-2023 10:51:17 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 01-02-2023 10:51:17 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'EDS_Monitoring', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Log_Usage_Collection]    Script Date: 01-02-2023 10:51:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log_Usage_Collection', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'Powershell –file C:\temp\EDS_Alerts\EDS\EDS_monitoring_Base.ps1', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [FailoverGroup_Email]    Script Date: 01-02-2023 10:51:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'FailoverGroup_Email', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'

DECLARE @body_content nvarchar(max);
SET @body_content = N''
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
  <tbody>'' +
CAST(
        (SELECT td = Repli_endpoint_url, '''',
				td = Last_Hardened_Lsn, '''',
				td = Last_Redone_Lsn, '''',
				td = Redo_Queue_Size, '''',
				td = Catchup_Progress, '''',
				td = End_of_log_lsn, '''',
				td = internal_state_desc, '''',
				td = database_state_desc, '''',
				td = partner_database, '''',
				td = ReplicationLag, '''',
				td = displaySeverity, ''''
        FROM [Managed_Instance_Failover_Group_Lag] where table_status=1
        FOR XML PATH(''tr''), TYPE   
        ) AS nvarchar(max)
    ) +
  N''</tbody>
</table>'';

								
IF EXISTS (select top 1 * FROM [Managed_Instance_Failover_Group_Lag] where table_status=1) 
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = ''JBSWIKI'',
                                   @body         = @body_content,
								   @body_format = ''HTML'',
                                   @recipients   = ''vijanak@microsoft.com'',
                                   @subject      = ''ALERT: Failover group replication lag is above accepted threshold''; 
   END
SET NOCOUNT OFF
', 
		@database_name=N'EDSMonitoring', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [MI_Space_Email]    Script Date: 01-02-2023 10:51:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'MI_Space_Email', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'

DECLARE @body_content nvarchar(max);
SET @body_content = N''
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
  <tbody>'' +
CAST(
        (SELECT td = volume_mount_point, '''',
				td = used_gb, '''',
                td = available_gb, '''',
                td = total_gb, '''',
				td = [Used_Space_GB_%], '''',
				td = [Available_Space_GB_%], ''''
        FROM [dbo].[MI_SPACE] where Table_status=1
        FOR XML PATH(''tr''), TYPE   
        ) AS nvarchar(max)
    ) +
  N''</tbody>
</table>'';

DECLARE @body_content1 nvarchar(max);
SET @body_content1 = N''
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
  <tbody>'' +
CAST(
        (SELECT td = DatabaseName, '''',
				td = FileName, '''',
                td = FileType, '''',
                td = FileSizeGB, '''',
				td = FreeSpaceGB, '''',
				td = FileMaxSizeGB, '''',
                td = PercentGrowth, '''',
                td = FileGrowthGB, '''',
				td = SpaceAvailableGB, ''''
        FROM [dbo].[MI_DB_SPACE] where Table_status=1
        FOR XML PATH(''tr''), TYPE   
        ) AS nvarchar(max)
    ) +
  N''</tbody>
</table>'';

DECLARE @body_content2 nvarchar(max);
set @body_content2 = @body_content + @body_content1
IF EXISTS (select top 1 * from [dbo].[MI_SPACE] where Table_status=1) 
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = ''JBSWIKI'',
                                   @body         = @body_content2,
								   @body_format = ''HTML'',
                                   @recipients   = ''vijanak@microsoft.com'',
                                   @subject      = ''ALERT: Storage Space on Azure SQL Managed Instance is Greater than 90%''; 
   END
SET NOCOUNT OFF', 
		@database_name=N'EDSMonitoring', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Log_Used_Email]    Script Date: 01-02-2023 10:51:17 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log_Used_Email', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'

DECLARE @body_content nvarchar(max);
SET @body_content = N''
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
  <tbody>'' +
CAST(
        (SELECT td = [MI], '''',
				td = [DatabaseName], '''',
                td = [Log_Size_in_MB], '''',
                td = [Log_Space_Used_%], '''',
				td = [Log_reuse_wait_desc], ''''
        FROM [dbo].[EDS_Log_Usage] where Table_status=1
        FOR XML PATH(''tr''), TYPE   
        ) AS nvarchar(max)
    ) +
  N''</tbody>
</table>'';


IF EXISTS (select top 1 * from [dbo].[EDS_Log_Usage] where Table_status=1) 
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = ''JBSWIKI'',
                                   @body         = @body_content,
								   @body_format = ''HTML'',
                                   @recipients   = ''vijanak@microsoft.com'',
                                   @subject      = ''ALERT: User Database Log Used % is Greater than 60%''; 
   END
SET NOCOUNT OFF
', 
		@database_name=N'EDSMonitoring', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

