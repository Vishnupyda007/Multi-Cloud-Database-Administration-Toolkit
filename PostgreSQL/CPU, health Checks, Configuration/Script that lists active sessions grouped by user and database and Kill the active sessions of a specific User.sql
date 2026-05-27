Here’s a **script that lists active sessions grouped by user and database**, and also includes an option to terminate sessions if needed:

---

### ✅ **List Active Sessions Grouped by User and Database**
```sql
SELECT datname AS database,
       usename AS username,
       COUNT(*) AS active_sessions
FROM pg_stat_activity
WHERE state = 'active'
GROUP BY datname, usename
ORDER BY active_sessions DESC;
```

---

### ✅ **Detailed Active Session Info**
```sql
SELECT pid,
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
```

---

### ✅ **Terminate All Sessions for a Specific User**
```sql
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT pid FROM pg_stat_activity WHERE usename = 'EDS_ETL_test'
    LOOP
        EXECUTE format('SELECT pg_terminate_backend(%s);', r.pid);
    END LOOP;
END$$;
```

---

### ✅ **Terminate All Sessions for a Specific Database**
```sql
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT pid FROM pg_stat_activity WHERE datname = 'ent_data_store'
    LOOP
        EXECUTE format('SELECT pg_terminate_backend(%s);', r.pid);
    END LOOP;
END$$;
```

---

🔥 Do you want me to **combine all of these into one script that first lists sessions and then terminates them based on user or database input**? Or should I **give you a version that only kills idle sessions older than X minutes**?