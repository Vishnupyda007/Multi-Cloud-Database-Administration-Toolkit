Here’s how you can check **deadlocks and blocking in PostgreSQL (including Cloud SQL)**:

---

### ✅ **1. Check Blocking Sessions**
(Already shared earlier, but included for completeness)
```sql
SELECT
    bl.pid AS blocked_pid,
    bl.usename AS blocked_user,
    bl.query AS blocked_query,
    bl.state AS blocked_state,
    bl.backend_start AS blocked_since,
    lk.pid AS blocking_pid,
    lk.usename AS blocking_user,
    lk.query AS blocking_query,
    lk.state AS blocking_state,
    lk.backend_start AS blocking_since
FROM pg_catalog.pg_locks l1
JOIN pg_catalog.pg_stat_activity bl ON l1.pid = bl.pid
JOIN pg_catalog.pg_locks l2 ON l1.locktype = l2.locktype
    AND l1.database IS NOT DISTINCT FROM l2.database
    AND l1.relation IS NOT DISTINCT FROM l2.relation
    AND l1.page IS NOT DISTINCT FROM l2.page
    AND l1.tuple IS NOT DISTINCT FROM l2.tuple
    AND l1.virtualxid IS NOT DISTINCT FROM l2.virtualxid
    AND l1.transactionid IS NOT DISTINCT FROM l2.transactionid
    AND l1.classid IS NOT DISTINCT FROM l2.classid
    AND l1.objid IS NOT DISTINCT FROM l2.objid
    AND l1.objsubid IS NOT DISTINCT FROM l2.objsubid
    AND l1.pid <> l2.pid
JOIN pg_catalog.pg_stat_activity lk ON l2.pid = lk.pid
WHERE NOT l1.granted AND l2.granted;
```

---
SELECT pid, usename, application_name, client_addr, state, xact_start, query_start, wait_event_type, wait_event, query
FROM pg_stat_activity
WHERE state = 'idle in transaction'
ORDER BY xact_start;

-------


SELECT now(), pid, usename, application_name, client_addr, xact_start, query
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND now() - xact_start > interval '20 minutes';


### ✅ **2. Check Deadlocks**
PostgreSQL logs deadlocks in the **server logs**, but you can also monitor potential deadlock situations using `pg_locks`:

```sql
SELECT
    pid,
    locktype,
    relation::regclass AS locked_relation,
    mode,
    granted,
    transactionid
FROM pg_locks
WHERE NOT granted;

for idle in trans--

SELECT a.pid, a.usename, a.query, l.mode, l.locktype, l.relation::regclass AS rel, l.granted
FROM pg_locks l
JOIN pg_stat_activity a ON a.pid = l.pid
WHERE a.state = 'idle in transaction'
ORDER BY a.xact_start;
```

- If you see multiple sessions waiting on locks that cannot be granted, this indicates a possible deadlock scenario.

---

### ✅ **3. Enable Deadlock Logging**
In Cloud SQL, deadlocks are logged automatically if `log_lock_waits` and `deadlock_timeout` are configured. You can check logs in **Cloud SQL Logs Viewer**.

---

### ✅ **4. Terminate Blocking Session**
```sql
SELECT pg_terminate_backend(<blocking_pid>);
```


-------------to terminate idle in transaction sessions-----

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle in transaction'
AND now() - state_change > interval '10 minutes'
AND pid <> pg_backend_pid();

---

🔥 Do you want me to give you **a combined script that shows active sessions, blocking chains, and potential deadlocks in one view**, and optionally **auto-terminates blockers older than X minutes**? Or should I prepare **a monitoring query that you can schedule for alerts**?