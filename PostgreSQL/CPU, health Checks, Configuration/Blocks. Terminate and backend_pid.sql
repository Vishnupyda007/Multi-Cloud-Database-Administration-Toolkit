
SELECT * 
FROM pg_stat_activity
WHERE datname = 'template1'
  AND pid <> pg_backend_pid(); -- Exclude your own session


 select pg_terminate_backend(903007)