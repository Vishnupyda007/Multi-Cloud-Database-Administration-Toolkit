SELECT cron.schedule_in_database(
  'refresh_fdw_EDS_views_OneC-4681',   -- unique job name
  '*/5 * * * *',             -- every 10 minutes
  'SELECT "DBAdmin".refresh_fdw_views()',-- function that exists in app1_db
  'OneC_4681'                   -- target database
);

select * from cron.job


select public.run_cron_job_manually('refresh_fdw_EDS_views_OneC-4681')

set time zone 'Asia/Kolkata';
select * from cron.job_run_details order by start_time desc;
