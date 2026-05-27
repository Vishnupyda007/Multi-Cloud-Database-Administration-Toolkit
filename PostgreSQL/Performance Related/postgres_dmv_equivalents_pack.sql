
-- PostgreSQL DMV/DBCC Equivalents Script Pack
-- Cloud SQL for PostgreSQL friendly
-- Author: M365 Copilot
-- Date: 2025-11-20
-- Usage: Execute blocks as needed. Some queries require extensions or specific versions.

/*
Prerequisites / Notes
- Run in the target database.
- Some views require roles with adequate privileges (e.g., cloudsqlsuperuser in Cloud SQL).
- Optional extensions: pg_stat_statements, pgstattuple, amcheck.
- For IO timing, set: track_io_timing=on (Cloud SQL flag) and restart.
*/

------------------------------
-- 0) Environment & Version
------------------------------
SELECT version() AS postgres_version;
SELECT name, setting FROM pg_settings WHERE name IN (
  'compute_query_id','shared_preload_libraries','track_io_timing','log_lock_waits','log_temp_files');

------------------------------
-- 1) Active Sessions & Waits (SQL Server: dm_exec_requests/sessions)
------------------------------
-- Current activity
SELECT pid, usename, datname, state, wait_event_type, wait_event,
       query_start, NOW() - query_start AS runtime,
       client_addr, application_name,
       LEFT(query, 2000) AS query
FROM pg_stat_activity
ORDER BY runtime DESC NULLS LAST;

-- Blocking relationships
WITH locks AS (
  SELECT pid, locktype, mode, granted, relation::regclass AS relation
  FROM pg_locks
)
SELECT a.pid AS blocker_pid,
       b.pid AS blocked_pid,
       a.query AS blocker_query,
       b.query AS blocked_query
FROM pg_stat_activity a
JOIN pg_stat_activity b ON a.pid <> b.pid
JOIN pg_locks la ON la.pid = a.pid AND la.granted
JOIN pg_locks lb ON lb.pid = b.pid AND NOT lb.granted AND la.locktype = lb.locktype
WHERE a.state <> 'idle';

------------------------------
-- 2) Locks Snapshot (SQL Server: dm_tran_locks)
------------------------------
SELECT pid, locktype, mode, granted, relation::regclass AS relation
FROM pg_locks
ORDER BY granted DESC, pid;

------------------------------
-- 3) Query Performance (SQL Server: dm_exec_query_stats)
-- Requires: pg_stat_statements
------------------------------
SELECT queryid,
       calls,
       total_exec_time AS total_ms,
       mean_exec_time AS avg_ms,
       rows,
       LEFT(query, 2000) AS query
FROM pg_stat_statements
ORDER BY total_ms DESC
LIMIT 50;

-- Slowest by mean time
SELECT queryid, calls,
       mean_exec_time AS avg_ms,
       LEFT(query, 2000) AS query
FROM pg_stat_statements
ORDER BY avg_ms DESC
LIMIT 25;

------------------------------
-- 4) Space Usage (SQL Server: dm_db_file_space_usage)
------------------------------
-- Database size
SELECT pg_size_pretty(pg_database_size(current_database())) AS db_size;

-- Per schema table sizes
SELECT n.nspname AS schema,
       c.relname AS table,
       pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
       pg_size_pretty(pg_relation_size(c.oid)) AS data_size,
       pg_size_pretty(pg_indexes_size(c.oid)) AS index_size
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
ORDER BY pg_total_relation_size(c.oid) DESC
LIMIT 50;

------------------------------
-- 5) Index Usage (SQL Server: dm_db_index_physical_stats)
------------------------------
SELECT schemaname, relname AS table_name, indexrelname AS index_name,
       idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC NULLS LAST
LIMIT 50;

------------------------------
-- 6) Table & Index Bloat (SQL Server: DBCC SHOWCONTIG)
-- Option A: pgstattuple (requires: CREATE EXTENSION pgstattuple)
------------------------------
-- Example: replace schema.table
-- SELECT * FROM pgstattuple('schema.table');

-- Estimate bloat without pgstattuple (quick heuristic)
WITH table_stats AS (
  SELECT c.oid,
         n.nspname AS schema,
         c.relname AS table,
         pg_relation_size(c.oid) AS size_bytes,
         COALESCE(NULLIF(s.n_live_tup,0),1) AS live_tuples
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  LEFT JOIN pg_stat_user_tables s ON s.relid = c.oid
  WHERE c.relkind = 'r'
)
SELECT schema, table,
       pg_size_pretty(size_bytes) AS table_size,
       live_tuples,
       (size_bytes / GREATEST(live_tuples,1)) AS bytes_per_tuple_estimate
FROM table_stats
ORDER BY bytes_per_tuple_estimate DESC NULLS LAST
LIMIT 50;

------------------------------
-- 7) I/O Metrics (SQL Server: dm_io_virtual_file_stats)
-- PG14+: pg_stat_io view; otherwise rely on buffer hit stats and track_io_timing
------------------------------
-- PG14+:
-- SELECT * FROM pg_stat_io;  -- uncomment on servers that support it

-- Buffer hit ratio per relation (approx)
SELECT relname,
       SUM(blks_hit) AS blks_hit,
       SUM(blks_read) AS blks_read,
       ROUND(100.0 * SUM(blks_hit) / NULLIF(SUM(blks_hit)+SUM(blks_read),0), 2) AS hit_ratio_percent
FROM pg_statio_user_tables
GROUP BY relname
ORDER BY hit_ratio_percent ASC NULLS LAST
LIMIT 25;

------------------------------
-- 8) WAL Metrics (volume & segments)
------------------------------
-- Cumulative WAL since reset (PG14+)
SELECT wal_bytes,
       pg_size_pretty(wal_bytes) AS wal_pretty,
       stats_reset
FROM pg_stat_wal;

-- Current WAL directory occupancy (requires privileges)
SELECT pg_size_pretty(SUM(size)) AS wal_dir_pretty
FROM pg_ls_waldir();

-- Segment count * segment size
WITH segs AS (
  SELECT COUNT(*) AS n FROM pg_ls_waldir() WHERE name <> 'archive_status'
)
SELECT n AS wal_segments,
       pg_size_pretty(n * pg_size_bytes(current_setting('wal_segment_size'))) AS approx_total
FROM segs;

------------------------------
-- 9) Replication Status
------------------------------
SELECT pid, usename, application_name, client_addr,
       state, sync_state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
       write_lag, flush_lag, replay_lag
FROM pg_stat_replication;

------------------------------
-- 10) Autovacuum & Progress
------------------------------
SELECT * FROM pg_stat_progress_vacuum;
SELECT * FROM pg_stat_progress_create_index;

------------------------------
-- 11) Plans for slow queries (SQL Server: dm_exec_query_plan)
------------------------------
-- After identifying a slow query text from pg_stat_statements, run:
-- EXPLAIN (ANALYZE, BUFFERS, VERBOSE) <your_query_here>;

------------------------------
-- 12) Integrity Checks (SQL Server: DBCC CHECKDB)
-- amcheck extension (btree checks) — requires: CREATE EXTENSION amcheck
------------------------------
-- Example: check a btree index thoroughly (replace schema.index)
-- SELECT bt_index_check(index := 'schema.index', heapallindexed := true);

-- Parent/child linkage check
-- SELECT bt_index_parent_check('schema.index', true);

-- List btree indexes for a table
SELECT i.relname AS index_name
FROM pg_class t
JOIN pg_index x ON x.indrelid = t.oid
JOIN pg_class i ON i.oid = x.indexrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'public' AND t.relname = 'your_table';

------------------------------
-- 13) Housekeeping: Reset Stats
------------------------------
-- Reset query stats (Cloud SQL supported)
SELECT pg_stat_statements_reset();

-- Reset shared WAL stats
SELECT pg_stat_reset_shared('wal');

------------------------------
-- 14) Extension Presence & Enable Templates
------------------------------
SELECT extname, extversion FROM pg_extension;
-- To enable (run per DB):
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
-- CREATE EXTENSION IF NOT EXISTS pgstattuple;
-- CREATE EXTENSION IF NOT EXISTS amcheck;

