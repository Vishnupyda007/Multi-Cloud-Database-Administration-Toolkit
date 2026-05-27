cat > 01-bloat-analysis/scripts/04-measure-bloat-tuples.sql << 'EOF'
-- ============================================================
-- PostgreSQL Bloat Lab
-- Script 04: Measure Bloat at Tuple Level
-- Author: Waqas Ahmad | WaqasDB (waqasdb.com)
-- ============================================================
--
-- USAGE: psql -d bloat_lab -f 04-measure-bloat-tuples.sql
--
-- PURPOSE: Measure bloat using pgstattuple extension.
--          This shows live tuples, dead tuples, and free space
--          as percentages of total table size.
-- ============================================================

-- 1. Table Size After Bloat
SELECT
    'AFTER BLOAT' AS measurement,
    pg_size_pretty(pg_relation_size('user_sessions')) AS data_size,
    pg_size_pretty(pg_indexes_size('user_sessions')) AS index_size,
    pg_size_pretty(pg_total_relation_size('user_sessions')) AS total_size;

-- 2. Dead Tuple Count from pg_stat_user_tables
SELECT
    relname,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    ROUND(n_dead_tup::numeric / NULLIF(n_live_tup, 0) * 100, 2) AS dead_pct,
    last_autovacuum,
    autovacuum_count
FROM pg_stat_user_tables
WHERE relname = 'user_sessions';

-- 3. Detailed Tuple Analysis (pgstattuple)
SELECT
    table_len,
    tuple_count,
    tuple_len,
    ROUND(tuple_percent::numeric, 2) AS tuple_percent,
    dead_tuple_count,
    dead_tuple_len,
    ROUND(dead_tuple_percent::numeric, 2) AS dead_tuple_percent,
    free_space,
    ROUND(free_percent::numeric, 2) AS free_percent
FROM pgstattuple('user_sessions');

-- 4. Bloat Ratio Calculation
SELECT
    pg_size_pretty(pg_relation_size('user_sessions')) AS current_size,
    pg_size_pretty(tuple_len) AS optimal_size,
    ROUND(table_len::numeric / NULLIF(tuple_len, 0), 2) AS bloat_ratio,
    pg_size_pretty(table_len - tuple_len) AS wasted_space,
    pg_size_pretty(free_space) AS free_space_size,
    pg_size_pretty(dead_tuple_len) AS dead_space_size
FROM pgstattuple('user_sessions');
EOF