
-- Schema: you can keep it in public or a dedicated schema (e.g., ops)
-- Here I use public for simplicity.

CREATE TABLE IF NOT EXISTS public.manual_job_log (
    log_id           bigserial PRIMARY KEY,
    job_name         text        NOT NULL,
    command          text        NOT NULL,
    started_at       timestamptz NOT NULL DEFAULT clock_timestamp(),
    finished_at      timestamptz,
    duration_ms      integer,                -- computed on finish
    executed_by      text        NOT NULL,   -- current_user at runtime
    success          boolean     NOT NULL DEFAULT false,
    rows_affected    bigint,                 -- optional: from GET DIAGNOSTICS
    error_message    text,                   -- populated on failure
    run_context      jsonb                  -- optional: extra details (params, env)
);

-- Helpful indexes for querying by time & job name
CREATE INDEX IF NOT EXISTS ix_manual_job_log_started_at
    ON public.manual_job_log (started_at DESC,job_name);




  
-- FUNCTION: public.run_cron_job_manually(text)
-- Replaces your function and adds robust logging and error handling.


CREATE OR REPLACE FUNCTION public.run_cron_job_manually(job_name_to_run text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, cron, pg_temp
AS $func$
DECLARE
    v_input         text := job_name_to_run;
    v_trimmed       text := btrim(v_input, E' \t\r\n');
    v_clean_input   text := v_trimmed;
    v_command       text;
    v_log_id        bigint;
    v_started_at    timestamptz := clock_timestamp();
    v_finished_at   timestamptz;
    v_duration_ms   integer;
    v_rowcount      bigint;
    v_candidates    text[];
BEGIN
    -- Strip surrounding single quotes if present (e.g. 'name')
    IF left(v_clean_input, 1) = '''' AND right(v_clean_input, 1) = '''' AND char_length(v_clean_input) >= 2 THEN
        v_clean_input := substring(v_clean_input FROM 2 FOR char_length(v_clean_input) - 2);
    END IF;

    RAISE NOTICE 'Input raw     = "%"', v_input;
    RAISE NOTICE 'Trimmed       = "%"', v_trimmed;
    RAISE NOTICE 'Cleaned       = "%"', v_clean_input;
    RAISE NOTICE 'Byte(raw)     = "%"', encode(v_input::bytea,'escape');
    RAISE NOTICE 'Byte(cleaned) = "%"', encode(v_clean_input::bytea,'escape');

    -- Lookup (case-insensitive exact after trim)
    SELECT c.command
      INTO v_command
    FROM cron.job c
    WHERE btrim(c.jobname, E' \t\r\n') ILIKE v_clean_input
    ORDER BY c.jobid
    LIMIT 1;

    -- Fallback: suggestions
    IF v_command IS NULL THEN
        SELECT array_agg(c.jobname ORDER BY c.jobid)
          INTO v_candidates
        FROM cron.job c
        WHERE c.jobname ILIKE '%' || v_clean_input || '%';

        INSERT INTO public.manual_job_log
               (job_name, command, started_at, executed_by, success, error_message, run_context)
        VALUES (v_clean_input, '<not found>', v_started_at, current_user, false,
                'Job not found',
                jsonb_build_object('suggestions', COALESCE(to_jsonb(v_candidates), '[]'::jsonb)));
        RAISE NOTICE 'Error: Job with name "%" not found.', v_clean_input;
        RETURN;
    END IF;

    -- 1) Persist the "started" log row
    INSERT INTO public.manual_job_log(job_name, command, started_at, executed_by, success)
    VALUES (v_clean_input, v_command, v_started_at, current_user, false)
    RETURNING log_id INTO v_log_id;

    -- 2) Inner block: run command so failures don't roll back the outer INSERT
    BEGIN
        RAISE NOTICE 'Manually executing job: %', v_clean_input;

        EXECUTE v_command;
        GET DIAGNOSTICS v_rowcount = ROW_COUNT;

        v_finished_at := clock_timestamp();
        v_duration_ms := CAST(EXTRACT(EPOCH FROM (v_finished_at - v_started_at)) * 1000 AS integer);

        UPDATE public.manual_job_log
           SET finished_at   = v_finished_at,
               duration_ms   = v_duration_ms,
               success       = true,
               rows_affected = v_rowcount
         WHERE log_id = v_log_id;

        RAISE NOTICE 'Job execution finished. Rows affected: %', COALESCE(v_rowcount, 0);

    EXCEPTION WHEN OTHERS THEN
        v_finished_at := clock_timestamp();
        v_duration_ms := CAST(EXTRACT(EPOCH FROM (v_finished_at - v_started_at)) * 1000 AS integer);

        UPDATE public.manual_job_log
           SET finished_at  = v_finished_at,
               duration_ms  = v_duration_ms,
               success      = false,
               error_message = SQLSTATE || ' ' || COALESCE(SQLERRM, 'Unknown error')
         WHERE log_id = v_log_id;

        RAISE NOTICE 'Job "%" failed: [%] %', v_clean_input, SQLSTATE, SQLERRM;
        -- Do not re-raise; we want to keep the log row.
    END;
END;
$func$;





select * from cron.job
SELECT public.run_cron_job_manually('test in DB1');

select * from cron.job_run_details order by start_time desc
select * from public.manual_job_log order by started_at desc



SELECT jobid,
       jobname,
       length(jobname)              AS len,
       encode(jobname::bytea,'escape') AS byte_view
FROM cron.job
ORDER BY jobid;



SELECT pid, usename, application_name, backend_type
FROM pg_stat_activity
WHERE application_name ILIKE 'pg_cron%';




SELECT current_database();             -- should be 'postgres'
SELECT COUNT(*) FROM cron.job;
SELECT COUNT(*) FROM cron.job_run_details;




