
-- pg_stat_statements Monitoring & Tuning Script Pack
-- Cloud SQL for PostgreSQL
-- Author: M365 Copilot
-- Usage: Run blocks as needed. Requires pg_stat_statements enabled and extension created.

/*
Prereqs
 - Flags: shared_preload_libraries='pg_stat_statements', pg_stat_statements.max, pg_stat_statements.track, pg_stat_statements.save
 - CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
*/

------------------------------
-- 0. Quick Health & Setup
------------------------------
-- Is extension installed? (current DB)
SELECT extname, extversion FROM pg_extension WHERE extname='pg_stat_statements';

-- Library loaded? (instance-level)
SELECT name, setting FROM pg_settings WHERE name IN (
  'shared_preload_libraries','pg_stat_statements.max','pg_stat_statements.track','pg_stat_statements.save','compute_query_id','track_io_timing');

-- Info view (PG14+): deallocations & last reset
SELECT * FROM pg_stat_statements_info;

------------------------------
-- 1. Workload Top by Total Time
------------------------------
SELECT (total_exec_time + COALESCE(total_plan_time,0)) AS total_time_ms,
       calls,
       mean_exec_time AS avg_exec_ms,
       COALESCE(mean_plan_time,0) AS avg_plan_ms,
       rows,
       query
FROM pg_stat_statements
ORDER BY total_time_ms DESC
LIMIT 50;

------------------------------
-- 2. Slowest by Mean Time
------------------------------
SELECT (mean_exec_time + COALESCE(mean_plan_time,0)) AS mean_time_ms,
       calls,
       rows,
       query
FROM pg_stat_statements
ORDER BY mean_time_ms DESC
LIMIT 50;

------------------------------
-- 3. Highest Buffer Activity (proxy for I/O)
------------------------------
SELECT (shared_blks_hit + shared_blks_read + shared_blks_dirtied + shared_blks_written) AS total_buffer_ops,
       calls,
       query
FROM pg_stat_statements
ORDER BY total_buffer_ops DESC
LIMIT 20;

------------------------------
-- 4. Worst Cache Hit Ratio
------------------------------
SELECT 100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0) AS hit_percent,
       calls,
       query
FROM pg_stat_statements
WHERE (shared_blks_hit + shared_blks_read) > 0
ORDER BY hit_percent ASC
LIMIT 20;

------------------------------
-- 5. High Variability (stddev)
------------------------------
SELECT stddev_exec_time AS stddev_ms,
       mean_exec_time AS mean_ms,
       calls,
       query
FROM pg_stat_statements
WHERE stddev_exec_time IS NOT NULL
ORDER BY stddev_ms DESC
LIMIT 20;

------------------------------
-- 6. Write-Heavy Statements
------------------------------
SELECT shared_blks_written + local_blks_written + temp_blks_written AS writes,
       calls,
       query
FROM pg_stat_statements
ORDER BY writes DESC
LIMIT 20;

------------------------------
-- 7. JIT Impact (PG11+)
------------------------------
SELECT jit_functions,
       jit_inlining_count,
       jit_optimization_count,
       jit_emission_count,
       query
FROM pg_stat_statements
WHERE (jit_functions + jit_inlining_count + jit_optimization_count + jit_emission_count) > 0
ORDER BY (jit_functions + jit_inlining_count + jit_optimization_count + jit_emission_count) DESC
LIMIT 20;

------------------------------
-- 8. Normalize by User/DB (for multi-tenant)
------------------------------
SELECT userid::regrole AS role,
       dbid::regdatabase AS db,
       SUM(total_exec_time) AS total_exec_ms,
       SUM(calls) AS calls
FROM pg_stat_statements
GROUP BY 1,2
ORDER BY total_exec_ms DESC
LIMIT 20;

------------------------------
-- 9. Indexing Candidates: High time + many rows
------------------------------
SELECT query,
       calls,
       rows,
       total_exec_time AS total_ms
FROM pg_stat_statements
WHERE query ILIKE 'select %'
ORDER BY total_ms DESC, rows DESC
LIMIT 50;

------------------------------
-- 10. Parameter Skew Detector (optional pattern)
-- Look for same fingerprint with wide mean/median gap (requires extra math)
------------------------------
-- Example: rank by mean time but filter low calls
SELECT queryid,
       SUM(calls) AS calls,
       SUM(total_exec_time) AS total_ms,
       AVG(mean_exec_time) AS avg_ms
FROM pg_stat_statements
GROUP BY queryid
HAVING SUM(calls) > 100
ORDER BY avg_ms DESC
LIMIT 20;

------------------------------
-- 11. Maintenance: Safe Reset (Cloud SQL supported)
------------------------------
-- WARNING: Resets cumulative stats for current DB only.
SELECT pg_stat_statements_reset();

------------------------------
-- 12. Per-table counter reset (core stats)
------------------------------
-- Reset all non-system relations (requires cloudsqlsuperuser role)
-- Uncomment when needed:
-- SELECT relname, pg_stat_reset_single_table_counters(oid)
-- FROM pg_class
-- WHERE reltype=0 AND relname NOT LIKE 'pg_%';

------------------------------
-- 13. EXPLAIN Integration Helper (copy-paste)
------------------------------
-- After identifying slow query text, run:
-- EXPLAIN (ANALYZE, BUFFERS, VERBOSE) <your_query>;

------------------------------
-- 14. Eviction Watch (increase max if rising)
------------------------------
SELECT dealloc, stats_reset
FROM pg_stat_statements_info;

------------------------------
-- 15. IO Timing (enable track_io_timing at instance level)
------------------------------
SELECT query,
       blk_read_time, blk_write_time,
       calls
FROM pg_stat_statements
ORDER BY (blk_read_time + blk_write_time) DESC
LIMIT 20;

