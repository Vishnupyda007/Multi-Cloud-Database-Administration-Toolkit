USE [Monitoring] 
IF OBJECT_ID('dbo.SQLMI_sysjobhistory_TBL_Email','U') IS NOT NULL
DROP TABLE dbo.SQLMI_sysjobhistory_TBL_Email
WAITFOR DELAY '00:00:00'

--WITH LastRun AS (
--    SELECT DISTINCT
--        job_id,
--        MAX(msdb.dbo.agent_datetime(run_date, run_time)) AS LastRunTime
--    FROM 
--        msdb.dbo.sysjobhistory
--    GROUP BY 
--        job_id
--)
SELECT * INTO #T FROM(
SELECT distinct
    @@SERVERNAME as ServerName, 
    j.name AS JobName,
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS LastRun_StartTime,
    DATEADD(SECOND, h.run_duration % 100 + ((h.run_duration / 100) % 100) * 60 + (h.run_duration / 10000) * 3600, 
            msdb.dbo.agent_datetime(h.run_date, h.run_time)) AS LastRun_EndTime,

    CASE
	    when j.enabled =1 then 'Enabled'
		else 'Disabled'
    END AS 'Job_Enable_Status',
    
	CASE 
        WHEN h.run_status <> 1 THEN 'Failed'
        ELSE 'Successful Run'
    END AS Job_LastRun_Status,
	
	CASE 
        WHEN h.run_status <> 1 THEN h.message
        ELSE 'No Error'
    END AS ErrorMessage,
	CAST(cast(js.next_run_date as CHAR(8)) as date) as Next_Run_Date,
	CASE(SS.freq_type)
            WHEN 1  THEN 'Once'
            WHEN 4  THEN 'Daily'
            WHEN 8  THEN (case when (SS.freq_recurrence_factor > 1) then  'Every ' + convert(varchar(3),SS.freq_recurrence_factor) + ' Weeks'  else 'Weekly'  end)
            WHEN 16 THEN (case when (SS.freq_recurrence_factor > 1) then  'Every ' + convert(varchar(3),SS.freq_recurrence_factor) + ' Months' else 'Monthly' end)
            WHEN 32 THEN 'Every ' + convert(varchar(3),SS.freq_recurrence_factor) + ' Months' -- RELATIVE
            WHEN 64 THEN 'SQL Startup'
            WHEN 128 THEN 'SQL Idle'
            ELSE ''
        END AS Frequency,
	 CASE 
	 (freq_subday_type)
            WHEN 1 then   left(stuff((stuff((replicate('0', 6 - len(active_start_time)))+ convert(varchar(6),active_start_time),3,0,':')),6,0,':'),8)
            WHEN 2 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' seconds'
            WHEN 4 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' minutes'
            WHEN 8 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' hours'
            ELSE ''
        END AS [Time]
		
FROM 
    msdb.dbo.sysjobs j
INNER JOIN 
    msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
LEFT JOIN 
    msdb.dbo.sysjobsteps s ON h.job_id = s.job_id AND h.step_id = s.step_id
--INNER JOIN 
--    LastRun lr ON h.job_id = lr.job_id AND msdb.dbo.agent_datetime(h.run_date, h.run_time) = lr.LastRunTime
inner join msdb.dbo.sysjobschedules js on j.job_id = js.job_id
left join msdb.dbo.sysjobschedules SJ on S.job_id = SJ.job_id  
left join msdb.dbo.sysschedules SS on SS.schedule_id = SJ.schedule_id

WHERE 
    j.enabled = 1 -- Only enabled jobs 
	and js.next_run_time <>0 and 
	js.next_run_date<>0 AND h.run_status=0
	--OR s.step_id<>1
	--OR j.name='IndexOptimize - USER_DATABASES' OR j.name<>'1.DBA_Replication_Monitor'
	and j.name in 
	(--'1.DBA_Replication_Monitor'
     --'1.DBA_Replication_Subscriptions_Inactive_Monitor'
'APP_JOB_CentralRepository_Contacts_MIG_Batch_1'
,'APP_JOB_CentralRepository_Contacts_MIG_Batch_3'
,'App_Job_CentralRepository_DependentName_MIG_Batch'
,'App_Job_CentralRepository_Email_Address_MIG_BatchSync_SP'
,'APP_JOB_CentralRepository_PassportDetails_MIG_BATCH_SP'
,'APP_JOB_CentralRepository_Set_ProjectStatus_MIG_Batch'
,'App_Job_Delete_AssociateDetails_Batch_SP'
,'App_JOB_ESA_Allocation_Min_LASTUPDDTTM_Column_Update_SP'
,'App_Job_HCM_FutureDatedScenario_Exec_SP'
,'App_Job_Job_Company_Master_FutureDated_SP'
,'App_Job_RHMS_RoleDetails_MIG_Exec_SP'
,'App_Job_save_CentralRepository_AssociateAddress_MIG_INITIAL_AND_BATCH_SYNCUP'
,'App_Job_Save_CentralRepository_JPMProfileItems_MIG_init'
,'App_Job_Save_CentralRepository_JPMProfileItems_MIG_init_1'
,'APP_JOB_Save_HCM_AssociateEmailAddress_MIG_INIT'
,'APP_JOB_Save_HCM_AssociateMaritalStatus_INIT'
,'App_Job_Save_HCM_AssociateName_EMAIL_FLAG_MIG_INIT'
,'APP_JOB_Save_HCM_AssociateName_MIG_INIT'
,'APP_JOB_Save_HCM_AssociateWorkExp_MIG_INIT'
,'APP_JOB_Save_HCM_PhysicalExamDetails_MIG_INIT'
,'App_Job_Select_AssociateDetails_Missed'
,'App_Job_Select_AssociateDetailsTable_Future_Exec_SP'
,'App_Save_CentralRepository_SelfUpdateContacts_MIG_Batch_IMD_SP'
,'CentralRepository_AssociatePool_MIG_Batch_SP'
,'CentralRepository_AssociatePool_MIG_Batch_SP'
,'DependentName_Future'
,'HCM_FutureDatedScenarioSP'
,'IndexOptimize - USER_DATABASES'
,'Job_Company_Master_FutureDated_SP'
,'save_CentralRepository_AssociateAddress_MIG_FUTURE'
,'save_CentralRepository_AssociateAddress_MIG_STATE_BATCH_UPDATE'
,'Save_CentralRepository_SelfUpdateContacts_MIG_Batch_SP'
,'SP_Execute_SAVE_CentralRepository_RHMS_RoleDetails_MIG')
--ORDER BY ServerName,LastRun_StartTime
)a
IF EXISTS (SELECT 1 FROM #T)
BEGIN
SELECT * INTO Monitoring..SQLMI_sysjobhistory_TBL_Email 
FROM #T
END
DROP TABLE #T
--SELECT distinct * FROM Monitoring..SQLMI_sysjobhistory_TBL_Email 