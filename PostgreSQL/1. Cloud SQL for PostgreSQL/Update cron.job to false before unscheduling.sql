SELECT jobid, schedule, command, nodename, nodeport, database, username, active, jobname
	FROM cron.job;

	select * from cron.job_run_details where jobid=6

	update cron.job set active='false' where jobid=6

	select public.cleanup_oneoff_cron_jobs()
	

	SELECT cron.schedule(
'cleanup-oneoff-cron-jobs',
'0 */4 * * *',  -- The interval: Run at the top of every 4th hour
$$SELECT public.cleanup_oneoff_cron_jobs();$$);

select public.run_cron_job_manually('cleanup-oneoff-cron-jobs')


	