The error in your screenshot says:

```
Could not drop the role.
role "eds_etl_test" cannot be dropped because some objects depend on it
privileges for database ent_data_store
4 objects in database ent_data_store
```

This means the role **`eds_etl_test`** still has privileges on objects in the database. PostgreSQL will not allow you to drop a role until all dependent privileges are revoked.

---

### ✅ **Steps to Drop the Role**

#### **1. Find All Privileges for the Role**
Run this query in the database:

```sql
SELECT grantee, privilege_type, table_schema, table_name
FROM information_schema.role_table_grants
WHERE grantee = 'eds_etl_test';
```

Also check schema-level and database-level grants:

```sql
SELECT grantee, privilege_type
FROM information_schema.role_schema_grants
WHERE grantee = 'eds_etl_test';

SELECT grantee, privilege_type
FROM information_schema.role_database_grants
WHERE grantee = 'eds_etl_test';
```

---

#### **2. Revoke All Privileges**
For each object, revoke privileges:

```sql
REVOKE ALL PRIVILEGES ON DATABASE ent_data_store FROM eds_etl_test;
REVOKE ALL PRIVILEGES ON SCHEMA public FROM eds_etl_test;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM eds_etl_test;
```

If the role owns objects, you must **change ownership** first:

```sql
ALTER TABLE table_name OWNER TO cloudsqlsuperuser;
```

---

#### **3. Drop the Role**
Once all privileges and ownerships are removed:

```sql
DROP ROLE eds_etl_test;
```

---

✅ Do you want me to give you **a single script that automatically revokes all privileges and changes ownership for this role across the entire database**, so you can run it in one go?