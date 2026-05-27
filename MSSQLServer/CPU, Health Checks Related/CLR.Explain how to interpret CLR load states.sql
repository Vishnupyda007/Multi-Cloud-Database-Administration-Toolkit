In SQL Server, **CLR load states** are observed through the **AppDomain state** in `sys.dm_clr_appdomains` and the assembly load information in `sys.dm_clr_loaded_assemblies`. Here’s how to interpret them:

---

## ✅ 1. Where to check CLR load states
- **`sys.dm_clr_appdomains`**: Shows each CLR AppDomain (essentially an isolated environment for assemblies).
  - Columns: `appdomain_id`, `db_id`, `state`, `creation_time`.
- **`sys.dm_clr_loaded_assemblies`**: Shows assemblies currently loaded into those AppDomains.
  - Columns: `assembly_id`, `appdomain_address`, `load_time`.

---

## ✅ 2. Common AppDomain `state` values
| State | Meaning |
|-------|---------|
| **VISIBLE** | The AppDomain is active and can execute CLR code. Assemblies in this domain are usable. |
| **UNLOADING** | The AppDomain is in the process of unloading (e.g., after `ALTER DATABASE ... SET TRUSTWORTHY OFF` or assembly drop). |
| **UNLOADED** | The AppDomain has been unloaded; assemblies are no longer available. |
| **INITIALIZING** | The AppDomain is being created and initialized. |

> These states come from the internal CLR hosting model in SQL Server. When you enable CLR (`clr enabled = 1`), SQL Server creates the **system AppDomain** and then per-database AppDomains as needed.

---

## ✅ 3. Assembly load interpretation
- If an assembly appears in `sys.dm_clr_loaded_assemblies`, it is **currently loaded in memory**.
- `load_time` shows when it was loaded.
- Assemblies load **on demand** (first execution) and remain loaded until:
  - The database is dropped or set offline.
  - The assembly is dropped.
  - The AppDomain is recycled (e.g., `ALTER DATABASE ... SET TRUSTWORTHY OFF` or server restart).

---

## ✅ 4. In **Cloud SQL for SQL Server**
- CLR works the same way internally, but:
  - You **cannot use UNSAFE assemblies** (only SAFE and EXTERNAL_ACCESS are allowed if the instance flag permits).
  - You **cannot access OS-level resources** (sandboxed environment).
  - AppDomain states and DMVs behave the same, but you need `VIEW SERVER STATE` to query them.

---

### ✅ Quick query to see AppDomain states:
```sql
SELECT appdomain_id, db_id, DB_NAME(db_id) AS database_name, state, creation_time
FROM sys.dm_clr_appdomains;
```

---

### ✅ How to interpret in practice:
- **VISIBLE** = CLR is active for that DB.
- If you see **UNLOADING** or **UNLOADED**, CLR objects from that DB are not usable until reloaded.
- If no rows exist, CLR hasn’t been used since the last restart or is disabled.

---

👉 Do you want me to **prepare a full diagnostic script** that:
- Checks if CLR is enabled,
- Lists all AppDomains with their states,
- Shows loaded assemblies with names and permission sets,
- And highlights which databases currently have CLR active?