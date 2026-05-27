-- Database size and connection info
SELECT
    current_database()                        AS db_name,
    pg_size_pretty(pg_database_size(current_database())) AS db_size,
    now()                                     AS captured_at;

-- Schema-level object count summary
SELECT
    n.nspname                                 AS schema_name,
    COUNT(CASE WHEN c.relkind = 'r' THEN 1 END) AS tables,
    COUNT(CASE WHEN c.relkind = 'i' THEN 1 END) AS indexes,
    COUNT(CASE WHEN c.relkind = 'v' THEN 1 END) AS views,
    COUNT(CASE WHEN c.relkind = 'S' THEN 1 END) AS sequences
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
GROUP BY n.nspname
ORDER BY n.nspname;




------------------------------------

-- Top 25 queries by avg execution time (catch slow individual calls)
SELECT
    left(query, 150)                          AS query_snippet,
    calls,
    round(mean_exec_time::numeric, 2)         AS avg_exec_ms,
    round(total_exec_time::numeric, 2)        AS total_exec_ms,
    rows,
    round(stddev_exec_time::numeric, 2)       AS stddev_ms,
    shared_blks_hit,
    shared_blks_read,
    round(shared_blks_hit::numeric / nullif(shared_blks_hit + shared_blks_read, 0) * 100, 2) AS cache_hit_pct
FROM pg_stat_statements
WHERE calls > 5
ORDER BY mean_exec_time DESC
LIMIT 25;

-- Top 25 by total time (heaviest load contributors)
SELECT
    left(query, 150)                          AS query_snippet,
    calls,
    round(total_exec_time::numeric, 2)        AS total_exec_ms,
    round(mean_exec_time::numeric, 2)         AS avg_exec_ms,
    rows
FROM pg_stat_statements
WHERE calls > 5
ORDER BY total_exec_time DESC
LIMIT 25;

-- High temp file usage queries (spilling to disk — memory pressure)
SELECT
    left(query, 150)                          AS query_snippet,
    calls,
    round(mean_exec_time::numeric, 2)         AS avg_exec_ms,
    temp_blks_written,
    round(temp_blks_written::numeric / nullif(calls, 0), 2) AS avg_temp_blks_per_call
FROM pg_stat_statements
WHERE temp_blks_written > 0
ORDER BY temp_blks_written DESC
LIMIT 20;





-----------index health--------------------

-- Unused or low-use indexes (review for DROP candidates)
SELECT
    n.nspname                                 AS schema_name,
    t.relname                                 AS table_name,
    i.relname                                 AS index_name,
    ix.indisunique                            AS is_unique,
    ix.indisprimary                           AS is_pk,
    s.idx_scan                                AS times_scanned,
    pg_size_pretty(pg_relation_size(i.oid))   AS index_size
FROM pg_index ix
JOIN pg_class t ON t.oid = ix.indrelid
JOIN pg_class i ON i.oid = ix.indexrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
LEFT JOIN pg_stat_user_indexes s ON s.indexrelid = ix.indexrelid
WHERE n.nspname = 'public'
  AND NOT ix.indisprimary
  AND NOT ix.indisunique
  AND s.idx_scan < 10
ORDER BY pg_relation_size(i.oid) DESC;

-- Tables doing heavy sequential scans — missing index candidates
SELECT
    schemaname,
    relname                                   AS table_name,
    seq_scan,
    idx_scan,
    n_live_tup                                AS live_rows,
    round(seq_scan::numeric / nullif(seq_scan + idx_scan, 0) * 100, 1) AS pct_seq_scan,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND seq_scan > 50
ORDER BY seq_scan DESC
LIMIT 20;

-- Dead tuple bloat per table (needs VACUUM)
SELECT
    schemaname,
    relname                                   AS table_name,
    n_live_tup,
    n_dead_tup,
    round(n_dead_tup::numeric / nullif(n_live_tup + n_dead_tup, 0) * 100, 2) AS dead_pct,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC
LIMIT 20;



------------repln health------------------
-- Replication slot status (check for lag / inactive slots)
SELECT
    slot_name,
    slot_type,
    database,
    active,
    active_pid,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal_size,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS replication_lag_size
FROM pg_replication_slots
ORDER BY slot_name;

-- Replication lag in seconds per subscriber (on primary)
SELECT
    client_addr,
    usename,
    application_name,
    state,
    sent_lsn,
    write_lsn,
    flush_lsn,
    replay_lsn,
    pg_size_pretty(pg_wal_lsn_diff(sent_lsn, replay_lsn))  AS total_lag_bytes,
    write_lag,
    flush_lag,
    replay_lag
FROM pg_stat_replication
ORDER BY replay_lag DESC NULLS LAST;

-- Subscription status (run on UAT/subscriber side)
SELECT
    subname                                   AS subscription_name,
    subenabled                                AS enabled,
    subslotname                               AS slot_name,
    subpublications                           AS publications
FROM pg_subscription;

-- Subscription worker status (run on UAT/subscriber side)
SELECT
    subname,
    pid,
    relid::regclass                           AS table_name,
    received_lsn,
    last_msg_send_time,
    last_msg_receipt_time,
    latest_end_lsn,
    latest_end_time
FROM pg_stat_subscription;



----------------5. Wait Events & Active Blocking (Run During Load)


-- Active sessions with wait events right now
SELECT
    pid,
    usename,
    application_name,
    state,
    wait_event_type,
    wait_event,
    round(extract(epoch from (now() - query_start)), 1) AS running_secs,
    left(query, 150)                          AS query_snippet
FROM pg_stat_activity
WHERE state != 'idle'
  AND pid <> pg_backend_pid()
ORDER BY running_secs DESC;

-- Blocking chains
SELECT
    blocked.pid                               AS blocked_pid,
    blocked.usename                           AS blocked_user,
    round(extract(epoch from (now() - blocked.query_start)), 1) AS blocked_secs,
    left(blocked.query, 100)                  AS blocked_query,
    blocking.pid                              AS blocking_pid,
    blocking.usename                          AS blocking_user,
    left(blocking.query, 100)                 AS blocking_query
FROM pg_stat_activity AS blocked
JOIN pg_stat_activity AS blocking
    ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
ORDER BY blocked_secs DESC;



---------------changed applied tracking---------------------


-- Recently modified tables (proxy via n_mod_since_analyze)
SELECT
    schemaname,
    relname                                   AS table_name,
    n_mod_since_analyze                       AS rows_modified_since_last_analyze,
    last_analyze,
    last_autoanalyze,
    n_live_tup,
    n_dead_tup
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND n_mod_since_analyze > 100
ORDER BY n_mod_since_analyze DESC;

-- WAL generation rate (indicates write load from UAT changes)
SELECT
    pg_current_wal_lsn()                      AS current_lsn,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0'::pg_lsn)) AS total_wal_generated;






-------------Also collect Index DDLs, and top intensive queries explain Analyse & those DDLs