
-- Cloud SQL for PostgreSQL: Query Performance Monitoring Script Pack
-- Author: M365 Copilot
-- Date: 2025-11-20
-- Notes:
--  * Run in the target database.
--  * Some blocks require extensions or flags (see Section 0).
--  * Safe for Cloud SQL managed environment; uses supported views/functions.

/*
Section 0. Prereqs (Cloud SQL flags & extensions)
-------------------------------------------------
Recommended instance flags (set via Cloud SQL 'Flags'):
  shared_preload_libraries=pg_stat_statements,auto_explain
  compute_query_id=auto
  pg_stat_statements.max=20000
  pg_stat_statements.track=top
  pg_stat_statements.save=on
  log_min_duration_statement=1000         -- log queries > 1s
  log_lock_waits=on                       -- capture lock waits
  deadlock_timeout=1s
  log_temp_files=0                        -- log all temp file usage
  log_checkpoints=on
  auto_explain.log_min_duration=1000      -- log plans for queries > 1s
  auto_explain.log_analyze=on             -- include runtime stats
  auto_explain.log_buffers=on             -- show buffer usage
  auto_explain.log_wal=on                 -- show WAL usage (PG13+)
  auto_explain.log_timing=off             -- reduce overhead

Create required extensions per database (as privileged user):
  CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
  -- Optional (enable for deeper diagnostics)
  -- CREATE EXTENSION IF NOT EXISTS pg_stat_statements; -- already above

Verify active settings:
  SELECT name, setting FROM pg_settings WHERE name IN (
    'shared_preload_libraries','compute_query_id','pg_stat_statements.max',
    'pg_stat_statements.track','pg_stat_statements.save','log_min_duration_statement',
    'log_lock_waits','deadlock_timeout','log_temp_files','log_checkpoints',
    'auto_explain.log_min_duration','auto_explain.log_analyze',
    'auto_explain.log_buffers','auto_explain.log_wal','auto_explain.log_timing');
*/

--------------------------------------------------
-- 1) Current activity & long runners
--------------------------------------------------
-- Active sessions with wait info
SELECT pid, usename, datname, state, wait_event_type, wait_event,
       query_start, NOW() - query_start AS runtime,
       client_addr, application_name,
       LEFT(query, 2000) AS query
FROM pg_stat_activity
WHERE state <> 'idle'
ORDER BY runtime DESC NULLS LAST;

-- Long-running queries (> 5 minutes)
SELECT pid, usename, NOW() - query_start AS runtime, state,
       LEFT(query, 2000) AS query
FROM pg_stat_activity
WHERE state='active' AND NOW() - query_start > INTERVAL '5 minutes'
ORDER BY runtime DESC;

--------------------------------------------------
-- 2) Blocking chains
--------------------------------------------------
WITH locks AS (
  SELECT pid, locktype, mode, granted, relation::regclass AS relation
  FROM pg_locks
)
SELECT a.pid   AS blocker_pid,
       b.pid   AS blocked_pid,
       a.state AS blocker_state,
       b.state AS blocked_state,
       a.wait_event, b.wait_event,
       LEFT(a.query, 1000) AS blocker_query,
       LEFT(b.query, 1000) AS blocked_query
FROM pg_stat_activity a
JOIN pg_stat_activity b ON a.pid <> b.pid
JOIN pg_locks la ON la.pid = a.pid AND la.granted
JOIN pg_locks lb ON lb.pid = b.pid AND NOT lb.granted AND la.locktype = lb.locktype
WHERE a.state <> 'idle'
ORDER BY blocked_pid;

--------------------------------------------------
-- 3) Top queries by total time (pg_stat_statements)
--------------------------------------------------
SELECT queryid,
       calls,
       ROUND(total_exec_time::numeric,2) AS total_ms,
       ROUND(mean_exec_time::numeric,2)  AS avg_ms,
       rows,
       LEFT(query, 2000) AS query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 50;

-- Slowest by mean time
SELECT queryid, calls,
       ROUND(mean_exec_time::numeric,2) AS avg_ms,
       LEFT(query, 2000) AS query
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 25;

-- Highest buffer activity (proxy for IO)
SELECT (shared_blks_hit + shared_blks_read + shared_blks_dirtied + shared_blks_written) AS total_buffer_ops,
       calls,
       LEFT(query, 2000) AS query
FROM pg_stat_statements
ORDER BY total_buffer_ops DESC
LIMIT 25;

-- Worst cache-hit ratio
SELECT ROUND(100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0),2) AS hit_percent,
       calls,
       LEFT(query, 2000) AS query
FROM pg_stat_statements
WHERE (shared_blks_hit + shared_blks_read) > 0
ORDER BY hit_percent ASC
LIMIT 25;

--------------------------------------------------
-- 4) EXPLAIN helper (copy/paste)
--------------------------------------------------
-- After identifying a slow query text above, run:
-- EXPLAIN (ANALYZE, BUFFERS, WAL, VERBOSE) <your_query_here>;
-- Tip: Wrap DML in a test transaction to avoid data changes:
-- BEGIN; EXPLAIN (ANALYZE, BUFFERS, WAL, VERBOSE) <DML>; ROLLBACK;

--------------------------------------------------
-- 5) IO & WAL overview
--------------------------------------------------
-- IO stats (PG16+): uncomment if supported
-- SELECT * FROM pg_stat_io;

-- WAL generated since last reset
SELECT wal_bytes, pg_size_pretty(wal_bytes) AS wal_pretty, stats_reset
FROM pg_stat_wal;

-- WAL segments & total size (requires privileges for pg_ls_waldir)
-- Total WAL dir size
SELECT pg_size_pretty(SUM(size)) AS wal_dir_pretty
FROM pg_ls_waldir();

-- Segment count * segment size
WITH segs AS (
  SELECT COUNT(*) AS n FROM pg_ls_waldir() WHERE name <> 'archive_status'
)
SELECT n AS wal_segments,
       pg_size_pretty(n * pg_size_bytes(current_setting('wal_segment_size'))) AS approx_total
FROM segs;

--------------------------------------------------
-- 6) Progress views
--------------------------------------------------
SELECT * FROM pg_stat_progress_vacuum;
SELECT * FROM pg_stat_progress_create_index;

--------------------------------------------------
-- 7) Housekeeping
--------------------------------------------------
-- Reset query stats (safe in Cloud SQL)
SELECT pg_stat_statements_reset();

-- Reset shared WAL stats
SELECT pg_stat_reset_shared('wal');

-- List installed extensions
SELECT extname, extversion FROM pg_extension ORDER BY extname;

