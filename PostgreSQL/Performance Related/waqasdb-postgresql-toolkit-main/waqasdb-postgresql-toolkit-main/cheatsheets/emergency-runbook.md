# PostgreSQL Emergency Runbook

> Keep this bookmarked. When production is down,
> you don't have time to search.

---

## 1. Find What's Running RIGHT NOW

```sql
SELECT pid, NOW() - query_start AS duration,
    usename, state, wait_event_type, wait_event,
    LEFT(query, 100) AS query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;
```

## 2. Kill a Runaway Query

```sql
-- Graceful cancel (tries to stop query)
SELECT pg_cancel_backend(PID_HERE);

-- Force terminate (kills the connection)
SELECT pg_terminate_backend(PID_HERE);
```

## 3. Find Blocking Locks

```sql
SELECT
    blocked_locks.pid AS blocked_pid,
    blocking_locks.pid AS blocking_pid,
    blocked_activity.query AS blocked_query,
    blocking_activity.query AS blocking_query
FROM pg_locks blocked_locks
JOIN pg_stat_activity blocked_activity
    ON blocked_activity.pid = blocked_locks.pid
JOIN pg_locks blocking_locks
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_stat_activity blocking_activity
    ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

## 4. Check Disk Space

```sql
-- Largest tables
SELECT tablename,
    pg_size_pretty(pg_total_relation_size(tablename::regclass)) AS size
FROM pg_tables WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(tablename::regclass) DESC
LIMIT 10;

-- WAL files consuming disk
SELECT count(*) AS wal_files,
    pg_size_pretty(sum(size)) AS total_size
FROM pg_ls_waldir();
```

## 5. Check Replication Lag

```sql
SELECT client_addr, state,
    pg_size_pretty(pg_wal_lsn_diff(sent_lsn, replay_lsn)) AS lag
FROM pg_stat_replication;
```

## 6. Check Connection Count

```sql
SELECT count(*) AS total,
    count(*) FILTER (WHERE state = 'active') AS active,
    count(*) FILTER (WHERE state = 'idle') AS idle,
    count(*) FILTER (WHERE state = 'idle in transaction') AS idle_txn,
    (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') AS max
FROM pg_stat_activity
WHERE backend_type = 'client backend';
```

---

*WaqasDB | waqasdb.com | consulting@waqasdb.com*   
