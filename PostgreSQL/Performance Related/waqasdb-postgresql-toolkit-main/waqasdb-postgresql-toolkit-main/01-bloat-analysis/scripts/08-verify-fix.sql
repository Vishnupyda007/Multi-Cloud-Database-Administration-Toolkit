cat > 01-bloat-analysis/scripts/08-verify-fix.sql << 'EOF'
-- ============================================================
-- PostgreSQL Bloat Lab
-- Script 08: Verify Fix — Complete Health Check
-- Author: Waqas Ahmad | WaqasDB (waqasdb.com)
-- ============================================================
--
-- USAGE: psql -d bloat_lab -f 08-verify-fix.sql
--
-- PURPOSE: Comprehensive verification that bloat has been fixed.
--          Check tuple level, page level, and index health.
-- ============================================================

-- 1. Final Table Sizes
SELECT
    'FINAL STATE' AS measurement,
    pg_size_pretty(pg_relation_size('user_sessions')) AS data_size,
    pg_size_pretty(pg_indexes_size('user_sessions')) AS index_size,
    pg_size_pretty(pg_total_relation_size('user_sessions')) AS total_size;

-- 2. Final Tuple Analysis
SELECT
    'user_sessions' AS table_name,
    tuple_count AS live_tuples,
    dead_tuple_count AS dead_tuples,
    ROUND(tuple_percent::numeric, 2) AS live_pct,
    ROUND(dead_tuple_percent::numeric, 2) AS dead_pct,
    ROUND(free_percent::numeric, 2) AS free_pct
FROM pgstattuple('user_sessions');

-- 3. Final Page Health
SELECT
    CASE
        WHEN avail = 0 THEN '1-FULL: Fully Packed'
        WHEN avail <= 1024 THEN '2-MINOR: Minor Gaps'
        WHEN avail <= 2048 THEN '3-MODERATE: Moderate Holes'
        ELSE '4-HAS_FREE: Has Free Space'
    END AS page_health,
    count(*) AS pages,
    ROUND(count(*) * 100.0 /
        (SELECT count(*) FROM pg_freespace('user_sessions')), 2
    ) AS pct_of_table
FROM pg_freespace('user_sessions')
GROUP BY 1
ORDER BY 1;

-- 4. Page Summary
SELECT
    count(*) AS total_pages,
    count(*) FILTER (WHERE avail = 0) AS fully_packed,
    ROUND(count(*) FILTER (WHERE avail = 0) * 100.0 / count(*), 2) AS pct_packed
FROM pg_freespace('user_sessions');

-- 5. Dead Tuple Check
SELECT
    relname,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_autovacuum,
    vacuum_count,
    autovacuum_count
FROM pg_stat_user_tables
WHERE relname = 'user_sessions';

-- 6. Index Health
SELECT
    indexrelname AS index_name,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    idx_scan AS times_used,
    idx_tup_read AS tuples_read
FROM pg_stat_user_indexes
WHERE relname = 'user_sessions';
EOF