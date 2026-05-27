-- CPU pressure — high blk_read_time = IO bound
SELECT
  datname,
  blk_read_time,
  blk_write_time,
  tup_fetched,
  tup_returned
FROM pg_stat_database
WHERE datname NOT IN ('template0','template1')
ORDER BY blk_read_time DESC;