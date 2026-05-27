-- Memory pressure — are queries spilling to disk?
SELECT
  datname,
  temp_files,       -- high number = work_mem too low, spilling to disk
  temp_bytes        -- bytes written to temp files
FROM pg_stat_database
WHERE datname NOT IN ('template0','template1')
ORDER BY temp_bytes DESC;