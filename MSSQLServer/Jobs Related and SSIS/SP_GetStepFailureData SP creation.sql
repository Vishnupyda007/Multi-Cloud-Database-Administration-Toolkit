use msdb
go
ALTER PROCEDURE SP_GetStepFailureData
(
@JobName VARCHAR(250)
)
AS
/*
This procedure gets failure log data for the failed step of a SQL Server Agent job
EXEC pr_GetStepFailureData 'JobName'
Specifically, the "sysjobstepslogs" table, which, if, will store all the logging data for selected steps of a SQL Server Agent job. Here I need to stress that it is the "properly configured " part that changes everything, for this table will be empty by default.

So what I want to do is to set certain (or al of the) steps in a job to write full logging data to , which I will then read out to get the error details

Firstly, configure logging for the steps you wish to keep log data for:

Right-click the job, and select "Properties".
Click "Steps" in the left-hand pane.
Click on the step to edit in the right-hand pane.
Click "Edit" (or simply double-click the step to combine 2 and 3)
Click "Advanced" in the left-hand pane.
Click "Log to table".
Confirm the modifications to the step, and to the Job.

what matters here is the use of two columns:

Log in sysjobstepslogs
Message in sysjobhistory
The former is the dreaded 1024 character truncated data that you can get from the Log File viewer, the latter is the full logging information that will be kept if you have configured a step to "Log to table".

So all this stored procedure does is to join sysjobhistory and sysjobstepslogs, using a left outer join to ensure that it is not only the steps that have Log to Table enabled which are output (though you can be more restrictive if you wish). Then the Log data (or Message data from sysjobhistory if table logging is not enabled) is output.

The stored procedure only outputs data if a step has failed - this is detected by filtering on run_status = 0 in the sysjobhistory table
*/
DECLARE @job_id UNIQUEIDENTIFIER
SELECT @job_id = job_id FROM dbo.sysjobs WHERE [name] = @JobName
SELECT 'Step ' + CAST(JH.step_id AS VARCHAR(3)) + ' of ' + (SELECT CAST(COUNT(*) AS VARCHAR(5)) FROM dbo.sysjobsteps WHERE job_id = @job_id) AS StepFailed,
 CAST(RIGHT(JH.run_date,2) AS CHAR(2)) + '/' + CAST(SUBSTRING(CAST(JH.run_date AS CHAR(8)),5,2) AS CHAR(2)) + '/' + CAST(LEFT(JH.run_date,4) AS CHAR(4)) AS DateRun,
 LEFT(RIGHT('0' + CAST(JH.run_time AS VARCHAR(6)),6),2) + ':' + SUBSTRING(RIGHT('0' + CAST(JH.run_time AS VARCHAR(6)),6),3,2) + ':' + LEFT(RIGHT('0' + CAST(JH.run_time AS VARCHAR(6)),6),2) AS TimeRun,
 JS.step_name, 
 JH.run_duration, 
 CASE
 WHEN JSL.[log] IS NULL THEN JH.[Message]
 ELSE JSL.[log]
 END AS LogOutput
FROM dbo.sysjobsteps JS INNER JOIN dbo.sysjobhistory JH 
 ON JS.job_id = JH.job_id AND JS.step_id = JH.step_id 
 LEFT OUTER JOIN dbo.sysjobstepslogs JSL
 ON JS.step_uid = JSL.step_uid
WHERE INSTANCE_ID >
 (SELECT MIN(INSTANCE_ID)
 FROM (
 SELECT top (2) INSTANCE_ID, job_id
 FROM dbo.sysjobhistory
 WHERE job_id = @job_id
 AND STEP_ID = 0
 ORDER BY INSTANCE_ID desc
 ) A
 )
 AND JS.step_id <> 0 
 AND JH.job_id = @job_id
 AND JH.run_status = 0 --or JH.run_status=1
ORDER BY JS.step_id ASC