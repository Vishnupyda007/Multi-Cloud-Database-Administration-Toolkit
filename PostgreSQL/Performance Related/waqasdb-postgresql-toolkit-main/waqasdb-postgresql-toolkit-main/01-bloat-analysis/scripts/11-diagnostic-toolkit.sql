cat > 01-bloat-analysis/scripts/11-diagnostic-toolkit.sql << 'EOF'
-- ============================================================
-- PostgreSQL Bloat Lab
-- Script 11: Reusable Diagnostic Toolkit
-- Author: Waqas Ahmad | WaqasDB (waqasdb.com)
-- ============================================================
--
-- USAGE: psql -d YOUR_DATABASE -f 11-diagnostic-toolkit.sql
--
-- PURPOSE: Production-ready diagnostic queries.
--          Use these on ANY PostgreSQL database to find
--          bloat, unused indexes, and performance issues.
--
-- SAFE TO RUN: Yes — all queries are read-only SELECT statements
-- ============================================================


-- ═══════════════════════════════════════
-- 1. BLOATED TABLES
-- ═══════════════════════════════════════

SELECT
    schemaname || '.' || relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS data_size,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    ROUND(n_dead_tup::numeric /
        NULLIF(n_live_tup, 0) * 100, 2) AS dead_pct,
    last_autovacuum,
    CASE
        WHEN n_dead_tup::numeric / NULLIF(n_live_tup, 0) > 0.20
        THEN 'CRITICAL — Vacuum immediately'
        WHEN n_dead_tup::numeric / NULLIF(n_live_tup, 0) > 0.10
        THEN 'WARNING — Schedule vacuum'
        WHEN n_dead_tup::numeric / NULLIF(n_live_tup, 0) > 0.05
        THEN 'MONITOR — Watch this table'
        ELSE 'HEALTHY'
    END AS status
FROM pg_stat_user_tables
WHERE n_live_tup > 0
ORDER BY n_dead_tup DESC
LIMIT 20;


-- ═══════════════════════════════════════
-- 2. UNUSED INDEXES (Wasting Disk & Slowing Writes)
-- ═══════════════════════════════════════

SELECT
    schemaname || '.' || relname AS table_name,
    indexrelname AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    idx_scan AS times_used,
    idx_tup_read AS tuples_read
FROM pg_stat_user_indexes
WHERE idx_scan = 0
AND schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC
LIMIT 20;


-- ═══════════════════════════════════════
-- 3. TABLES NEEDING INDEXES (Too Many Sequential Scans)
-- ═══════════════════════════════════════

SELECT
    schemaname || '.' || relname AS table_name,
    seq_scan,
    seq_tup_read,
    idx_scan,
    pg_size_pretty(pg_relation_size(relid)) AS size,
    CASE WHEN seq_scan + idx_scan > 0
        THEN ROUND(idx_scan::numeric / (seq_scan + idx_scan) * 100, 2)
        ELSE 0
    END AS idx_usage_pct,
    CASE WHEN seq_scan > idx_scan AND pg_relation_size(relid) > 10485760
        THEN 'Consider adding index'
        ELSE 'OK'
    END AS recommendation
FROM pg_stat_user_tables
WHERE seq_scan > 100
AND pg_relation_size(relid) > 10 * 1024 * 1024
ORDER BY seq_tup_read DESC
LIMIT 20;


-- ═══════════════════════════════════════
-- 4. DATABASE CACHE HIT RATIO
-- ═══════════════════════════════════════

SELECT
    datname AS database,
    blks_hit AS cache_hits,
    blks_read AS disk_reads,
    ROUND(blks_hit::numeric /
        NULLIF(blks_hit + blks_read, 0) * 100, 2) AS cache_hit_ratio,
    CASE
        WHEN blks_hit::numeric / NULLIF(blks_hit + blks_read, 0) > 0.99
        THEN 'Excellent (>99%)'
        WHEN blks_hit::numeric / NULLIF(blks_hit + blks_read, 0) > 0.95
        THEN 'Good (>95%)'
        ELSE 'Poor (<95%) — increase shared_buffers'
    END AS status
FROM pg_stat_database
WHERE datname = current_database();


-- ═══════════════════════════════════════
-- 5. TABLE SIZE RANKING
-- ═══════════════════════════════════════

SELECT
    schemaname || '.' || tablename AS table_name,
    pg_size_pretty(pg_total_relation_size(
        schemaname || '.' || tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(
        schemaname || '.' || tablename)) AS data_size,
    pg_size_pretty(pg_indexes_size(
        (schemaname || '.' || tablename)::regclass)) AS index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(
    schemaname || '.' || tablename) DESC
LIMIT 20;


-- ═══════════════════════════════════════
-- 6. AUTOVACUUM STATUS
-- ═══════════════════════════════════════

SELECT
    schemaname || '.' || relname AS table_name,
    n_live_tup,
    n_dead_tup,
    vacuum_count,
    autovacuum_count,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE n_live_tup > 1000
ORDER BY n_dead_tup DESC
LIMIT 20;


-- ═══════════════════════════════════════
-- 7. CURRENT CONNECTIONS
-- ═══════════════════════════════════════

SELECT
    count(*) AS total_connections,
    count(*) FILTER (WHERE state = 'active') AS active,
    count(*) FILTER (WHERE state = 'idle') AS idle,
    count(*) FILTER (WHERE state = 'idle in transaction') AS idle_in_txn,
    (SELECT setting::int FROM pg_settings
     WHERE name = 'max_connections') AS max_connections,
    ROUND(count(*)::numeric /
        (SELECT setting::numeric FROM pg_settings
         WHERE name = 'max_connections') * 100, 2) AS usage_pct
FROM pg_stat_activity
WHERE backend_type = 'client backend';
EOF