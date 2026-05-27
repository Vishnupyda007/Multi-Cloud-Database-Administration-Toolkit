cat > 01-bloat-analysis/scripts/10-rerun-with-tuning.sql << 'EOF'
-- ============================================================
-- PostgreSQL Bloat Lab
-- Script 10: Re-Run Workload WITH Tuned Autovacuum
-- Author: Waqas Ahmad | WaqasDB (waqasdb.com)
-- ============================================================
--
-- USAGE: psql -d bloat_lab -f 10-rerun-with-tuning.sql
--
-- PURPOSE: Run the IDENTICAL update workload with tuned
--          autovacuum settings and compare results.
--
-- EXPECTED: Autovacuum should trigger more frequently,
--           keeping dead tuples near zero throughout.
-- ============================================================

-- 1. Record baseline before re-test
SELECT
    'BEFORE RE-TEST' AS stage,
    pg_size_pretty(pg_relation_size('user_sessions')) AS data_size,
    n_dead_tup AS dead_tuples,
    autovacuum_count AS vacuum_runs,
    last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'user_sessions';

-- 2. Run the SAME update workload
DO $$
DECLARE
    start_time TIMESTAMP;
    round_time TIMESTAMP;
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Starting UPDATE workload WITH tuned autovacuum';
    RAISE NOTICE '──────────────────────────────────────────────';

    FOR i IN 1..10 LOOP
        round_time := clock_timestamp();

        UPDATE user_sessions
        SET updated_at = NOW(),
            is_active = NOT is_active
        WHERE id IN (
            SELECT id FROM user_sessions
            ORDER BY random()
            LIMIT 500000
        );

        RAISE NOTICE 'Round %/10 complete (% seconds)',
            i,
            ROUND(EXTRACT(EPOCH FROM clock_timestamp() - round_time)::numeric, 2);

        -- Small pause to give autovacuum a chance to run
        PERFORM pg_sleep(2);
    END LOOP;

    RAISE NOTICE '──────────────────────────────────────────────';
    RAISE NOTICE 'Total time: % seconds',
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::numeric, 2);
END $$;

-- 3. Wait for autovacuum to finish any pending work
SELECT pg_sleep(30);

-- 4. Measure results WITH tuning
SELECT
    'AFTER RE-TEST (TUNED)' AS stage,
    pg_size_pretty(pg_relation_size('user_sessions')) AS data_size,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    autovacuum_count AS total_vacuum_runs,
    last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'user_sessions';

-- 5. Tuple analysis
SELECT
    pg_size_pretty(table_len) AS table_size,
    tuple_count AS live_tuples,
    dead_tuple_count AS dead_tuples,
    ROUND(dead_tuple_percent::numeric, 2) AS dead_pct,
    ROUND(free_percent::numeric, 2) AS free_pct
FROM pgstattuple('user_sessions');

-- 6. Comparison Summary
-- Run this to see the key differences:
SELECT
    relname,
    n_dead_tup,
    last_autovacuum,
    autovacuum_count,
    pg_size_pretty(pg_relation_size(relid)) AS size
FROM pg_stat_user_tables
WHERE relname = 'user_sessions';
EOF