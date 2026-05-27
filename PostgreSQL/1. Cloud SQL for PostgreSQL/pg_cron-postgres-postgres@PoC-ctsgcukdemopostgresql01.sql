SELECT cron.schedule_in_database('test in DB2', '* * * * *', 'UPDATE public.actor
                SET first_name = ''Kiran'',
                    last_name = ''Kumar'',
                    last_update = now()
                WHERE actor_id = 11;', 'og_db');



select * from cron.job_run_details where jobid in (19,20,22,23,24,25) order by start_time desc


 
 select * from cron.job



 SELECT cron.schedule(
    'test1-job', -- The name of the job
    '* * * * *',           -- The schedule: every day at 3:00 AM
    $$ UPDATE public.actor
	SET  first_name='Hima', last_name='Vishnu', last_update=now()
	WHERE actor_id=1; $$ -- The command
);
 
SELECT cron.alter_job(
    job_id := 8,  -- The name of the job you are targeting
    schedule := NULL,             -- Pass NULL because we are NOT changing the schedule
    -- The new command you want the job to run is placed inside these dollar quotes
    command := $$
        SELECT dblink_exec(
            'dbname=og_db',
            -- Start of the inner dollar-quoted string
            $remote_command$
                UPDATE public.actor
                SET first_name = 'Kiran',
                    last_name = 'Kumar',
                    last_update = now()
                WHERE actor_id = 6;
            $remote_command$
            -- End of the inner dollar-quoted string
        );
    $$
);
 
 
UPDATE cron.job SET database = 'og_db' WHERE jobid = 9;
 
select * from cron.job
 
select * from cron.job_run_details where jobid in (8,7,9,15) order by start_time desc
 
SELECT cron.alter_job(
    job_id := 7,
    schedule := '* * * * *',  -- Run every minute
 
    -- The command can now be a simple UPDATE statement
    -- because the job is running from within the target database.
    -- We still need to handle the single quotes correctly.
    command := $$
        UPDATE public.actor
        SET first_name = 'Hima',
            last_name = 'Vishnu',
            last_update = now()
        WHERE actor_id = 4;
    $$
);
 
-- Run this from the 'postgres' database
 
SELECT cron.schedule(
    'run-test-og_db-with-auth',  -- A new, unique name for the job
    '* * * * *',               -- Run every 2 minutes for testing
    $$
    SELECT dblink_exec(
        -- The full connection string, now including user and password
        'host=10.75.154.9 dbname=og_db user=postgres password=8>z{&knxM\OyHud:',
        -- The command to run (no changes needed here)
        $remote_command$
            UPDATE public.actor
            SET first_name = 'Hima',
                last_name = 'Vishnu',
                last_update = now()
            WHERE actor_id = 7;
        $remote_command$
    );
    $$
);