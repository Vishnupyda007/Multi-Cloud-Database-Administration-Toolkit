USE [msdb]
GO

/****** Object:  Job [EDS_Monitoring_UAT]    Script Date: 11/27/2024 2:41:07 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 11/27/2024 2:41:07 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'EDS_Monitoring_UAT', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'CTS\946572', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Log_Usage_Collection]    Script Date: 11/27/2024 2:41:07 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log_Usage_Collection', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=10, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'Powershell –file D:\EDSDBMonitoring_EDSUAT\EDS_monitoring_Base.ps1', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [FailoverGroup_Email]    Script Date: 11/27/2024 2:41:07 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'FailoverGroup_Email', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=10, 
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
      EXEC msdb.dbo.sp_send_dbmail @profile_name = ''DBA'',
                                   @body         = @body_content,
								   @body_format = ''HTML'',
                                   @recipients   = ''edmdba@cognizant.com'',
                                   @subject      = ''ALERT:EDSUAT Failover group replication lag is below accepted threshold''; 
   END
SET NOCOUNT OFF
', 
		@database_name=N'EDSUATMonitoring', 
		@output_file_name=N'D:\EDSUAT_Job_Status', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [MI_Space_Email]    Script Date: 11/27/2024 2:41:07 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'MI_Space_Email', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=10, 
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
      EXEC msdb.dbo.sp_send_dbmail @profile_name = ''DBA'',
                                   @body         = @body_content2,
								   @body_format = ''HTML'',
                                   @recipients   = ''edmdba@cognizant.com'',
                                   @subject      = ''ALERT: EDS UAT Storage Space on Azure SQL MI is Greater than 90%''; 
   END
SET NOCOUNT OFF', 
		@database_name=N'EDSUATMonitoring', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Log_Used_Email]    Script Date: 11/27/2024 2:41:07 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log_Used_Email', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=10, 
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
      EXEC msdb.dbo.sp_send_dbmail @profile_name = ''DBA'',
                                   @body         = @body_content,
								   @body_format = ''HTML'',
                                   @recipients   = ''edmdba@cognizant.com'',
                                   @subject      = ''ALERT: EDS UAT User Database Log Used % is Greater than 60%''; 
   END
SET NOCOUNT OFF
', 
		@database_name=N'EDSUATMonitoring', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [CPU_Costly_Queries]    Script Date: 11/27/2024 2:41:07 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'CPU_Costly_Queries', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=10, 
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
      <th>CollectionTime</th>
      <th>Avg_CPU_percent</th>	  
    </tr>
  </thead>
  <tbody>'' +
CAST(
        (SELECT td = [EndTime], '''',
				td = [Avg_CPU_percent], ''''
        FROM [dbo].[CPU_Percent]
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
  <tbody>'' +
CAST(
        (select 
		td = b.[dd hh:mm:ss.mss], '''',
		td = b.[start_time], '''',
		td = b.[session_id], '''',
		td = convert(varchar(max),b.[sql_text]), '''',
		td = a.[Parent Query], '''',
		td = b.[status], '''',
		td = case 
		WHEN (b.[wait_info] IS NULL) THEN ''-''
		ELSE b.[wait_info]
		END, '''',
		td = b.[CPU], '''',
		td = b.[tempdb_allocations], '''',
		td = b.[tempdb_current], '''',
		td = b.[reads], '''',
		td = b.[writes], '''',
		td = b.[host_name], '''',
		td = b.[database_name], '''',
		td = b.[program_name], ''''
		from EDSMonitoring.dbo.What_is_Running a 
		INNER JOIN EDSMonitoring.dbo.whoisactive_cpu b 
		on a.spid=b.session_id 
		and a.program=b.program_name and a.hostname=b.host_name and a.start_time=b.start_time
		and a.[Database]=b.database_name 
		where program NOT IN (''TdService'') and a.ecid=0
        FOR XML PATH(''tr''), TYPE   
        ) AS nvarchar(max)
    ) +
  N''</tbody>
</table>'';

DECLARE @body_content2 nvarchar(max);
set @body_content2 = @body_content + @body_content1
IF EXISTS (select top 1 * from [dbo].[CPU_Percent]) 
   
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = ''DBA'',
                                   @body         = @body_content2,
								   @body_format = ''HTML'',
                                   @recipients   = ''edmdba@cognizant.com'',
								   @subject      = ''ALERT: EDS UAT Azure SQL MI CPU utilization is above 90%''; 
   END
SET NOCOUNT OFF', 
		@database_name=N'EDSUATMonitoring', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Memory_Reads_Queries]    Script Date: 11/27/2024 2:41:07 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Memory_Reads_Queries', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=10, 
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
      <th>CollectionTime</th>
      <th>Avg_Memory_percent</th>	  
    </tr>
  </thead>
  <tbody>'' +
CAST(
        (SELECT td = [EndTime], '''',
				td = [Avg_Memory_percent], ''''
        FROM [dbo].[Memory_Percent]
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
      <th>[dd hh:mm:ss.mss]</th>
		<th>[start_time]</th>
		<th>[session_id]</th>
		<th>[sql_text]</th>
		<th>a.[Parent Query]</th>
		<th>[status]</th>
		<th>[wait_info]</th>
		<th>[Logical Reads]</th>
		<th>[tempdb_allocations]</th>
		<th>[tempdb_current]</th>
		<th>[reads]</th>
		<th>[writes]</th>
		<th>[host_name]</th>
		<th>[database_name]</th>
		<th>[program_name]</th>
    </tr>
  </thead>
  <tbody>'' +
CAST(
        (select 
		td = b.[dd hh:mm:ss.mss], '''',
		td = b.[start_time], '''',
		td = b.[session_id], '''',
		td = convert(varchar(max),b.[sql_text]), '''',
		td = a.[Parent Query], '''',
		td = b.[status], '''',
		td = case 
		WHEN (b.[wait_info] IS NULL) THEN ''-''
		ELSE b.[wait_info]
		END, '''',
		td = b.[Reads], '''',
		td = b.[tempdb_allocations], '''',
		td = b.[tempdb_current], '''',
		td = b.[reads], '''',
		td = b.[writes], '''',
		td = b.[host_name], '''',
		td = b.[database_name], '''',
		td = b.[program_name], ''''
		from EDSMonitoring.dbo.[What_is_Running_Memory] a 
		INNER JOIN EDSMonitoring.dbo.whoisactive_Memory b 
		on a.spid=b.session_id 
		and a.program=b.program_name and a.hostname=b.host_name and a.start_time=b.start_time
		and a.[Database]=b.database_name 
		where program NOT IN (''TdService'') and a.ecid=0
        FOR XML PATH(''tr''), TYPE   
        ) AS nvarchar(max)
    ) +
  N''</tbody>
</table>'';

DECLARE @body_content2 nvarchar(max);
set @body_content2 = @body_content + @body_content1
IF EXISTS (select top 1 * from [dbo].[Memory_Percent]) 
  
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = ''DBA'',
                                   @body         = @body_content2,
								   @body_format = ''HTML'',
                                   @recipients   = ''edmdba@cognizant.com'',
								   @subject      = ''ALERT: EDS UAT Azure SQL MI Memory utilization is above 98%''; 
   END
SET NOCOUNT OFF', 
		@database_name=N'EDSUATMonitoring', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [IO_Costly_Queries]    Script Date: 11/27/2024 2:41:07 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'IO_Costly_Queries', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=10, 
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
      <th>CollectionTime</th>
      <th>Avg_Data_IO_percent</th>	  
	  <th>Avg_Log_Write_percent</th>
    </tr>
  </thead>
  <tbody>'' +
CAST(
        (SELECT td = [EndTime], '''',
				td = [Avg_Data_IO_percent], '''',
				td = [Avg_Log_Write_percent], ''''
        FROM [dbo].[IO_Percent]
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
      <th>[dd hh:mm:ss.mss]</th>
		<th>[start_time]</th>
		<th>[session_id]</th>
		<th>[sql_text]</th>
		<th>a.[Parent Query]</th>
		<th>[status]</th>
		<th>[wait_info]</th>
		<th>[Physical IO]</th>
		<th>[Logical Reads]</th>
		<th>[tempdb_allocations]</th>
		<th>[tempdb_current]</th>
		<th>[writes]</th>
		<th>[host_name]</th>
		<th>[database_name]</th>
		<th>[program_name]</th>
    </tr>
  </thead>
  <tbody>'' +
CAST(
        (select 
		td = b.[dd hh:mm:ss.mss], '''',
		td = b.[start_time], '''',
		td = b.[session_id], '''',
		td = convert(varchar(max),b.[sql_text]), '''',
		td = a.[Parent Query], '''',
		td = b.[status], '''',
		td = case 
		WHEN (b.[wait_info] IS NULL) THEN ''-''
		ELSE b.[wait_info]
		END, '''',
		td = a.physical_io, '''',
		td = b.[Reads], '''',
		td = b.[tempdb_allocations], '''',
		td = b.[tempdb_current], '''',
		td = b.[writes], '''',
		td = b.[host_name], '''',
		td = b.[database_name], '''',
		td = b.[program_name], ''''
		from EDSMonitoring.dbo.[What_is_Running_IO] a 
		INNER JOIN EDSMonitoring.dbo.whoisactive_IO b 
		on a.spid=b.session_id 
		and a.program=b.program_name and a.hostname=b.host_name and a.start_time=b.start_time
		and a.[Database]=b.database_name 
		where program NOT IN (''TdService'') and a.ecid=0
        FOR XML PATH(''tr''), TYPE   
        ) AS nvarchar(max)
    ) +
  N''</tbody>
</table>'';

DECLARE @body_content2 nvarchar(max);
set @body_content2 = @body_content + @body_content1
IF EXISTS (select top 1 * from [dbo].[IO_Percent]) 
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = ''DBA'',
                                   @body         = @body_content2,
								   @body_format = ''HTML'',
                                   @recipients   = ''edmdba@cognizant.com'',
								   @subject      = ''ALERT: EDS UAT Azure SQL Managed Instance IO or Log Write utilization is above 90%''; 
   END
SET NOCOUNT OFF', 
		@database_name=N'EDSUATMonitoring', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Tempdb_Costly_Queries]    Script Date: 11/27/2024 2:41:07 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Tempdb_Costly_Queries', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=10, 
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
      <th>Tempdb Size</th>
    </tr>
  </thead>
  <tbody>'' +
CAST(
        (SELECT td = [DBSize], ''''				
        FROM [dbo].DB_Size_Tempdb
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
      <th>[dd hh:mm:ss.mss]</th>
		<th>[start_time]</th>
		<th>[session_id]</th>
		<th>[sql_text]</th>
		<th>a.[Parent Query]</th>
		<th>[status]</th>
		<th>[wait_info]</th>
		<th>[Physical IO]</th>
		<th>[Logical Reads]</th>
		<th>[tempdb_allocations]</th>
		<th>[tempdb_current]</th>
		<th>[writes]</th>
		<th>[login_Name]</th>
		<th>[host_name]</th>
		<th>[database_name]</th>
		<th>[program_name]</th>
    </tr>
  </thead>
  <tbody>'' +
CAST(
        (select 
		td = b.[dd hh:mm:ss.mss], '''',
		td = b.[start_time], '''',
		td = b.[session_id], '''',
		td = convert(varchar(max),b.[sql_text]), '''',
		td = a.[Parent Query], '''',
		td = b.[status], '''',
		td = case 
		WHEN (b.[wait_info] IS NULL) THEN ''-''
		ELSE b.[wait_info]
		END, '''',
		td = a.physical_io, '''',
		td = b.[Reads], '''',
		td = b.[tempdb_allocations], '''',
		td = b.[tempdb_current], '''',
		td = b.[writes], '''',
		td = b.[login_name], '''',
		td = b.[host_name], '''',
		td = b.[database_name], '''',
		td = b.[program_name], ''''
		from EDSMonitoring.dbo.[What_is_Running_tempdb] a 
		INNER JOIN EDSMonitoring.dbo.whoisactive_tempdb b 
		on a.spid=b.session_id 
		and a.program=b.program_name and a.hostname=b.host_name and a.start_time=b.start_time
		and a.[Database]=b.database_name 
		where program NOT IN (''TdService'') and a.ecid=0
        FOR XML PATH(''tr''), TYPE   
        ) AS nvarchar(max)
    ) +
  N''</tbody>
</table>'';

DECLARE @body_content2 nvarchar(max);
set @body_content2 = @body_content + @body_content1
IF EXISTS (select top 1 * from [dbo].[DB_Size_Tempdb]) 
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = ''DBA'',
                                   @body         = @body_content2,
								   @body_format = ''HTML'',
								   @recipients   = ''edmdba@cognizant.com'',
                                   @subject      = ''ALERT: EDS UAT Azure SQL Managed Instance TempDB is above 250 GB''; 
   END
SET NOCOUNT OFF', 
		@database_name=N'EDSUATMonitoring', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Replication_Checks]    Script Date: 11/27/2024 2:41:07 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Replication_Checks', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=4, 
		@on_fail_step_id=10, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @body_content nvarchar(max);
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
</style>''

--<table class="GeneratedTable">
--  <thead>
--    <tr>
--      <th>Tempdb Size</th>
--    </tr>
--  </thead>
--  <tbody>'' +
--CAST(
--        (SELECT td = [DBSize], ''''				
--        FROM [dbo].DB_Size_Tempdb
--        FOR XML PATH(''tr''), TYPE   
--        ) AS nvarchar(max)
--    ) +
--  N''</tbody>
--</table>'';

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
	<th>DTTIME</th>
      <th>PublisherServer</th>
		<th>PublisherDatabase</th>
		<th>SubscriberServer</th>
		<th>SubscriberDatabase</th>
		<th>ReplicationType</th>
		<th>ReplicationStatus</th>
		<th>LogReaderAgentState</th>
		<th>ReplicationLatency</th>
		<th>LastSync</th>		
    </tr>
  </thead>
  <tbody>'' +
CAST(
        (
		select 
		td = DTTIME, '''',
		td = PublisherServer, '''',
		td = PublisherDatabase, '''',
		td = SubscriberServer, '''',
		td = SubscriberDatabase, '''',
		td = ReplicationType, '''',
		td = ReplicationStatus, '''',
		td = LogReaderAgentState, '''',
		td = ISNULL(ReplicationLatency,0) , '''',
		td = LastSync, ''''		
		from [ctsinazuatedssqlmi01.inso13dfbbbfa2150.database.windows.net].Monitoring.dbo.EDS_Replication_Monitor 
        FOR XML PATH(''tr''), TYPE   
        ) AS nvarchar(max)
    ) +
  N''</tbody>
</table>'';

DECLARE @body_content2 nvarchar(max);
set @body_content2 = @body_content + @body_content1
IF EXISTS (select top 1 * from [ctsinazuatedssqlmi01.inso13dfbbbfa2150.database.windows.net].Monitoring.dbo.EDS_Replication_Monitor ) 
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = ''DBA'',
                                   @body         = @body_content2,
								   @body_format = ''HTML'',
								   @recipients   = ''edmdba@cognizant.com'',
                                   @subject      = ''ALERT: EDS UAT Azure SQL Managed Instance Replication Issues''; 
   END
SET NOCOUNT OFF', 
		@database_name=N'EDSUATMonitoring', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Failure Notification]    Script Date: 11/27/2024 2:41:07 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Failure Notification', 
		@step_id=10, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC msdb.dbo.sp_send_dbmail @profile_name = ''DBA'',
                                   @body         = ''EDS Monitoring Job Failed on Server CTSC01290748301'',
								   @body_format = ''HTML'',
                                   @recipients   = ''edmdba@cognizant.com'',
                                   @subject      = ''ALERT: EDS UAT EDS Monitoring Job Failed on Server CTSC01290748301''; ', 
		@database_name=N'EDSUATMonitoring', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Monitoring_Job_Schedule', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20240929, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'f04347c6-c983-4629-87de-33edf1c9cab5'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


