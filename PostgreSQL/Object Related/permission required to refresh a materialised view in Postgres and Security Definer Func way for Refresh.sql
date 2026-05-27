Here’s the **clear, PostgreSQL‑accurate answer**, with **no ambiguity**, and explained both **practically** and **from a security/IAM perspective**.

***

## ✅ Permission required to REFRESH a materialized view in PostgreSQL

### ✅ **Minimum required permission**

You must be **the OWNER of the materialized view**  
**OR**
You must be a **superuser**

That’s it.

***

## ✅ Why ownership is required (important concept)

`REFRESH MATERIALIZED VIEW` is **not just a SELECT**.  
Internally it:

*   Truncates the materialized view
*   Re‑executes the underlying SELECT
*   Inserts fresh data into the materialized view

➡️ That is a **WRITE operation** on the materialized view.

So PostgreSQL enforces:

> **Only the owner (or superuser) can refresh it**

***

## ✅ Required privileges by command type

| Command                                  | Required privilege       |
| ---------------------------------------- | ------------------------ |
| `SELECT` from materialized view          | `SELECT` privilege       |
| `REFRESH MATERIALIZED VIEW`              | **OWNER**                |
| `REFRESH MATERIALIZED VIEW CONCURRENTLY` | **OWNER + UNIQUE INDEX** |

***

## ✅ What does NOT work (very common mistake)

```sql
GRANT SELECT ON my_matview TO user1;
```

❌ This **does NOT** allow:

```sql
REFRESH MATERIALIZED VIEW my_matview;
```

Because `GRANT` **cannot grant ownership-level privileges**.

***

## ✅ How to check the owner

```sql
SELECT
    schemaname,
    matviewname,
    matviewowner
FROM pg_matviews
WHERE matviewname = 'your_matview_name';
```

***

## ✅ How to allow another user to refresh it

### ✅ Option 1 (Recommended): Change ownership

```sql
ALTER MATERIALIZED VIEW schema.my_matview
OWNER TO target_user;
```

✅ Clean  
✅ Fully supported  
✅ Least surprise

***

### ✅ Option 2: Use a SECURITY DEFINER function (best practice)

This is the **enterprise‑safe approach**.

```sql
CREATE OR REPLACE FUNCTION admin.refresh_my_matview()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
    REFRESH MATERIALIZED VIEW schema.my_matview;
$$;

GRANT EXECUTE ON FUNCTION admin.refresh_my_matview() TO app_user;
```

✅ App user can refresh  
✅ App user does NOT own the view  
✅ No superuser needed

📌 **This is the recommended pattern in production**

***

## ✅ What about `REFRESH … CONCURRENTLY`?

Additional requirement:

```sql
CREATE UNIQUE INDEX
ON schema.my_matview (some_column);
```

And still:

*   Must be **owner**
*   Or **SECURITY DEFINER function**

***

## ✅ Cloud SQL / RDS / Managed Postgres (important)

All managed PostgreSQL services follow **the same rule**:

✅ Owner or superuser only  
❌ No extra “refresh” role exists  
❌ No GRANT-based workaround

***

## ✅ One‑line definitive answer

> **Refreshing a materialized view requires ownership of the materialized view (or superuser). GRANT privileges alone are not sufficient.**

***

## ✅ Quick decision guide

| Scenario          | Recommended solution      |
| ----------------- | ------------------------- |
| App needs refresh | SECURITY DEFINER function |
| DBA refreshes     | Owner                     |
| Read-only user    | ❌ Cannot refresh          |
| Multiple apps     | Wrapper function          |

***

If you want, I can:

*   ✅ Generate a **generic refresh function** for all matviews
*   ✅ Add **logging / audit**
*   ✅ Add **retry & lock handling**
*   ✅ Explain **why Postgres enforces this**
*   ✅ Compare with Oracle / SQL Server behavior

Just tell me 👍
