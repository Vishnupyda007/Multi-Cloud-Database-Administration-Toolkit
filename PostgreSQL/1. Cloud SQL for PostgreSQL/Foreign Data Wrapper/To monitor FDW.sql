set time zone 'Asia/Kolkata';
SELECT *
FROM pg_stat_activity
WHERE application_name = 'postgres_fdw';


select
  datname,
  temp_files,       -- high number = work_mem too low, spilling to disk
  temp_bytes        -- bytes written to temp files
FROM pg_stat_database
WHERE datname NOT IN ('template0','template1')
ORDER BY temp_bytes DESC;

select * from pg_settings where name like ''

--select * from pg_stat_database

select * from pg_stat_statements

SELECT
  datname,
  blk_read_time,
  blk_write_time,
  tup_fetched,
  tup_returned
FROM pg_stat_database
WHERE datname NOT IN ('template0','template1')
ORDER BY blk_read_time DESC;



SELECT 
    pid,
    state,
    wait_event_type,
    wait_event,
    left(query, 80) AS query_preview,
    now() - query_start AS duration
FROM pg_stat_activity
WHERE state != 'idle'
AND usename = 'gguser_repedspgsql_nonprod'
ORDER BY duration DESC;