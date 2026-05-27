================================================================================
  PostgreSQL Performance Audit — OneC_4681
  All Data Collection Scripts
  Date: 15 April 2026
================================================================================

  These scripts were executed across two database connections:
    - Connection 1 : postgres db  (pg_stat_statements lives here)
    - Connection 2 : OneC_4681 db (schema, tables, indexes, procedures)

  Run order is preserved exactly as used during the audit.

================================================================================
  CONNECTION 1 — postgres database
================================================================================

------------------------------------------------------------------------
-- SCRIPT 01: Verify server version
------------------------------------------------------------------------

SELECT version();


------------------------------------------------------------------------
-- SCRIPT 02: List all databases on the instance
------------------------------------------------------------------------

SELECT datname FROM pg_database;


------------------------------------------------------------------------
-- SCRIPT 03: Top queries by total execution time (filtered to OneC_4681)
--            Source: pg_stat_statements (must be enabled as extension)
------------------------------------------------------------------------

SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    stddev_exec_time,
    rows,
    shared_blks_hit,
    shared_blks_read,
    ROUND(
        (shared_blks_read * 100.0
         / NULLIF(shared_blks_hit + shared_blks_read, 0))::numeric, 2
    ) AS cache_miss_pct
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'OneC_4681')
ORDER BY total_exec_time DESC
LIMIT 20;


================================================================================
  CONNECTION 2 — OneC_4681 database
================================================================================

------------------------------------------------------------------------
-- SCRIPT 04: Verify server version
------------------------------------------------------------------------

SELECT version();


------------------------------------------------------------------------
-- SCRIPT 05: List all user tables — page 1 (rows 1–50)
------------------------------------------------------------------------

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_type   = 'BASE TABLE'
  AND table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name
LIMIT 50;


------------------------------------------------------------------------
-- SCRIPT 06: List all user tables — page 2 (rows 51–150)
------------------------------------------------------------------------

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_type   = 'BASE TABLE'
  AND table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name
LIMIT 100 OFFSET 50;


------------------------------------------------------------------------
-- SCRIPT 07: Table statistics — sequential scans, dead tuples, vacuum
--            Top 25 tables by seq_scan count
--            Identifies missing indexes and autovacuum gaps
------------------------------------------------------------------------

SELECT
    relname,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_live_tup,
    n_dead_tup,
    ROUND(
        100.0 * n_dead_tup
        / NULLIF(n_live_tup + n_dead_tup, 0), 2
    )                  AS dead_pct,
    last_autovacuum,
    last_autoanalyze
FROM pg_stat_user_tables
ORDER BY seq_scan DESC
LIMIT 25;


------------------------------------------------------------------------
-- SCRIPT 08: Index usage — zero / low-use indexes (bottom 40)
--            Candidates for removal
------------------------------------------------------------------------

SELECT
    relname        AS table_name,
    indexrelname   AS index_name,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC
LIMIT 40;


------------------------------------------------------------------------
-- SCRIPT 09: Index usage — hot indexes (top 30 by scan count)
--            Confirms which indexes are load-bearing
------------------------------------------------------------------------

SELECT
    relname        AS table_name,
    indexrelname   AS index_name,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan > 0
ORDER BY idx_scan DESC
LIMIT 30;


------------------------------------------------------------------------
-- SCRIPT 10: Stored procedure source code
--            Retrieves full body of the 6 most critical procedures
------------------------------------------------------------------------

SELECT
    n.nspname                            AS schema,
    p.proname                            AS function_name,
    pg_get_function_arguments(p.oid)     AS args,
    p.prosrc                             AS source
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
      'usp_get_open_jobs_for_referral',
      'usp_get_notifications',
      'usp_get_referralcandidates',
      'usp_get_candidateid',
      'usp_get_master_data_alpha',
      'usp_referal_updatecandidateresumedetails'
  )
ORDER BY p.proname;


------------------------------------------------------------------------
-- SCRIPT 11: Index definitions for the 8 highest-traffic tables
--            Used to identify duplicate and redundant indexes
------------------------------------------------------------------------

SELECT
    indexname,
    tablename,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN (
      'trn_candidate_jobapplication',
      'trn_notifications',
      'trn_requisition',
      'trn_candidate_personaldetails',
      'trn_referral_ownership',
      'trn_candidate_logininfo',
      'trn_requisitionposting',
      'mas_employer',
      'trn_candidate_address'
  )
ORDER BY tablename, indexname;


------------------------------------------------------------------------
-- SCRIPT 12: Server configuration parameters
--            Reviews all performance-relevant GUC settings
------------------------------------------------------------------------

SELECT
    name,
    setting,
    unit,
    context
FROM pg_settings
WHERE name IN (
    'autovacuum',
    'autovacuum_vacuum_scale_factor',
    'autovacuum_analyze_scale_factor',
    'autovacuum_vacuum_threshold',
    'autovacuum_analyze_threshold',
    'autovacuum_vacuum_cost_delay',
    'autovacuum_max_workers',
    'shared_buffers',
    'work_mem',
    'effective_cache_size',
    'max_connections',
    'random_page_cost',
    'effective_io_concurrency',
    'enable_partitionwise_join',
    'enable_partitionwise_aggregate',
    'max_parallel_workers_per_gather',
    'max_parallel_workers',
    'jit',
    'default_statistics_target'
)
ORDER BY name;


------------------------------------------------------------------------
-- SCRIPT 13: Duplicate and redundant index detection
--            Expands index column lists from pg_index for comparison
------------------------------------------------------------------------

SELECT
    t.relname                                                   AS table_name,
    ix.relname                                                  AS index_name,
    array_to_string(array_agg(a.attname ORDER BY k.i), ', ')   AS columns,
    pg_size_pretty(pg_relation_size(ix.oid))                   AS index_size,
    i.indisunique,
    i.indisprimary
FROM pg_index i
JOIN pg_class t       ON t.oid  = i.indrelid
JOIN pg_class ix      ON ix.oid = i.indexrelid
JOIN pg_namespace n   ON n.oid  = t.relnamespace
CROSS JOIN LATERAL unnest(i.indkey) WITH ORDINALITY AS k(attnum, i)
JOIN pg_attribute a   ON a.attrelid = t.oid AND a.attnum = k.attnum
WHERE n.nspname = 'public'
  AND t.relname IN (
      'trn_candidate_jobapplication',
      'trn_requisition',
      'trn_notifications',
      'trn_referral_ownership',
      'trn_candidate_personaldetails',
      'trn_candidate_logininfo',
      'trn_requisitionposting',
      'mas_employer',
      'trn_candidate_address'
  )
GROUP BY t.relname, ix.relname, ix.oid, i.indisunique, i.indisprimary
ORDER BY t.relname, columns;


------------------------------------------------------------------------
-- SCRIPT 14: Foreign key constraints — audit for references to _old tables
------------------------------------------------------------------------

SELECT
    c.conname        AS constraint_name,
    c.contype,
    t.relname        AS table_name,
    a.attname        AS column_name,
    ft.relname       AS foreign_table,
    fa.attname       AS foreign_column
FROM pg_constraint c
JOIN pg_class t      ON t.oid  = c.conrelid
JOIN pg_attribute a  ON a.attrelid = t.oid AND a.attnum = ANY(c.conkey)
LEFT JOIN pg_class ft     ON ft.oid = c.confrelid
LEFT JOIN pg_attribute fa ON fa.attrelid = ft.oid
                         AND fa.attnum   = ANY(c.confkey)
WHERE c.contype = 'f'
  AND t.relnamespace = (
      SELECT oid FROM pg_namespace WHERE nspname = 'public'
  )
ORDER BY t.relname
LIMIT 40;


------------------------------------------------------------------------
-- SCRIPT 15: Column structure — trn_notifications
--            Used to understand filter columns and index design
------------------------------------------------------------------------

SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'trn_notifications'
ORDER BY ordinal_position;


------------------------------------------------------------------------
-- SCRIPT 16: Column structure — trn_candidate_jobapplication
--            Confirms referredemployeeid column exists with no index
------------------------------------------------------------------------

SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name   = 'trn_candidate_jobapplication'
ORDER BY ordinal_position;


------------------------------------------------------------------------
-- SCRIPT 17: Dead-tuple bloat spot-check — trn_accesstoken
------------------------------------------------------------------------

SELECT
    relname,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum,
    autovacuum_count,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE relname = 'trn_accesstoken';


------------------------------------------------------------------------
-- SCRIPT 18: Confirm no index exists on referredemployeeid
--            (trn_candidate_jobapplication — root cause of 10B seq reads)
------------------------------------------------------------------------

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename  = 'trn_candidate_jobapplication'
ORDER BY indexname;


------------------------------------------------------------------------
-- SCRIPT 19: Staging table scan patterns
--            Identifies ETL tables with no indexes
------------------------------------------------------------------------

SELECT
    relname,
    n_live_tup,
    seq_scan,
    seq_tup_read,
    idx_scan
FROM pg_stat_user_tables
WHERE relname LIKE 'stg_%'
ORDER BY seq_tup_read DESC;


------------------------------------------------------------------------
-- SCRIPT 20: Full stored procedure inventory
--            Audits volatility (VOLATILE/STABLE/IMMUTABLE)
--            and parallelism safety (SAFE/UNSAFE/RESTRICTED)
------------------------------------------------------------------------

SELECT
    n.nspname   AS schema,
    p.proname   AS function_name,
    p.prokind,
    CASE p.provolatile
        WHEN 'i' THEN 'IMMUTABLE'
        WHEN 's' THEN 'STABLE'
        WHEN 'v' THEN 'VOLATILE'
    END         AS volatility,
    CASE p.proparallel
        WHEN 's' THEN 'PARALLEL SAFE'
        WHEN 'r' THEN 'PARALLEL RESTRICTED'
        WHEN 'u' THEN 'PARALLEL UNSAFE'
    END         AS parallel_safety
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname LIKE 'usp_%'
ORDER BY p.proname;


================================================================================
  BONUS — ONGOING HEALTH-CHECK SCRIPTS
  Run weekly to catch new issues early
================================================================================

------------------------------------------------------------------------
-- HEALTH 01: Top 20 tables by sequential scan volume
--            New entries here signal missing indexes
------------------------------------------------------------------------

SELECT
    relname,
    seq_scan,
    seq_tup_read,
    n_live_tup,
    ROUND(
        100.0 * n_dead_tup
        / NULLIF(n_live_tup + n_dead_tup, 0), 2
    ) AS dead_pct,
    last_autovacuum
FROM pg_stat_user_tables
ORDER BY seq_scan DESC
LIMIT 20;


------------------------------------------------------------------------
-- HEALTH 02: Tables with significant dead-tuple bloat (> 5%)
------------------------------------------------------------------------

SELECT
    relname,
    n_live_tup,
    n_dead_tup,
    ROUND(
        100.0 * n_dead_tup
        / NULLIF(n_live_tup + n_dead_tup, 0), 2
    )               AS dead_pct,
    last_autovacuum,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE n_dead_tup > 100
  AND (100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0)) > 5
ORDER BY dead_pct DESC;


------------------------------------------------------------------------
-- HEALTH 03: Indexes with zero scans since last stats reset
--            Run after confirming reset date via:
--              SELECT stats_reset FROM pg_stat_bgwriter;
------------------------------------------------------------------------

SELECT
    schemaname,
    relname        AS table_name,
    indexrelname   AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;


------------------------------------------------------------------------
-- HEALTH 04: Top 15 slowest queries right now (pg_stat_statements)
--            Run on the postgres database
------------------------------------------------------------------------

SELECT
    LEFT(query, 80)                               AS query_snippet,
    calls,
    ROUND(mean_exec_time::numeric, 2)             AS mean_ms,
    ROUND(stddev_exec_time::numeric, 2)           AS stddev_ms,
    ROUND(total_exec_time::numeric, 0)            AS total_ms,
    shared_blks_hit + shared_blks_read            AS total_blks
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 15;


------------------------------------------------------------------------
-- HEALTH 05: Tables missing autovacuum (never ran or inactive)
------------------------------------------------------------------------

SELECT
    relname,
    n_live_tup,
    n_dead_tup,
    last_autovacuum,
    last_vacuum,
    autovacuum_count
FROM pg_stat_user_tables
WHERE (last_autovacuum IS NULL AND last_vacuum IS NULL)
   OR autovacuum_count = 0
ORDER BY n_live_tup DESC;


------------------------------------------------------------------------
-- HEALTH 06: Cache hit ratio per table
--            Any value below 99% warrants investigation
------------------------------------------------------------------------

SELECT
    relname,
    heap_blks_hit,
    heap_blks_read,
    ROUND(
        100.0 * heap_blks_hit
        / NULLIF(heap_blks_hit + heap_blks_read, 0), 2
    ) AS cache_hit_pct
FROM pg_statio_user_tables
WHERE heap_blks_hit + heap_blks_read > 0
ORDER BY cache_hit_pct ASC
LIMIT 20;


------------------------------------------------------------------------
-- HEALTH 07: Long-running queries (active sessions > 30 seconds)
--            Run on any database as a live operations check
------------------------------------------------------------------------

SELECT
    pid,
    now() - pg_stat_activity.query_start  AS duration,
    query,
    state,
    wait_event_type,
    wait_event
FROM pg_stat_activity
WHERE state != 'idle'
  AND query_start < now() - INTERVAL '30 seconds'
ORDER BY duration DESC;


------------------------------------------------------------------------
-- HEALTH 08: Table size report — top 20 by total size
------------------------------------------------------------------------

SELECT
    schemaname,
    relname                                               AS table_name,
    pg_size_pretty(pg_total_relation_size(
        quote_ident(schemaname) || '.' || quote_ident(relname)
    ))                                                    AS total_size,
    pg_size_pretty(pg_relation_size(
        quote_ident(schemaname) || '.' || quote_ident(relname)
    ))                                                    AS table_size,
    pg_size_pretty(pg_indexes_size(
        quote_ident(schemaname) || '.' || quote_ident(relname)
    ))                                                    AS index_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(
    quote_ident(schemaname) || '.' || quote_ident(relname)
) DESC
LIMIT 20;


------------------------------------------------------------------------
-- HEALTH 09: Reset statistics baseline
--            Run AFTER applying fixes to start clean measurements
--            Execute script 09a on postgres db, 09b on OneC_4681
------------------------------------------------------------------------

-- 09a: Run on postgres database
SELECT pg_stat_statements_reset();

-- 09b: Run on OneC_4681 database
SELECT pg_stat_reset();


================================================================================
  CATALOG REFERENCE
  Which system catalog each script queries
================================================================================

  Script 01, 04  |  pg_version()                         | Version check
  Script 02      |  pg_database                          | DB inventory
  Script 03      |  pg_stat_statements                   | Query workload (postgres db)
  Script 05, 06  |  information_schema.tables            | Table inventory
  Script 07      |  pg_stat_user_tables                  | Seq scans / dead tuples / vacuum
  Script 08, 09  |  pg_stat_user_indexes                 | Index usage stats
  Script 10      |  pg_proc + pg_namespace               | Stored procedure source
  Script 11      |  pg_indexes                           | Index definitions
  Script 12      |  pg_settings                          | Server GUC configuration
  Script 13      |  pg_index + pg_class + pg_attribute   | Duplicate index detection
  Script 14      |  pg_constraint + pg_attribute         | Foreign key audit
  Script 15, 16  |  information_schema.columns           | Column structure
  Script 17      |  pg_stat_user_tables                  | Bloat spot-check
  Script 18      |  pg_indexes                           | Confirm missing index
  Script 19      |  pg_stat_user_tables                  | Staging table patterns
  Script 20      |  pg_proc                              | Volatility / parallelism audit
  Health 01–09   |  pg_stat_user_tables / indexes /      | Ongoing weekly health checks
                 |  pg_statio_user_tables /              |
                 |  pg_stat_activity / pg_stat_bgwriter  |

================================================================================
  END OF FILE
  PostgreSQL Performance Audit Scripts — OneC_4681 — 15 April 2026
================================================================================
