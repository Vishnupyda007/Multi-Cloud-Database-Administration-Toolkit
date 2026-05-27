cat > 01-bloat-analysis/scripts/06-fix-vacuum.sql << 'EOF'
-- ============================================================
-- PostgreSQL Bloat Lab
-- Script 06: Fix Attempt 1 — Regular VACUUM
-- Author: Waqas Ahmad | WaqasDB (waqasdb.com)
-- ============================================================
--
-- USAGE: psql -d bloat_lab -f 06-fix-vacuum.sql
--
-- PURPOSE: Demonstrate that regular VACUUM cleans dead tuples
--          but does NOT shrink the file size.
--
-- PRODUCTION SAFE: Yes — VACUUM does not lock the table
-- ============================================================

-- 1. Size BEFORE vacuum
SELECT
    'BEFORE VACUUM' AS stage,
    pg_size_pretty(pg_relation_size('user_sessions')) AS data_size;

-- 2. Run VACUUM
VACUUM VERBOSE user_sessions;

-- 3. Size AFTER vacuum
SELECT
    'AFTER VACUUM' AS stage,
    pg_size_pretty(pg_relation_size('user_sessions')) AS data_size;

-- 4. Dead tuple check
SELECT
    relname,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    vacuum_count
FROM pg_stat_user_tables
WHERE relname = 'user_sessions';

-- 5. Tuple analysis after vacuum
SELECT
    pg_size_pretty(table_len) AS table_size,
    tuple_count AS live_tuples,
    dead_tuple_count AS dead_tuples,
    ROUND(dead_tuple_percent::numeric, 2) AS dead_pct,
    ROUND(free_percent::numeric, 2) AS free_pct
FROM pgstattuple('user_sessions');

-- KEY OBSERVATION:
-- Dead tuples should be 0 or near 0
-- BUT table size is UNCHANGED
-- free_percent is STILL high
-- VACUUM marks space as reusable but NEVER returns it to OS
EOF