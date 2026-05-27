SELECT  sj.name ,
        sjs.command
FROM    msdb.dbo.sysjobs sj
        JOIN msdb.dbo.sysjobsteps sjs ON sj.job_id = sjs.job_id
WHERE   sjs.subsystem = N'SSIS' and sj.name='Daily_Prod_MI_Storage_Mailer'

----------

SELECT    JS.command FROM    dbo.sysjobs AS SJ
    INNER JOIN dbo.sysjobsteps AS JS
    ON JS.job_id = SJ.job_id
WHERE
    SJ.name = 'INFCSA_Data_Porting_PT';



---------------
USE msdb;
GO
 
SELECT
jobs.name AS JobName,
    steps.step_id AS StepID,
    steps.step_name AS StepName,
    steps.command AS Command,
    CASE
        WHEN steps.subsystem = 'TSQL' THEN 'Transact-SQL'
        WHEN steps.subsystem = 'SSIS' THEN 'SQL Server Integration Services'
        WHEN steps.subsystem = 'CMDEXEC' THEN 'Operating System (CmdExec)'
        WHEN steps.subsystem = 'POWERSHELL' THEN 'PowerShell'
        ELSE steps.subsystem
    END AS Subsystem,
    steps.database_name AS DatabaseName,
    CASE
        WHEN steps.server IS NOT NULL THEN steps.server
        ELSE '(Local Server)'
    END AS DataSource
FROM
    sysjobs AS jobs
INNER JOIN
    sysjobsteps AS steps ON jobs.job_id = steps.job_id
ORDER BY
    JobName, StepID;
