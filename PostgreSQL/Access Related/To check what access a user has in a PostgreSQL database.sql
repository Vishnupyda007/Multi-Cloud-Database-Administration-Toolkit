To check what access a user has in a **PostgreSQL database**, you can use system catalog views and functions. Here are the main ways:

---

### ✅ **1. Check Roles and Memberships**
Run this query in the database:

```sql
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb, rolcanlogin
FROM pg_roles
WHERE rolname = '<username>';
```

- `rolsuper` → Superuser privilege
- `rolcreatedb` → Can create databases
- `rolcanlogin` → Can log in

---

### ✅ **2. Check Role Memberships**
To see which roles the user is a member of:

```sql
SELECT roleid::regrole AS role_name, member::regrole AS member_name
FROM pg_auth_members
WHERE member::regrole = '<username>';
```

---

### ✅ **3. Check Database-Level Privileges**
Run this in the database where you want to check access:

```sql
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = '<username>';
```

Or for schema-level:

```sql
SELECT grantee, privilege_type
FROM information_schema.role_schema_grants
WHERE grantee = '<username>';
```

---

### ✅ **4. Check All Privileges in Database**
```sql
\du <username>   -- In psql (shows roles and privileges)
```

---

### ✅ **5. Check Object-Level Privileges**
For tables:
```sql
SELECT grantee, privilege_type, table_schema, table_name
FROM information_schema.role_table_grants
WHERE grantee = '<username>';
```

---

Do you want me to **give you a single consolidated query that lists all privileges (roles, schemas, tables) for a user in one output**, or **a script to check across all databases on the server**?