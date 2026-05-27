-- ════════════════════════════════════════════════════════════
-- Run on SUBSCRIBER during initial copy
-- ════════════════════════════════════════════════════════════

-- ── 1. Overall sync state per table ──────────────────────────
SELECT
    s.subname                   AS subscription,
    r.srrelid::regclass           AS table_name,
    CASE r.srsubstate
        WHEN 'i' THEN '🔄 Initializing'
        WHEN 'd' THEN '📥 Copying data...'
        WHEN 'f' THEN '✅ Copy done, catching up'
        WHEN 's' THEN '✅ Synchronized'
        WHEN 'r' THEN '✅ Replicating (live)'
    END                         AS status,
    r.srsublsn                  AS lsn_position
FROM pg_subscription s
JOIN pg_subscription_rel r ON r.srsubid = s.oid
ORDER BY s.subname, table_name;


SELECT
    sub.subname,
    rel.srrelid::regclass AS table_name,
    CASE rel.srsubstate
        WHEN 'i' THEN 'Initializing'
        WHEN 'd' THEN 'DATA COPY IN PROGRESS'
        WHEN 'f' THEN 'Finishing / WAL catchup'
        WHEN 's' THEN 'Synchronized'
        WHEN 'r' THEN 'READY - streaming live'
    END AS sync_state
FROM pg_subscription_rel rel
JOIN pg_subscription sub ON sub.oid = rel.srsubid
ORDER BY sub.subname, table_name;

select * from pg_subscription_rel


-- ── 2. Count progress — rows copied so far ───────────────────
-- For each table being synced, check row count
-- Compare subscriber vs publisher counts

-- On SUBSCRIBER — current row count
SELECT
    'orders'    AS table_name, COUNT(*) AS rows_on_subscriber FROM public.orders
UNION ALL
SELECT
    'customers' AS table_name, COUNT(*) AS rows_on_subscriber FROM public.customers;

-- On PUBLISHER — total rows expected
SELECT
    'orders'    AS table_name, COUNT(*) AS rows_on_publisher FROM public.orders
UNION ALL
SELECT
    'customers' AS table_name, COUNT(*) AS rows_on_publisher FROM public.customers;

-- ── 3. Active copy workers — what's running right now ────────
-- Run on SUBSCRIBER
SELECT
    pid,
    usename,
    application_name,
    state,
    backend_type,
    LEFT(query, 100) AS current_query,
    NOW() - backend_start AS running_for
FROM pg_stat_activity
WHERE backend_type IN (
    'logical replication worker',
    'logical replication launcher',
    'TablesyncWorker'            -- PG17 specific
)
ORDER BY backend_type;

-- ── 4. Detailed copy progress per table (PG17) ───────────────
-- PG17 has better visibility into sync workers
SELECT
    w.subname,
    w.pid,
    w.relid::regclass       AS table_name,
    w.received_lsn,
    w.last_msg_send_time,
    w.last_msg_receipt_time,
    AGE(NOW(), w.last_msg_receipt_time) AS last_activity
FROM pg_stat_subscription_stats w
ORDER BY w.subname;

-- ── 5. pg_stat_progress_copy — live byte progress ────────────
-- Shows exact bytes copied during COPY phase
SELECT
    p.pid,
    p.relid::regclass       AS table_name,
    p.command,
    p.type,
    p.bytes_processed,
    p.bytes_total,
    CASE
        WHEN p.bytes_total > 0 THEN
            ROUND(
                (p.bytes_processed::NUMERIC / p.bytes_total) * 100,
                2
            )::TEXT || '%'
        ELSE 'calculating...'
    END                     AS progress_pct,
    p.tuples_processed      AS rows_copied,
    p.tuples_excluded       AS rows_skipped
FROM pg_stat_progress_copy p
ORDER BY table_name;
-- This is the BEST query during initial COPY phase ✅
-- Shows real-time byte and row progress

-- ── 6. Full initial copy monitoring script ───────────────────
-- Run this repeatedly (every 10-30 seconds) to track progress
SELECT
    NOW()                                           AS checked_at,
    sr.srrelid::regclass                              AS table_name,
    CASE sr.srsubstate
        WHEN 'i' THEN '🔄 Initializing'
        WHEN 'd' THEN '📥 Copying...'
        WHEN 'f' THEN '✅ Copy complete'
        WHEN 's' THEN '✅ Synced'
        WHEN 'r' THEN '✅ Live replication'
    END                                             AS sync_state,
    cp.bytes_processed,
    cp.bytes_total,
    CASE
        WHEN cp.bytes_total > 0 THEN
            ROUND(
                (cp.bytes_processed::NUMERIC
                    / cp.bytes_total) * 100, 1
            )::TEXT || '%'
        WHEN sr.srsubstate IN ('s','r') THEN '100%'
        ELSE '...'
    END                                             AS copy_progress,
    cp.tuples_processed                             AS rows_copied,
    pg_size_pretty(cp.bytes_processed)              AS data_copied,
    pg_size_pretty(cp.bytes_total)                  AS total_data
FROM pg_subscription_rel sr
LEFT JOIN pg_stat_progress_copy cp
    ON cp.relid = sr.srrelid
ORDER BY
    CASE sr.srsubstate
        WHEN 'd' THEN 1
        WHEN 'i' THEN 2
        WHEN 'f' THEN 3
        WHEN 's' THEN 4
        WHEN 'r' THEN 5
    END,
    sr.srrelid::regclass;

select * from pg_subscription_rel

-- ── 7. Estimated time remaining ──────────────────────────────
SELECT
    relid::regclass                             AS table_name,
    pg_size_pretty(bytes_processed)             AS copied,
    pg_size_pretty(bytes_total)                 AS total,
    ROUND(
        bytes_processed::NUMERIC
            / NULLIF(bytes_total,0) * 100, 1
    )                                           AS pct_done,
    CASE
        WHEN bytes_processed > 0 AND bytes_total > 0 THEN
            -- Estimate remaining time based on current rate
            pg_size_pretty(bytes_total - bytes_processed)
                || ' remaining'
        ELSE 'calculating...'
    END                                         AS remaining,
    tuples_processed                            AS rows_done,
    NOW() - pg_stat_get_backend_activity_start(pid) AS elapsed
FROM pg_stat_progress_copy
WHERE bytes_total > 0
ORDER BY pct_done;

-- ── 8. Check if initial copy is fully DONE ───────────────────
-- Run on SUBSCRIBER
SELECT
    COUNT(*)                                    AS total_tables,
    COUNT(*) FILTER (WHERE srsubstate = 'r')    AS replicating,
    COUNT(*) FILTER (WHERE srsubstate = 's')    AS synchronized,
    COUNT(*) FILTER (WHERE srsubstate = 'd')    AS still_copying,
    COUNT(*) FILTER (WHERE srsubstate = 'i')    AS initializing,
    CASE
        WHEN COUNT(*) FILTER (
            WHERE srsubstate NOT IN ('r','s')
        ) = 0
        THEN '✅ ALL TABLES SYNCED — replication live'
        ELSE '🔄 ' || COUNT(*) FILTER (
            WHERE srsubstate NOT IN ('r','s')
        )::TEXT || ' tables still syncing'
    END                                         AS overall_status
FROM pg_subscription_rel;
-- When still_copying = 0 → initial sync complete ✅

-- ── 9. Publisher side — WAL send progress ────────────────────
-- Run on PUBLISHER during initial copy
SELECT
    application_name        AS subscriber,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    write_lag,
    flush_lag,
    replay_lag,
    pg_size_pretty(
        pg_wal_lsn_diff(sent_lsn, replay_lsn)
    )                       AS pending_wal
FROM pg_stat_replication
ORDER BY application_name;