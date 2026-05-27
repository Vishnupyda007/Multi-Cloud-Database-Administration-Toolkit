-- ── Run on PUBLISHER — full replication health dashboard ──────
SELECT
    '━━━ REPLICATION HEALTH DASHBOARD ━━━' AS info,
    NOW()                                   AS checked_at;

SELECT
    s.slot_name                             AS subscriber,
    s.active                                AS is_active,
    s.synced                                AS failover_ready,  -- PG17
    r.state                                 AS wal_state,
    r.client_addr                           AS subscriber_ip,
    r.replay_lag                            AS lag,
    pg_size_pretty(
        pg_wal_lsn_diff(
            pg_current_wal_lsn(), s.restart_lsn
        )
    )                                       AS wal_accumulated,
    pg_wal_lsn_diff(
        pg_current_wal_lsn(), s.restart_lsn
    )                                       AS wal_bytes
FROM pg_replication_slots s
LEFT JOIN pg_stat_replication r
    ON r.pid = s.active_pid
WHERE s.slot_type = 'logical'
ORDER BY s.slot_name;

-- ── Alert query — run this to catch problems early ────────────
SELECT
    slot_name,
    CASE
        WHEN active = FALSE THEN
            '🔴 CRITICAL: Slot inactive — WAL accumulating'
        WHEN pg_wal_lsn_diff(
                 pg_current_wal_lsn(), restart_lsn
             ) > 1073741824 THEN
            '🟡 WARNING: WAL lag > 1GB'
        WHEN pg_wal_lsn_diff(
                 pg_current_wal_lsn(), restart_lsn
             ) > 5368709120 THEN
            '🔴 CRITICAL: WAL lag > 5GB'
        ELSE
            '🟢 OK'
    END AS health_status,
    pg_size_pretty(
        pg_wal_lsn_diff(
            pg_current_wal_lsn(), restart_lsn
        )
    ) AS wal_lag
FROM pg_replication_slots
WHERE slot_type = 'logical'
ORDER BY slot_name;