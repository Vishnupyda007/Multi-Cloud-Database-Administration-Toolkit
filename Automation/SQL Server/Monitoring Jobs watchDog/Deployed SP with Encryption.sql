

--------------------------------------------------------------------------------
-- 2) Main Procedure
--------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.usp_EnforceJobMaxRuntime', N'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_EnforceJobMaxRuntime;
GO

CREATE PROCEDURE dbo.USP_EnforceJobMaxRuntime
      @DefaultMaxMinutes   INT                = 30
    , @DbMailProfileName   SYSNAME            = N'ITOps1CDBA'
    , @DefaultToEmails     NVARCHAR(4000)     = 'CRSDBASUPPORT@cognizant.com'
    , @ApplyDefaultToAll   BIT                = 1          -- apply default policy to all jobs not in policy table
    , @ExcludeJobsCSV      NVARCHAR(MAX)      = NULL       -- CSV; supports % wildcards
    , @DryRun              BIT                = 0          -- 1=do not stop; just log "WouldStop"
    , @SendEmail           BIT                = 1 with encryption
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
		  and j.name not in ('syspolicy_purge_history','SSIS Server Maintenance Job','DBA_FullBackup.Subplan_1','Prod_Replication_Status_Report',
		  'UpdateStatistics.Subplan_1','MaintenancePlan.Subplan_1','1C_AI_Assistant_Weekly_Rebuild_Index_and_Update_Stats','1C_AI_Assistant_Daily_Update_Stats')
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
        LEFT JOIN dbo.JobRuntimePolicy p
            ON p.JobName = w.JobName
    ),
    effective AS (
        SELECT
            w.job_id,
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
        SELECT job_id, JobName, SessionId, start_execution_date, ElapsedSeconds, ThresholdSeconds,
               CurrentStepId, CurrentStepName, CategoryName, PolicyEnforce, PolicyEmails
        FROM #candidates ;

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
                N'" after ', @elapsed, N's (threshold ', @thresh, N's) ', 
                --COALESCE(@ServerName, @@SERVERNAME), 
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
Current step: ', COALESCE(CAST(@step_id AS NVARCHAR(10)), N''), N' - ', COALESCE(@step_name, N''), 
--N'

--Server: ', COALESCE(@ServerName, @@SERVERNAME), 
CASE WHEN @InstanceName IS NOT NULL AND @InstanceName <> N'' THEN CONCAT(N'\', @InstanceName) ELSE N'' END, N'

This notification was generated by System.'
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
