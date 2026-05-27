cat > 01-bloat-analysis/scripts/09-autovacuum-tuning.sql << 'EOF'
-- ============================================================
-- PostgreSQL Bloat Lab
-- Script 09: Per-Table Autovacuum Prevention Tuning
-- Author: Waqas Ahmad | WaqasDB (waqasdb.com)
-- ============================================================
--
-- USAGE: psql -d bloat_lab -f 09-autovacuum-tuning.sql
--
-- PURPOSE: Configure aggressive autovacuum settings per-table
--          to prevent bloat from accumulating.
--
-- WHY DEFAULT SETTINGS ARE BAD:
--   Default autovacuum_vacuum_scale_factor = 0.2 (20%)
--   For a 5M row table: 5,000,000 × 0.2 = 1,000,000 dead rows
--   before autovacuum even triggers!
--
-- TUNED SETTINGS:
--   Scale factor = 0.01 (1%)
--   For 5M rows: 5,000,000 × 0.01 = 50,000 dead rows trigger
--   That's 20x more aggressive!
-- ============================================================

-- 1. Show current DEFAULT settings
SELECT
    name,
    setting,
    unit,
    short_desc
FROM pg_settings
WHERE name IN (
    'autovacuum_vacuum_scale_factor',
    'autovacuum_vacuum_threshold',
    'autovacuum_analyze_scale_factor',
    'autovacuum_analyze_threshold',
    'autovacuum_vacuum_cost_delay',
    'autovacuum_vacuum_cost_limit'
)
ORDER BY name;

-- 2. Show the MATH of why defaults fail
SELECT
    'DEFAULT' AS setting_type,
    5000000 AS total_rows,
    0.20 AS scale_factor,
    50 AS threshold,
    (5000000 * 0.20 + 50)::int AS dead_rows_before_vacuum
UNION ALL
SELECT
    'TUNED' AS setting_type,
    5000000 AS total_rows,
    0.01 AS scale_factor,
    1000 AS threshold,
    (5000000 * 0.01 + 1000)::int AS dead_rows_before_vacuum;

-- 3. Apply optimized per-table settings
ALTER TABLE user_sessions SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_vacuum_threshold = 1000,
    autovacuum_analyze_scale_factor = 0.005,
    autovacuum_vacuum_cost_delay = 2,
    autovacuum_vacuum_cost_limit = 1000
);

-- 4. Verify settings were applied
SELECT
    relname,
    reloptions
FROM pg_class
WHERE relname = 'user_sessions';

-- 5. Confirm current autovacuum state
SELECT
    relname,
    n_live_tup,
    n_dead_tup,
    autovacuum_count,
    last_autovacuum,
    pg_size_pretty(pg_relation_size(relid)) AS size
FROM pg_stat_user_tables
WHERE relname = 'user_sessions';
EOF