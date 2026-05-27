To check **active sessions in Cloud SQL for PostgreSQL**, you can query the PostgreSQL system view `pg_stat_activity`. This works for any PostgreSQL instance, including Cloud SQL.

---

### ✅ **Query to List Active Sessions**
```sql
SELECT pid,
       usename AS username,
       datname AS database,
       client_addr AS client_ip,
       application_name,
       state,
       query,
       backend_start,
       state_change
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY backend_start DESC;
```

---

### ✅ **Explanation**
- `pg_stat_activity` → Shows all connections and their current state.
- `state = 'active'` → Filters only active queries (not idle).
- Columns:
  - `pid` → Process ID of the session.
  - `usename` → Database user.
  - `datname` → Database name.
  - `client_addr` → Client IP address.
  - `query` → SQL currently running.
  - `backend_start` → When the session started.

---

### ✅ **To See All Sessions (Active + Idle)**
Remove the `WHERE` clause:
```sql
SELECT * FROM pg_stat_activity;
```

---

### ✅ **To Terminate a Session**
```sql
SELECT pg_terminate_backend(<pid>);
```

---

🔥 Do you want me to give you:
- **A script that lists active sessions grouped by user and database**, OR  
- **A script that kills all sessions for a specific user or database in Cloud SQL**?