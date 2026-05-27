From your screenshot, the query shows **no privileges for `EDS_ETL_test`**, even though you mentioned granting access and the role has `cloudsqluser`. Here’s why this happens and how to fix it:

---

### ✅ Why Access Is Not Working
1. **`cloudsqluser` role in Cloud SQL**  
   - This is a **PostgreSQL role created by GCP for IAM integration**, but it **does not automatically grant database-level privileges**.
   - It only allows the user to **connect to the instance** if IAM authentication is enabled.

2. **Database Privileges Missing**  
   - Your query shows no grants in `information_schema.role_table_grants`, meaning the user has **no object-level privileges** in the database.

---

### ✅ How to Provision Access Properly
You need to **grant privileges inside the database** after creating the role:

#### **Step 1: Grant CONNECT on Database**
```sql
GRANT CONNECT ON DATABASE ent_data_store TO "EDS_ETL_test";
```

#### **Step 2: Grant Usage on Schema**
```sql
GRANT USAGE ON SCHEMA public TO "EDS_ETL_test";
```

#### **Step 3: Grant Table Privileges**
For read-only:
```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "EDS_ETL_test";
```

For future tables:
```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "EDS_ETL_test";
```

#### **Step 4: Verify**
Run:
```sql
\z   -- in psql (shows privileges)
```
Or:
```sql
SELECT grantee, privilege_type, table_schema, table_name
FROM information_schema.role_table_grants
WHERE grantee = 'EDS_ETL_test';
```

---

✅ Do you want me to give you **a complete script that grants full read/write access to a user across all schemas and ensures future tables also inherit these privileges**? Or **just read-only access**?