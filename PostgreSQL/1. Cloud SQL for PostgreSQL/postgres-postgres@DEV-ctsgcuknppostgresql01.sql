SELECT spcname, pg_tablespace_location(oid)FROM pg_tablespace;

 show log_directory;


 CREATE EXTENSION pg_cron;


 -- Total WAL directory size in bytes
SELECT SUM(size) AS wal_dir_bytes
FROM pg_ls_waldir();

-- Human-readable
SELECT pg_size_pretty(SUM(size)) AS wal_dir_pretty
FROM pg_ls_waldir();


-- Overall WAL generation since last reset
SELECT wal_bytes,
       pg_size_pretty(wal_bytes) AS wal_bytes_pretty,
       stats_reset
FROM pg_stat_wal;


SELECT pg_current_wal_lsn();



SELECT SUM(size) AS wal_dir_bytes
FROM pg_ls_waldir();

SELECT pg_size_pretty(SUM(size)) AS wal_dir_pretty
FROM pg_ls_waldir();


