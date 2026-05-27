

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
    @DbMailProfileName SYSNAME      = N'ITOps1CDBA',        -- Database Mail profile
    @DefaultToEmails   NVARCHAR(4000)= N'CRSDBASUPPORT@cognizant.com', -- fallback recipients (CSV)
    @DefaultMaxMinutes INT          = 30,                -- global default
    @ApplyDefaultToAll BIT          = 1,                 -- 1 = enforce default for all jobs unless excluded
    @ExcludeJobsCSV    NVARCHAR(MAX)= N'Job Runtime Watchdog%', -- CSV of job names (supports % wildcards)
    @JobName           SYSNAME      = N'Job Runtime Watchdog',
    @RunEverySeconds   INT          = 300,                -- schedule frequency
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
