cat > 01-bloat-analysis/scripts/07-fix-vacuum-full.sql << 'EOF'
-- ============================================================
-- PostgreSQL Bloat Lab
-- Script 07: Fix Method 2 — VACUUM FULL
-- Author: Waqas Ahmad | WaqasDB (waqasdb.com)
-- ============================================================
--
-- USAGE: psql -d bloat_lab -f 07-fix-vacuum-full.sql
--
-- PURPOSE: Demonstrate that VACUUM FULL rewrites the table
--          and actually shrinks the file size.
--
-- ⚠️ WARNING: VACUUM FULL acquires ACCESS EXCLUSIVE lock!
--    The table is completely LOCKED during this operation.
--    No reads, no writes until finished.
--    On an 18TB table = HOURS of downtime.
--    NEVER run on production during peak hours!
--
-- PRODUCTION SAFE: ❌ NO — Use pg_repack instead
-- ============================================================

-- 1. Size BEFORE vacuum full
SELECT
    'BEFORE VACUUM FULL' AS stage,
    pg_size_pretty(pg_relation_size('user_sessions')) AS data_size,
    pg_size_pretty(pg_indexes_size('user_sessions')) AS index_size,
    pg_size_pretty(pg_total_relation_size('user_sessions')) AS total_size;

-- 2. Run VACUUM FULL (this will take a while)
VACUUM FULL VERBOSE user_sessions;

-- 3. Size AFTER vacuum full
SELECT
    'AFTER VACUUM FULL' AS stage,
    pg_size_pretty(pg_relation_size('user_sessions')) AS data_size,
    pg_size_pretty(pg_indexes_size('user_sessions')) AS index_size,
    pg_size_pretty(pg_total_relation_size('user_sessions')) AS total_size;

-- 4. Verify file was actually rewritten
SELECT
    tuple_count AS live_tuples,
    dead_tuple_count AS dead_tuples,
    ROUND(tuple_percent::numeric, 2) AS live_pct,
    ROUND(dead_tuple_percent::numeric, 2) AS dead_pct,
    ROUND(free_percent::numeric, 2) AS free_pct
FROM pgstattuple('user_sessions');

-- KEY OBSERVATION:
-- Table size should be roughly HALF of bloated size
-- dead_tuples = 0
-- free_percent should be < 2% (near optimal)
EOF