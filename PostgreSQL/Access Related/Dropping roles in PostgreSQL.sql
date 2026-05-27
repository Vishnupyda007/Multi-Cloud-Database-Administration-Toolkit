Great question! Here’s the key point:

### ✅ Can you drop a login role that has access to objects in a database?

**Yes, but only if the role does NOT own any objects.**  
PostgreSQL does not care about privileges when dropping a role—it only cares about ownership. If the role:

*   Has **grants** (SELECT, INSERT, etc.) → You can still `DROP ROLE` without revoking them first.
*   **Owns objects** (tables, schemas, functions, etc.) → You **cannot** drop it until ownership is reassigned or objects are dropped.

***

### ✅ Why?

Ownership creates a dependency. PostgreSQL enforces referential integrity for object ownership, so you must clean up first.

***

### ✅ What happens to privileges after dropping the role?

*   All grants to that role become meaningless because the role no longer exists.
*   No error occurs for privileges; they just disappear.

***

### ✅ Steps if the role owns objects:

Use:

```sql
BEGIN;

-- Reassign ownership to another role (e.g., postgres)
REASSIGN OWNED BY old_role TO new_owner;

-- Drop any privileges granted by old_role
DROP OWNED BY old_role;

-- Drop the role
DROP ROLE old_role;

COMMIT;
```

***

### ✅ If the role is just a login with no ownership:

You can simply:

```sql
DROP ROLE old_role;
```

***

Do you want me to give you:

*   **A script to check if a role owns any objects before dropping it**  
    OR
*   **A full automated cleanup script (reassign or drop owned objects, then drop role)**?

(Second option is best for production safety.)
