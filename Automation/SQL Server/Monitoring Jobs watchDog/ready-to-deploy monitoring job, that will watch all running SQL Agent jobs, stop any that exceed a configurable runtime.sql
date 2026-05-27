Absolutely—here’s a **ready-to-deploy monitoring job** that will watch all running SQL Agent jobs, **stop any that exceed a configurable runtime** (default 30 minutes), **log everything**, and **email you an alert** for each stop action. It also supports **per‑job policies** (different thresholds, recipients, on/off).

> ✅ Works entirely in T‑SQL (no CLR/PowerShell needed)  
> ✅ Uses `msdb` for objects by default  
> ✅ Safe by default with **exclusions** and **dry‑run** mode  
> ✅ Per‑job overrides with a policy table

***

## What this installer does

1.  Creates:
    *   `msdb.dbo.JobRuntimePolicy` — **optional overrides** per job (who to alert, max minutes, enabled).
    *   `msdb.dbo.JobRuntimeStopLog` — **detailed log** of all checks/stops.
    *   `msdb.dbo.usp_EnforceJobMaxRuntime` — main **watchdog** proc.
2.  Creates a SQL Agent Job: **“Job Runtime Watchdog”** (runs every minute).
3.  Sends **Database Mail** alerts per stopped job.

> **Prereqs**
>
> *   Database Mail configured and a profile name you can use.
> *   The Agent Job owner (or the proxy) must be able to execute:
>     *   `msdb..sp_stop_job` (Agent operator or sysadmin),
>     *   `sp_send_dbmail` (member of `DatabaseMailUserRole` in `msdb`).

***

## 1) Install / Setup Script

> 🔧 **Customize the variables in the “CONFIGURE” block** first — especially `@DbMailProfileName` and `@DefaultToEmails`.

```sql
/* =======================================================================
   SQL Agent Job Runtime Watchdog: Install / Setup
   Creates policy table, log table, stored proc, and an Agent job that
   stops jobs running longer than a configured limit (default 30 min),
   logs details, and emails alerts.

   Run as: sysadmin (recommended)
   Target DB: msdb
   ======================================================================= */

USE msdb;
GO

/* ============================
   CONFIGURE (edit these)
   ============================ */
DECLARE 
    @DbMailProfileName SYSNAME      = N'Default',        -- Database Mail profile
    @DefaultToEmails   NVARCHAR(4000)= N'dba-team@example.com', -- fallback recipients (CSV)
    @DefaultMaxMinutes INT          = 30,                -- global default
    @ApplyDefaultToAll BIT          = 1,                 -- 1 = enforce default for all jobs unless excluded
    @ExcludeJobsCSV    NVARCHAR(MAX)= N'Job Runtime Watchdog%', -- CSV of job names (supports % wildcards)
    @JobName           SYSNAME      = N'Job Runtime Watchdog',
    @RunEverySeconds   INT          = 60,                -- schedule frequency
    @DryRun            BIT          = 0;                 -- 1 = log only, do not stop
/* ============================ */

--------------------------------------------------------------------------------
-- 1) Tables: Policy and Log
--------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.JobRuntimePolicy', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.JobRuntimePolicy
    (
        JobName            SYSNAME        NOT NULL,       -- Exact name of the job
        MaxRuntimeMinutes  INT            NOT NULL,       -- Threshold for this job
        Enabled            BIT            NOT NULL DEFAULT(1), -- 1=enforce policy for this job
        Enforce            BIT            NOT NULL DEFAULT(1), -- 1=stop when exceeded
        AlertToEmails      NVARCHAR(4000) NULL,           -- CSV emails for this job
        Notes              NVARCHAR(1000) NULL,
        CreatedAt          DATETIME2(0)   NOT NULL DEFAULT(SYSDATETIME()),
        CreatedBy          SYSNAME        NOT NULL DEFAULT(SUSER_SNAME()),
        CONSTRAINT PK_JobRuntimePolicy PRIMARY KEY (JobName)
    );
END
GO

IF OBJECT_ID(N'dbo.JobRuntimeStopLog', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.JobRuntimeStopLog
    (
        LogId              BIGINT         IDENTITY(1,1) PRIMARY KEY,
        JobId              UNIQUEIDENTIFIER NULL,
        JobName            SYSNAME        NOT NULL,
        SessionId          INT            NULL,
        CategoryName       SYSNAME        NULL,
        StartExecutionDate DATETIME2(0)   NULL,
        StopCheckTime      DATETIME2(0)   NOT NULL DEFAULT(SYSDATETIME()),
        ElapsedSeconds     INT            NULL,
        ThresholdSeconds   INT            NULL,
        CurrentStepId      INT            NULL,
        CurrentStepName    SYSNAME        NULL,
        ActionTaken        NVARCHAR(50)   NOT NULL,   -- 'Stopped', 'WouldStop', 'Skipped', 'Error'
        StopAttemptResult  NVARCHAR(4000) NULL,
        AlertToEmails      NVARCHAR(4000) NULL,
        AlertSent          BIT            NULL,
        AlertError         NVARCHAR(1000) NULL,
        InstanceName       SYSNAME        NULL,
        SqlServerName      SYSNAME        NULL,
        InsertedBy         SYSNAME        NOT NULL DEFAULT(SUSER_SNAME()),
        InsertedAt         DATETIME2(0)   NOT NULL DEFAULT(SYSDATETIME())
    );
    CREATE INDEX IX_JobRuntimeStopLog_JobName_Time ON dbo.JobRuntimeStopLog (JobName, InsertedAt DESC);
    CREATE INDEX IX_JobRuntimeStopLog_Action_Time   ON dbo.JobRuntimeStopLog (ActionTaken, InsertedAt DESC);
END
GO

--------------------------------------------------------------------------------
-- 2) Main Procedure
--------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.usp_EnforceJobMaxRuntime', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_EnforceJobMaxRuntime;
GO

CREATE PROCEDURE dbo.usp_EnforceJobMaxRuntime
      @DefaultMaxMinutes   INT                = 30
    , @DbMailProfileName   SYSNAME            = N'Default'
    , @DefaultToEmails     NVARCHAR(4000)     = NULL
    , @ApplyDefaultToAll   BIT                = 1          -- apply default policy to all jobs not in policy table
    , @ExcludeJobsCSV      NVARCHAR(MAX)      = NULL       -- CSV; supports % wildcards
    , @DryRun              BIT                = 0          -- 1=do not stop; just log "WouldStop"
    , @SendEmail           BIT                = 1
AS
BEGIN
    SET NOCOUNT ON;

    /* Resolve current Agent session id to identify currently-running rows */
    DECLARE @CurrentSessionId INT;
    SELECT @CurrentSessionId = MAX(session_id) FROM msdb.dbo.syssessions;

    /* Build exclude patterns table from CSV (supports simple wildcard %) */
    DECLARE @Excl TABLE (Pattern NVARCHAR(400) NOT NULL);
    IF @ExcludeJobsCSV IS NOT NULL
    BEGIN
        INSERT INTO @Excl(Pattern)
        SELECT LTRIM(RTRIM(value))
        FROM STRING_SPLIT(@ExcludeJobsCSV, ',')
        WHERE LTRIM(RTRIM(value)) <> '';
    END

    /* Collect currently running jobs + elapsed + step guess */
    ;WITH running AS (
        SELECT
            j.job_id,
            j.name                     AS JobName,
            c.name                     AS CategoryName,
            ja.session_id,
            ja.start_execution_date,
            DATEDIFF(SECOND, ja.start_execution_date, SYSDATETIME()) AS ElapsedSeconds,
            ja.last_executed_step_id,
            -- current step heuristic: last_executed_step_id + 1 (or 1 if null)
            ISNULL(ja.last_executed_step_id + 1, 1) AS CurrentStepId
        FROM msdb.dbo.sysjobactivity AS ja
        INNER JOIN msdb.dbo.sysjobs AS j
            ON j.job_id = ja.job_id
        LEFT JOIN msdb.dbo.syscategories AS c
            ON c.category_id = j.category_id
        WHERE ja.session_id = @CurrentSessionId
          AND ja.start_execution_date IS NOT NULL
          AND ja.stop_execution_date  IS NULL
    ),
    withStepName AS (
        SELECT r.*, s.step_name AS CurrentStepName
        FROM running r
        LEFT JOIN msdb.dbo.sysjobsteps s
            ON s.job_id = r.job_id AND s.step_id = r.CurrentStepId
    ),
    withPolicy AS (
        SELECT
            w.*,
            p.MaxRuntimeMinutes,
            p.Enabled,
            p.Enforce,
            p.AlertToEmails
        FROM withStepName w
        LEFT JOIN msdb.dbo.JobRuntimePolicy p
            ON p.JobName = w.JobName
    ),
    effective AS (
        SELECT
            w.JobId,
            w.JobName,
            w.CategoryName,
            w.session_id         AS SessionId,
            w.start_execution_date,
            w.ElapsedSeconds,
            w.CurrentStepId,
            w.CurrentStepName,
            -- effective policy
            ThresholdSeconds = COALESCE(w.MaxRuntimeMinutes, CASE WHEN @ApplyDefaultToAll=1 THEN @DefaultMaxMinutes ELSE NULL END) * 60,
            PolicyEnabled    = COALESCE(w.Enabled, CASE WHEN @ApplyDefaultToAll=1 THEN 1 ELSE 0 END),
            PolicyEnforce    = COALESCE(w.Enforce, CASE WHEN @ApplyDefaultToAll=1 THEN 1 ELSE 0 END),
            PolicyEmails     = NULLIF(COALESCE(w.AlertToEmails, @DefaultToEmails), '')
        FROM withPolicy w
    )
    SELECT * INTO #candidates
    FROM effective e
    WHERE e.PolicyEnabled = 1
      AND e.ThresholdSeconds IS NOT NULL
      AND e.ElapsedSeconds >= e.ThresholdSeconds
      AND NOT EXISTS (
            SELECT 1 FROM @Excl x WHERE e.JobName LIKE x.Pattern
      );

    DECLARE 
        @InstanceName SYSNAME     = CAST(SERVERPROPERTY('InstanceName') AS SYSNAME),
        @ServerName   SYSNAME     = CAST(SERVERPROPERTY('MachineName') AS SYSNAME);

    DECLARE 
        @job_id UNIQUEIDENTIFIER,
        @job_name SYSNAME,
        @session_id INT,
        @start_time DATETIME2(0),
        @elapsed INT,
        @thresh INT,
        @step_id INT,
        @step_name SYSNAME,
        @cat SYSNAME,
        @enforce BIT,
        @emails NVARCHAR(4000);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT JobId, JobName, SessionId, start_execution_date, ElapsedSeconds, ThresholdSeconds,
               CurrentStepId, CurrentStepName, CategoryName, PolicyEnforce, PolicyEmails
        FROM #candidates;

    OPEN cur;
    FETCH NEXT FROM cur INTO @job_id, @job_name, @session_id, @start_time, @elapsed, @thresh,
                             @step_id, @step_name, @cat, @enforce, @emails;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @action NVARCHAR(50) = N'Skipped';
        DECLARE @result NVARCHAR(4000) = NULL;
        DECLARE @alertSent BIT = NULL, @alertErr NVARCHAR(1000) = NULL;

        IF @DryRun = 1
        BEGIN
            SET @action = N'WouldStop';
        END
        ELSE IF @enforce = 1
        BEGIN
            BEGIN TRY
                EXEC msdb.dbo.sp_stop_job @job_id = @job_id;
                SET @action = N'Stopped';
                SET @result = N'sp_stop_job succeeded';
            END TRY
            BEGIN CATCH
                SET @action = N'Error';
                SET @result = CONCAT('sp_stop_job failed: [', ERROR_NUMBER(), '] ', ERROR_MESSAGE());
            END CATCH
        END
        ELSE
        BEGIN
            SET @action = N'Skipped';
            SET @result = N'PolicyEnforce=0';
        END

        /* Log row */
        INSERT INTO dbo.JobRuntimeStopLog
        (
            JobId, JobName, SessionId, CategoryName,
            StartExecutionDate, StopCheckTime, ElapsedSeconds, ThresholdSeconds,
            CurrentStepId, CurrentStepName,
            ActionTaken, StopAttemptResult,
            AlertToEmails, AlertSent, AlertError,
            InstanceName, SqlServerName
        )
        VALUES
        (
            @job_id, @job_name, @session_id, @cat,
            @start_time, SYSDATETIME(), @elapsed, @thresh,
            @step_id, @step_name,
            @action, @result,
            @emails, NULL, NULL,
            @InstanceName, @ServerName
        );

        DECLARE @NewLogId BIGINT = SCOPE_IDENTITY();

        /* Send email per event (Stopped or WouldStop), if configured */
        IF @SendEmail = 1 AND (@action IN (N'Stopped', N'Error', N'WouldStop')) AND NULLIF(@emails, '') IS NOT NULL
        BEGIN
            DECLARE @sub NVARCHAR(400) = CONCAT(
                N'[SQL Agent Watchdog] ', @action, N' job "', @job_name, 
                N'" after ', @elapsed, N's (threshold ', @thresh, N's) on ', 
                COALESCE(@ServerName, @@SERVERNAME), 
                CASE WHEN @InstanceName IS NOT NULL AND @InstanceName <> N'' THEN CONCAT(N'\', @InstanceName) ELSE N'' END
            );

            DECLARE @body NVARCHAR(MAX) = N'';
            SET @body = CONCAT(
N'Action: ', @action, N'
Result: ', COALESCE(@result, N''), N'

Job: ', @job_name, N' (', CONVERT(VARCHAR(36), @job_id), N')
Category: ', COALESCE(@cat, N''), N'
Started at: ', CONVERT(NVARCHAR(19), @start_time, 120), N'
Checked at: ', CONVERT(NVARCHAR(19), SYSDATETIME(), 120), N'
Elapsed (sec): ', @elapsed, N'
Threshold (sec): ', @thresh, N'
Current step: ', COALESCE(CAST(@step_id AS NVARCHAR(10)), N''), N' - ', COALESCE(@step_name, N''), N'

Server: ', COALESCE(@ServerName, @@SERVERNAME), 
CASE WHEN @InstanceName IS NOT NULL AND @InstanceName <> N'' THEN CONCAT(N'\', @InstanceName) ELSE N'' END, N'

This notification was generated by msdb.dbo.usp_EnforceJobMaxRuntime.'
            );

            BEGIN TRY
                EXEC msdb.dbo.sp_send_dbmail
                      @profile_name = @DbMailProfileName
                    , @recipients   = @emails
                    , @subject      = @sub
                    , @body         = @body;

                UPDATE dbo.JobRuntimeStopLog
                SET AlertSent = 1
                WHERE LogId = @NewLogId;
            END TRY
            BEGIN CATCH
                SET @alertErr = CONCAT('DBMail failed: [', ERROR_NUMBER(), '] ', ERROR_MESSAGE());
                UPDATE dbo.JobRuntimeStopLog
                SET AlertSent = 0, AlertError = @alertErr
                WHERE LogId = @NewLogId;
            END CATCH
        END

        FETCH NEXT FROM cur INTO @job_id, @job_name, @session_id, @start_time, @elapsed, @thresh,
                                 @step_id, @step_name, @cat, @enforce, @emails;
    END

    CLOSE cur; DEALLOCATE cur;
END
GO
```

***

## 2) (Optional) Seed Per‑Job Policies

Use this to **override** the default 30 minutes for specific jobs, change recipients, or disable enforcement for a job.

```sql
-- Examples: insert / upsert per-job policies
MERGE msdb.dbo.JobRuntimePolicy AS T
USING (VALUES
    (N'Nightly ETL Load', 45, 1, 1, N'etl-ops@example.com', N'ETL needs 45 minutes'),
    (N'Index Maintenance - UserDBs', 90, 1, 0, N'dba-team@example.com', N'Monitor only, do not stop'),
    (N'Critical Report Generator', 25, 1, 1, N'app-owners@example.com', N'Tight SLA')
) AS S(JobName, MaxRuntimeMinutes, Enabled, Enforce, AlertToEmails, Notes)
ON T.JobName = S.JobName
WHEN MATCHED THEN UPDATE
  SET MaxRuntimeMinutes = S.MaxRuntimeMinutes,
      Enabled           = S.Enabled,
      Enforce           = S.Enforce,
      AlertToEmails     = S.AlertToEmails,
      Notes             = S.Notes
WHEN NOT MATCHED THEN
  INSERT (JobName, MaxRuntimeMinutes, Enabled, Enforce, AlertToEmails, Notes)
  VALUES (S.JobName, S.MaxRuntimeMinutes, S.Enabled, S.Enforce, S.AlertToEmails, S.Notes);
```

***

## 3) Create the SQL Agent Job and Schedule

> **Tip:** Add your DBA team email into `@DefaultToEmails`, and add any **exclusions** (e.g., log shipping, replication, or this watchdog job itself).

```sql
USE msdb;
GO

-- Clean up any existing job with same name
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job Runtime Watchdog')
BEGIN
    EXEC msdb.dbo.sp_delete_job @job_name = N'Job Runtime Watchdog';
END
GO

DECLARE 
    @job_id UNIQUEIDENTIFIER,
    @job_name SYSNAME          = N'Job Runtime Watchdog',
    @DbMailProfileName SYSNAME = N'Default',
    @DefaultToEmails NVARCHAR(4000) = N'dba-team@example.com',
    @DefaultMaxMinutes INT     = 30,
    @ApplyDefaultToAll BIT     = 1,
    @ExcludeJobsCSV NVARCHAR(MAX) = N'Job Runtime Watchdog%,Log Shipping%,syspolicy%';

-- Create job
EXEC msdb.dbo.sp_add_job
      @job_name   = @job_name
    , @enabled    = 1
    , @description= N'Stops SQL Agent jobs exceeding configured runtime; logs to msdb.dbo.JobRuntimeStopLog and emails.'
    , @start_step_id = 1
    , @owner_login_name = SUSER_SNAME()
    , @job_id     = @job_id OUTPUT;

-- Add T-SQL step that enforces the policy every run
EXEC msdb.dbo.sp_add_jobstep
      @job_id = @job_id
    , @step_id = 1
    , @step_name = N'Enforce Max Runtime'
    , @subsystem = N'TSQL'
    , @database_name = N'msdb'
    , @command = N'
EXEC msdb.dbo.usp_EnforceJobMaxRuntime
      @DefaultMaxMinutes = ' + CAST(@DefaultMaxMinutes AS NVARCHAR(10)) + N'
    , @DbMailProfileName = N''' + @DbMailProfileName + N'''
    , @DefaultToEmails   = N''' + @DefaultToEmails + N'''
    , @ApplyDefaultToAll = ' + CAST(@ApplyDefaultToAll AS NVARCHAR(1)) + N'
    , @ExcludeJobsCSV    = N''' + @ExcludeJobsCSV + N'''
    , @DryRun            = 0
    , @SendEmail         = 1;'
    , @retry_attempts = 0
    , @on_success_action = 1   -- Quit with success
    , @on_fail_action = 2;     -- Quit with failure

-- Run every 1 minute (customize as needed)
EXEC msdb.dbo.sp_add_schedule
      @schedule_name = N'Every 1 Minute'
    , @enabled = 1
    , @freq_type = 4             -- daily
    , @freq_interval = 1
    , @freq_subday_type = 4      -- minutes
    , @freq_subday_interval = 1  -- every 1 minute
    , @active_start_time = 0;

EXEC msdb.dbo.sp_attach_schedule
      @job_id = @job_id
    , @schedule_name = N'Every 1 Minute';

EXEC msdb.dbo.sp_add_jobserver
      @job_id = @job_id;
GO
```

***

## 4) How to Use / Customize

*   **Global default:** The job monitors all running jobs and stops any exceeding **30 minutes** (change via `@DefaultMaxMinutes`).
*   **Exclusions:** Add job name patterns to `@ExcludeJobsCSV` (supports `%` wildcards), e.g.:
    *   `Log Shipping%`, `AlwaysOn%`, `syspolicy%`, your monitor job name, etc.
*   **Per‑job overrides:** Insert/update rows in `msdb.dbo.JobRuntimePolicy`:
    *   Set `MaxRuntimeMinutes`, `AlertToEmails`, `Enforce` (0 to only observe), `Enabled` (0 to ignore).
*   **Email routing:** Uses policy `AlertToEmails` if present; otherwise `@DefaultToEmails`.
*   **Dry‑run mode:** Set `@DryRun = 1` (either during testing or in the agent job step) to **log** but **not stop**.

***

## 5) Test It Safely

1.  Create a dummy long‑running job:
    ```sql
    EXEC msdb.dbo.sp_add_job @job_name = N'Dummy Long Runner';
    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'Dummy Long Runner',
        @step_name = N'Wait',
        @subsystem = N'TSQL',
        @command = N'WAITFOR DELAY ''00:40:00'';';
    EXEC msdb.dbo.sp_add_jobserver @job_name = N'Dummy Long Runner';
    EXEC msdb.dbo.sp_start_job @job_name = N'Dummy Long Runner';
    ```
2.  Ensure the watchdog default is 30 min and not excluding this job.
3.  Watch entries in `msdb.dbo.JobRuntimeStopLog` and your email.

***

## 6) Operational Notes & Good Practices

*   **Rollback time:** Stopping a job that’s in a large transaction may take time due to rollback.
*   **Retry loops:** If your job has step retries, ensure it won’t keep re‑starting immediately after being stopped; use scheduling windows or guards inside the job.
*   **High‑noise environments:** Consider increasing the schedule interval to every 2–5 minutes if 1‑minute polling is too frequent.
*   **Security:** The job owner or proxy must have:
    *   `SQLAgentOperatorRole` (or higher) in `msdb` to stop jobs.
    *   `DatabaseMailUserRole` in `msdb` to send mail.

***

## 7) Uninstall (if needed)

```sql
USE msdb;
GO
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Job Runtime Watchdog')
    EXEC msdb.dbo.sp_delete_job @job_name = N'Job Runtime Watchdog';

DROP PROCEDURE IF EXISTS dbo.usp_EnforceJobMaxRuntime;
-- Keep log table by default; drop if you want a clean slate:
-- DROP TABLE IF EXISTS dbo.JobRuntimeStopLog;
-- DROP TABLE IF EXISTS dbo.JobRuntimePolicy;
GO
```

***

## Want me to tailor this for your environment?

*   Share:
    *   The **email list** you want for `@DefaultToEmails`,
    *   Any **jobs to exclude** (log shipping/replication/AlwaysOn/maintenance),
    *   Any **per‑job thresholds** and recipients.
*   I can return a **pre‑filled policy block** for your specific jobs and a **final install script** you can run as‑is.

Would you like me to:

1.  Pre‑populate policies for a list of your critical jobs, or
2.  Package this into a **.sql** file with your defaults for easy rollout across servers?
