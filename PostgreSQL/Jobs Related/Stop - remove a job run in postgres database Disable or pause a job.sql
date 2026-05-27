---to disable the job------


UPDATE cron.job
SET active = false
WHERE jobname = 'ddl_event_log_cleanup_yourdbname';



------to remove job----------

SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'ddl_event_log_cleanup_yourdbname';