Here’s a **combined PostgreSQL monitoring script** that shows:

✅ Active sessions  
✅ Blocking chains (who is blocking whom)  
✅ Potential deadlocks (waiting locks)  

---

### **Combined Script**
```sql
-- Active Sessions
SELECT 'ACTIVE_SESSION' AS section,
       pid,
       usename AS username,
       datname AS database,
       client_addr AS client_ip,
       application_name,
       state,
       query,
       backend_start
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY backend_start DESC;

-- Blocking Chains
SELECT 'BLOCKING_CHAIN' AS section,
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

-- Potential Deadlocks (waiting locks)
SELECT 'WAITING_LOCKS' AS section,
       pid,
       locktype,
       relation::regclass AS locked_relation,
       mode,
       granted,
       transactionid
FROM pg_locks
WHERE NOT granted;
```

---

### ✅ **How to Use**
- Run this in **Query Tool** in pgAdmin or psql.
- It will return three result sets:
  - **Active sessions** (currently running queries)
  - **Blocking chains** (blocked vs blocking sessions)
  - **Waiting locks** (possible deadlock indicators)

---

### ✅ **Optional: Kill Blocking Sessions**
```sql
SELECT pg_terminate_backend(<blocking_pid>);
```

---

🔥 Do you want me to **extend this script to automatically terminate blocking sessions older than X minutes** and **send alerts via email or log them for monitoring**? Or should I **give you a version that you can schedule as a monitoring job in Cloud SQL**?