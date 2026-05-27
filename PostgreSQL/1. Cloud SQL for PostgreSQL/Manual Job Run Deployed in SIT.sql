
-------------------------------------------------------------------------------
-- Cloud SQL for PostgreSQL: Manual pg_cron run + logging + reconciler setup
-- IMPORTANT: Execute this in the `postgres` database (where pg_cron is installed)
-------------------------------------------------------------------------------

-- 0) Ensure pg_cron is enabled in this database (Cloud SQL enables via instance flag)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- (Optional) allow your operator role to query cron schema
-- GRANT USAGE ON SCHEMA cron TO your_operator_role;

-------------------------------------------------------------------------------
-- 1) Create manual job log table and indexes
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.manual_job_log (
    log_id          BIGSERIAL PRIMARY KEY,
    job_name        TEXT        NOT NULL,
    command         TEXT        NOT NULL,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    finished_at     TIMESTAMPTZ,
    duration_ms     INTEGER,
    executed_by     TEXT        NOT NULL DEFAULT current_user,
    success         BOOLEAN     NOT NULL DEFAULT FALSE,
    rows_affected   BIGINT,
    error_message   TEXT,
    run_context     JSONB       -- stores pg_cron one-off jobid, status, etc.
);

-- Helpful indexes for querying by time & job name
CREATE INDEX IF NOT EXISTS ix_manual_job_log_started_at
    ON public.manual_job_log (started_at DESC);

CREATE INDEX IF NOT EXISTS ix_manual_job_log_job_name
    ON public.manual_job_log (job_name, started_at DESC);

-------------------------------------------------------------------------------
-- 2) Manual trigger function (pg_cron-only, Cloud SQL compatible)
--    Schedules a one-off run on the next minute tick in the target database.
--    Returns the new pg_cron jobid. Outcome is reconciled later.
-------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.run_cron_job_manually(TEXT);

CREATE OR REPLACE FUNCTION public.run_cron_job_manually(job_name_to_run TEXT)
RETURNS INTEGER  -- returns one-off pg_cron jobid (or NULL if base job not found)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, cron, pg_temp
AS $func$
DECLARE
    v_jobname      TEXT := btrim(job_name_to_run, E' \t\r\n');
    v_cmd          TEXT;
    v_db           TEXT;
    v_base_jobid   INT;
    v_log_id       BIGINT;
    v_started_at   TIMESTAMPTZ := clock_timestamp();
    v_run_jobname  TEXT;
    v_new_jobid    INT;
BEGIN
    -- Normalize accidental surrounding single quotes (e.g., 'name')
    IF left(v_jobname,1) = '''' AND right(v_jobname,1) = '''' AND char_length(v_jobname) >= 2 THEN
        v_jobname := substring(v_jobname FROM 2 FOR char_length(v_jobname) - 2);
    END IF;

    -- Look up the base job in pg_cron catalog (managed from `postgres` DB)
    SELECT jobid, command, database
      INTO v_base_jobid, v_cmd, v_db
    FROM cron.job
    WHERE btrim(jobname, E' \t\r\n') = v_jobname
    LIMIT 1;

    IF v_cmd IS NULL THEN
        INSERT INTO public.manual_job_log(job_name, command, started_at, executed_by, success, error_message)
        VALUES (v_jobname, '<not found>', v_started_at, current_user, FALSE, 'Job not found');
        RAISE NOTICE 'Job "%" not found', v_jobname;
        RETURN NULL;
    END IF;

    -- Log "started" (we reconcile outcome later)
    INSERT INTO public.manual_job_log(job_name, command, started_at, executed_by, success, run_context)
    VALUES (v_jobname, v_cmd, v_started_at, current_user, FALSE,
            jsonb_build_object('mode','schedule_in_database'))
    RETURNING log_id INTO v_log_id;

    -- Create one-off job name; schedule for next minute tick (portable & reliable)
    v_run_jobname := v_jobname || '_manual_' || to_char(now(), 'YYYYMMDDHH24MISSMS');

    v_new_jobid := cron.schedule_in_database(
        v_run_jobname,
        '* * * * *',   -- next minute tick; seconds granularity can vary across providers
        v_cmd,
        v_db
    );

    -- Store linkage to the one-off pg_cron job
    UPDATE public.manual_job_log
       SET run_context = COALESCE(run_context, '{}'::jsonb) ||
                         jsonb_build_object('cron_jobid',   v_new_jobid,
                                            'cron_jobname', v_run_jobname,
                                            'target_db',    v_db)
     WHERE log_id = v_log_id;

    RAISE NOTICE 'Scheduled one-off manual run: jobid=% (jobname=%) for DB=%',
                 v_new_jobid, v_run_jobname, v_db;

    RETURN v_new_jobid;
END;
$func$;

ALTER FUNCTION public.run_cron_job_manually(TEXT) OWNER TO postgres;

-------------------------------------------------------------------------------
-- 3) Reconciler function: updates manual_job_log from cron.job_run_details
--    Call this after a minute or run it via pg_cron (see schedules below).
-------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.reconcile_manual_runs(INT);

CREATE OR REPLACE FUNCTION public.reconcile_manual_runs(max_age_minutes INT DEFAULT 120)
RETURNS INT  -- number of manual-log rows updated
LANGUAGE plpgsql
AS $$
DECLARE
    v_updated INT := 0;
BEGIN
    WITH ctx AS (
        SELECT log_id,
               (run_context->>'cron_jobid')::INT AS cron_jobid
        FROM public.manual_job_log
        WHERE run_context ? 'cron_jobid'
          AND started_at >= now() - make_interval(mins => max_age_minutes)
    ),
    last_runs AS (
        SELECT j.jobid, j.runid, j.status, j.return_message, j.end_time
        FROM cron.job_run_details j
        JOIN (
            SELECT jobid, max(runid) AS max_runid
            FROM cron.job_run_details
            GROUP BY jobid
        ) latest ON latest.jobid = j.jobid AND latest.max_runid = j.runid
    )
    UPDATE public.manual_job_log l
       SET finished_at   = lr.end_time,
           duration_ms   = CASE WHEN lr.end_time IS NOT NULL
                                THEN CAST(EXTRACT(EPOCH FROM (lr.end_time - l.started_at)) * 1000 AS INT)
                                ELSE l.duration_ms END,
           success       = (lr.status = 'succeeded'),
           error_message = CASE WHEN lr.status = 'succeeded' THEN NULL ELSE lr.return_message END,
           run_context   = COALESCE(l.run_context, '{}'::jsonb) ||
                           jsonb_build_object('status', lr.status,
                                              'return_message', lr.return_message,
                                              'runid', lr.runid)
    FROM ctx c
    JOIN last_runs lr ON lr.jobid = c.cron_jobid
    WHERE l.log_id = c.log_id
      AND (l.finished_at IS NULL OR l.success = FALSE);

    GET DIAGNOSTICS v_updated = ROW_COUNT;
    RETURN v_updated;
END;
$$;

ALTER FUNCTION public.reconcile_manual_runs(INT) OWNER TO postgres;

-------------------------------------------------------------------------------
-- 4) (Optional) pg_cron schedules (run these in `postgres` DB)
--    a) Reconciler every minute
--    b) Nightly cleanup of one-off jobs (optional; commented)
--    c) Weekly purge of old logs (optional; commented)
-------------------------------------------------------------------------------

-- a) Reconciler every minute (keeps logs in sync)
-- Step 1: Unschedule the old job to avoid duplicates
--SELECT cron.unschedule('manual-log-reconciler');

-- Step 2: Schedule the new job to run every 3 hours
SELECT cron.schedule(
  'manual-log-reconciler',
  '0 */3 * * *',  -- The interval: Run at the top of every 3rd hour
  $$SELECT public.reconcile_manual_runs(180);$$ -- The parameter: Look back 240 minutes (4 hours)
);


-- b) Nightly cleanup (e.g., at 00:05 UTC) — optional
CREATE OR REPLACE FUNCTION public.cleanup_oneoff_cron_jobs()
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
    v_job_ids INT[]; -- Array to hold the job IDs
    v_job_id  INT;
BEGIN
    -- Step 1: Collect all matching job IDs into an array variable.
    SELECT array_agg(jobid)
    INTO v_job_ids
    FROM cron.job
    WHERE jobname LIKE '%\_manual\_%'
      AND active = TRUE
      AND jobid IN (
         SELECT (run_context->>'cron_jobid')::INT
         FROM public.manual_job_log
         WHERE started_at < now() - INTERVAL '4 hours'
      );

    -- If no jobs were found, the array will be NULL. Exit early.
    IF v_job_ids IS NULL THEN
        RETURN 0;
    END IF;

    -- Step 2: Loop through the array and unschedule each job.
    -- The `FOREACH` loop is safe even if the array is empty.
    FOREACH v_job_id IN ARRAY v_job_ids
    LOOP
        PERFORM cron.unschedule(v_job_id);
    END LOOP;

    -- Step 3: The count is simply the number of elements in the array.
    RETURN array_length(v_job_ids, 1);

END;
$$;


select public.cleanup_oneoff_cron_jobs()

SELECT cron.schedule(
'cleanup-oneoff-cron-jobs',
'0 */4 * * *',  -- The interval: Run at the top of every 4th hour
$$SELECT public.cleanup_oneoff_cron_jobs();$$);

-- c) Weekly purge (Sundays 01:00 UTC; keep 90 days) — optional
CREATE OR REPLACE FUNCTION public.purge_manual_logs(p_retention_days INT DEFAULT 30)
RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE
  v_cron_deleted   BIGINT;
  v_manual_deleted BIGINT;
  v_retention_interval INTERVAL;
BEGIN
  -- Create an interval from the input days for use in queries.
  v_retention_interval := make_interval(days => p_retention_days);

  RAISE NOTICE 'Starting purge of records older than % days...', p_retention_days;

  -- 1. Purge from cron.job_run_details
  WITH deleted AS (
    DELETE FROM cron.job_run_details
    WHERE end_time < now() - v_retention_interval
    RETURNING jobid -- RETURNING a column is necessary for the CTE
  )
  SELECT count(*) INTO v_cron_deleted FROM deleted;

  RAISE NOTICE '--> Deleted % rows from cron.job_run_details.', COALESCE(v_cron_deleted, 0);

  -- 2. Purge from public.manual_job_log
  WITH deleted AS (
    DELETE FROM public.manual_job_log
    WHERE started_at < now() - v_retention_interval
    RETURNING 1 -- RETURNING a literal is efficient if we only need a count
  )
  SELECT count(*) INTO v_manual_deleted FROM deleted;

  RAISE NOTICE '--> Deleted % rows from public.manual_job_log.', COALESCE(v_manual_deleted, 0);

  -- 3. Return the total count of deleted rows from both tables
  RETURN COALESCE(v_cron_deleted, 0) + COALESCE(v_manual_deleted, 0);
END;
$$;

-- SELECT public.purge_manual_logs(7)
SELECT cron.schedule(
'purge-manual-logs',
'0 0 * * *',
$$SELECT public.purge_manual_logs(30);$$);

-------------------------------------------------------------------------------
-- 5) Sample usage
-------------------------------------------------------------------------------

-- Trigger a manual run for an existing pg_cron job by job name (exact match).
-- It will run on the next minute tick in the job's target database, and
-- return the one-off pg_cron jobid.
-- SELECT public.run_cron_job_manually('maintenance_job_analyze_dbs') AS one_off_jobid;

-- After ~60–90 seconds, the reconciler job will update your log automatically;
-- you can also force reconciliation at any time:
-- SELECT public.reconcile_manual_runs();

-- Inspect pg_cron’s run history (source of truth for success/failure)
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;
--SELECT count(*) FROM cron.job_run_details where end_time < now() - INTERVAL '7 days'
--- select * from cron.job order by jobid

-- Inspect your manual job audit log
-- SELECT * FROM public.manual_job_log ORDER BY started_at DESC LIMIT 10;

-------------------------------------------------------------------------------
-- End of setup
