-- ============================================================
-- PostgreSQL Bloat Lab
-- Script 02: Record Baseline Measurements (Before Bloat)
-- Author: Waqas Ahmad | WaqasDB (waqasdb.com)
-- ============================================================
--
-- USAGE: psql -d bloat_lab -f 02-baseline-measurement.sql
--
-- PURPOSE: Record table health BEFORE creating bloat.
--          Save this output for before/after comparison.
-- ============================================================

-- 1. Table Size
SELECT
    'BASELINE' AS measurement,
    pg_size_pretty(pg_relation_size('user_sessions')) AS data_size,
    pg_size_pretty(pg_indexes_size('user_sessions')) AS index_size,
    pg_size_pretty(pg_total_relation_size('user_sessions')) AS total_size;

-- 2. Row Statistics
SELECT
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    ROUND(n_dead_tup::numeric / NULLIF(n_live_tup, 0) * 100, 2) AS dead_pct,
    last_autovacuum,
    autovacuum_count
FROM pg_stat_user_tables
WHERE relname = 'user_sessions';

-- 3. Tuple-Level Analysis (pgstattuple)
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

-- 4. Page Health Baseline
SELECT
    count(*) AS total_pages,
    count(*) FILTER (WHERE avail = 0) AS fully_packed_pages,
    count(*) FILTER (WHERE avail > 0) AS pages_with_free_space,
    ROUND(count(*) FILTER (WHERE avail = 0) * 100.0 / count(*), 2) AS pct_fully_packed
FROM pg_freespace('user_sessions');
