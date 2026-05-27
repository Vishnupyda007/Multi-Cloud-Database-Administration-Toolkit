-- ============================================================
-- PostgreSQL Bloat Lab
-- Script 03: Create Bloat with UPDATE-Heavy Workload
-- Author: Waqas Ahmad | WaqasDB (waqasdb.com)
-- ============================================================
--
-- USAGE: psql -d bloat_lab -f 03-create-bloat.sql
--
-- PURPOSE: Simulate production UPDATE workload that causes bloat.
--          10 rounds × 500K random updates = 5M total updates.
--
-- TIME: ~5-15 minutes depending on hardware
--
-- WHAT HAPPENS:
--   PostgreSQL MVCC creates a NEW tuple for every UPDATE.
--   The OLD tuple is marked as dead.
--   This causes the table to grow significantly.
-- ============================================================

DO $$
DECLARE
    start_time TIMESTAMP;
    round_time TIMESTAMP;
BEGIN
    start_time := clock_timestamp();
    RAISE NOTICE 'Starting UPDATE workload at %', start_time;
    RAISE NOTICE '10 rounds × 500,000 rows = 5,000,000 updates';
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
    END LOOP;

    RAISE NOTICE '──────────────────────────────────────────────';
    RAISE NOTICE 'Total time: % seconds',
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::numeric, 2);
    RAISE NOTICE 'Bloat workload complete';
END $$;
