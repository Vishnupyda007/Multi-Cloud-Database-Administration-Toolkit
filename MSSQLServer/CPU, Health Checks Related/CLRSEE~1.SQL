Got it. Below are **ready‑to‑run T‑SQL snippets** to (1) see whether **any CLR assemblies are currently loaded** (server‑wide and per database), (2) **list all SQLCLR assemblies and the T‑SQL objects that use them** (cross‑database), and (3) **inspect SSIS packages** in **SSISDB** to detect **Script Task / Script Component** usage (managed .NET inside SSIS runtime) and **packages that call SQLCLR objects**.

> **Permissions:** DMVs for CLR require `VIEW SERVER STATE` (and on SQL Server 2022+, `VIEW SERVER PERFORMANCE STATE`).[1](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-clr-loaded-assemblies-transact-sql?view=azuresqldb-current)

---

## 1) Are any CLR assemblies currently **loaded**?

### 1A) Server‑wide with database mapping
This shows each **loaded assembly instance** and the **database** whose AppDomain it is running under.

```sql
-- Server-wide: which CLR assemblies are currently loaded, mapped to DB
SELECT
    DB_NAME(ad.db_id)          AS database_name,
    la.assembly_id,
    la.load_time,
    ad.appdomain_id,
    ad.state                   AS appdomain_state
FROM sys.dm_clr_loaded_assemblies AS la
JOIN sys.dm_clr_appdomains       AS ad
  ON la.appdomain_address = ad.appdomain_address
ORDER BY database_name, la.load_time;
```

- `sys.dm_clr_loaded_assemblies` returns one row per **loaded** managed assembly;  
- `sys.dm_clr_appdomains` tells you **which database** the AppDomain belongs to.[1](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-clr-loaded-assemblies-transact-sql?view=azuresqldb-current)[2](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-clr-appdomains-transact-sql?view=azuresqldb-current)

> **Note:** The DMV shows assemblies loaded across the **whole server**. It doesn’t directly expose names; for that, join to `sys.assemblies` **inside each database** (next query). The Microsoft docs also show this pattern.[1](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-clr-loaded-assemblies-transact-sql?view=azuresqldb-current)

### 1B) Per‑database: include assembly names  
Run this in each **user database** you care about (or use the cross‑DB script in §2):

```sql
-- Run in a user database to see loaded assemblies by name
SELECT
    a.name         AS assembly_name,
    a.assembly_id,
    a.permission_set_desc,
    l.load_time
FROM sys.dm_clr_loaded_assemblies AS l
JOIN sys.assemblies              AS a
  ON a.assembly_id = l.assembly_id
ORDER BY a.name;
```

The `sys.dm_clr_loaded_assemblies` doc shows this exact join to resolve names from `sys.assemblies` (remember: `sys.assemblies` is **scoped to the current DB**).[1](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-clr-loaded-assemblies-transact-sql?view=azuresqldb-current)

---

## 2) List **all SQLCLR assemblies** and the **T‑SQL objects** that use them (cross‑database)

This enumerates assemblies plus the **CLR‑backed objects** (procedures, functions, triggers, user‑defined types / aggregates) that reference them.

```sql
/* Cross-DB inventory of SQLCLR assemblies and the objects that reference them */
DECLARE @sql nvarchar(max) = N'';

SELECT @sql = STRING_AGG(CONCAT(N'
USE ', QUOTENAME(d.name), N';
-- Assemblies and their CLR-backed objects in ', QUOTENAME(d.name), N'
;WITH clr_objects AS (
    SELECT 
        a.name                    AS assembly_name,
        a.permission_set_desc,
        o.name                    AS object_name,
        o.[type]                  AS object_type,
        am.assembly_class,
        am.assembly_method
    FROM sys.assemblies AS a
    JOIN sys.assembly_modules AS am
      ON am.assembly_id = a.assembly_id
    JOIN sys.objects AS o
      ON o.object_id = am.object_id

    UNION ALL
    -- User-defined types (UDTs)
    SELECT 
        a.name,
        a.permission_set_desc,
        t.name,
        CAST(''UDT'' AS nvarchar(10)),
        at.assembly_class,
        NULL
    FROM sys.assemblies AS a
    JOIN sys.assembly_types AS at
      ON at.assembly_id = a.assembly_id
    JOIN sys.types AS t
      ON t.user_type_id = at.user_type_id
)
SELECT DB_NAME() AS database_name, *
FROM clr_objects
ORDER BY assembly_name, object_type, object_name;'
), N'')
FROM sys.databases AS d
WHERE d.state = 0      -- online
  AND d.database_id > 4; -- skip master, tempdb, model, msdb

EXEC sys.sp_executesql @sql;
```

- `sys.assemblies`: one row per assembly in the current DB.[3](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-assemblies-transact-sql?view=sql-server-ver17)  
- `sys.assembly_modules`: maps CLR assemblies to **procedures/functions/triggers** (and aggregate functions).[4](https://stackoverflow.com/questions/3155542/sql-server-how-to-list-all-clr-functions-procedures-objects-for-assembly)  
- `sys.assembly_types`: maps assemblies to **user‑defined types (UDTs)**.[4](https://stackoverflow.com/questions/3155542/sql-server-how-to-list-all-clr-functions-procedures-objects-for-assembly)

> This is adapted from Microsoft’s catalog view docs and the well‑known query pattern from the SQLCLR community.[3](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-assemblies-transact-sql?view=sql-server-ver17)[4](https://stackoverflow.com/questions/3155542/sql-server-how-to-list-all-clr-functions-procedures-objects-for-assembly)

---

## 3) **SSIS angle** — “SSIS‑related” CLR and **checking CLR usage in SSIS packages**

**Important context:**  
- **Script Task / Script Component** in SSIS run **managed .NET code inside the SSIS runtime** (VSTA), **not** as SQLCLR inside the Database Engine. You do **not** need `clr enabled` in SQL Server just because a package has a Script Task. `clr enabled` matters only if the package **calls SQLCLR objects in SQL Server** (e.g., `EXEC dbo.MyClrProc`).[5](https://learn.microsoft.com/en-us/sql/integration-services/control-flow/script-task?view=sql-server-ver17)  
- SQLCLR assemblies deployed **in SQL Server** are discoverable via §2. Management, registration, and trust of assemblies are covered in Microsoft docs.[6](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/assemblies/managing-clr-integration-assemblies?view=sql-server-ver17)

### 3A) Find **packages with Script Task / Script Component** (managed .NET inside SSIS runtime)

The following example inspects **SSISDB** to fetch the package XML and XQuery for Script Task / Script Component markers. (Namespaces differ by SSIS version; adjust if needed.)

```sql
/* List SSIS packages in SSISDB that contain Script Task or Script Component */
DECLARE @folder  sysname = N'%';     -- filter if needed
DECLARE @project sysname = N'%';     -- filter if needed

;WITH pkgs AS (
  SELECT p.project_id, p.name AS project_name, f.name AS folder_name, pk.name AS package_name, pk.package_id
  FROM   SSISDB.catalog.projects  AS p
  JOIN   SSISDB.catalog.folders   AS f  ON f.folder_id = p.folder_id
  JOIN   SSISDB.catalog.packages  AS pk ON pk.project_id = p.project_id
  WHERE  f.name LIKE @folder AND p.name LIKE @project
)
SELECT
    k.folder_name,
    k.project_name,
    k.package_name,
    CASE WHEN x.pkg.value('count(//DTS:Executable[@DTS:ExecutableType="Microsoft.SqlServer.Dts.Tasks.ScriptTask.ScriptTask"])','int') > 0
         THEN 1 ELSE 0 END AS has_script_task,
    CASE WHEN x.pkg.value('count(//pipeline:component[@componentClassID="Microsoft.SqlServer.Dts.Pipeline.ScriptComponentHost"])','int') > 0
         THEN 1 ELSE 0 END AS has_script_component
FROM pkgs AS k
CROSS APPLY (
    -- Get decrypted package XML from catalog
    SELECT CONVERT(xml, S.package_data) AS pkg
    FROM   SSISDB.internal.packages AS S
    WHERE  S.package_id = k.package_id
) AS x
-- SSIS package XML namespaces (adjust if your version uses different prefixes)
-- Default DTS namespace + dataflow/pipeline namespace
-- (Using WITH XMLNAMESPACES per-query is not permitted in CROSS APPLY; so embed prefixes inline)
```

> Notes:  
> * In SSIS 2012+, packages in SSISDB are stored as varbinary; the internal view exposes `package_data`. Converting to XML works when packages are stored as XML; encrypted packages require catalog decryption (the internal view/procs handle that for deployed packages). If your environment enforces encryption that prevents casting, call `catalog.get_package` to retrieve clear XML per package.  
> * Script Task identification uses the **ExecutableType** string; Script Component appears as a **data flow** component with class ID `Microsoft.SqlServer.Dts.Pipeline.ScriptComponentHost`. This is standard SSIS metadata for Script tasks/components.[5](https://learn.microsoft.com/en-us/sql/integration-services/control-flow/script-task?view=sql-server-ver17)

If your cast to XML fails (encryption), iterate over packages and call the built‑in **`catalog.get_package`** stored procedure to fetch the decrypted XML into a variable, then scan via XQuery.

### 3B) Find packages that **call SQLCLR objects** in the Database Engine

Combine the SQLCLR object inventory (§2) with package inspection. One pragmatic approach:

1) **Materialize** CLR‑backed object names (schema‑qualified) to a temp table:

```sql
-- Gather schema-qualified names of CLR-backed objects across DBs
IF OBJECT_ID('tempdb..#clr_objects') IS NOT NULL DROP TABLE #clr_objects;
CREATE TABLE #clr_objects (object_name sysname PRIMARY KEY);

DECLARE @sql nvarchar(max) = N'';
SELECT @sql = STRING_AGG(CONCAT(N'
USE ', QUOTENAME(d.name), N';
INSERT INTO #clr_objects(object_name)
SELECT DISTINCT QUOTENAME(SCHEMA_NAME(o.schema_id)) + ''.'' + QUOTENAME(o.name)
FROM sys.assembly_modules am
JOIN sys.objects o ON o.object_id = am.object_id;'
), N'')
FROM sys.databases AS d
WHERE d.state = 0 AND d.database_id > 4;

EXEC sys.sp_executesql @sql;
```

2) **Search package SQL** text in SSISDB for occurrences of those names (simple but effective):

```sql
/* Scan Execute SQL Tasks inside packages for calls to CLR-backed objects */
DECLARE @folder  sysname = N'%';
DECLARE @project sysname = N'%';

;WITH pkgs AS (
  SELECT p.project_id, p.name AS project_name, f.name AS folder_name, pk.name AS package_name, pk.package_id
  FROM   SSISDB.catalog.projects  AS p
  JOIN   SSISDB.catalog.folders   AS f  ON f.folder_id = p.folder_id
  JOIN   SSISDB.catalog.packages  AS pk ON pk.project_id = p.project_id
  WHERE  f.name LIKE @folder AND p.name LIKE @project
),
pkgxml AS (
  SELECT k.folder_name, k.project_name, k.package_name,
         CONVERT(xml, S.package_data) AS pkg
  FROM   pkgs AS k
  JOIN   SSISDB.internal.packages AS S
    ON   S.package_id = k.package_id
)
SELECT DISTINCT
    x.folder_name, x.project_name, x.package_name, c.object_name AS clr_object_referenced
FROM pkgxml AS x
CROSS JOIN #clr_objects AS c
WHERE x.pkg.exist(
      'declare default element namespace "www.microsoft.com/SqlServer/Dts";
       declare namespace SQLTask="www.microsoft.com/sqlserver/dts/tasks/sqltask";
       //DTS:Executable[@DTS:ExecutableType="Microsoft.SqlServer.Dts.Tasks.ExecuteSQLTask.ExecuteSQLTask"]
         /DTS:ObjectData/SQLTask:SqlTaskData/@SQLTask:SqlStatementSource[contains(., sql:variable("@needle"))]'
     ) = 1
OPTION (RECOMPILE);
```

- The XQuery looks for **Execute SQL Task** nodes and checks whether the **SQL text** (`SqlStatementSource`) **contains a CLR object name** from `#clr_objects`.  
- Adjust namespaces if your SSIS version differs. SSIS Script & Execute SQL Task metadata structures are documented; Script Task is the standard way SSIS hosts managed code, separate from SQLCLR.[5](https://learn.microsoft.com/en-us/sql/integration-services/control-flow/script-task?view=sql-server-ver17)

---

## 4) Bonus: quick “is CLR enabled?” check (for completeness)

```sql
SELECT name, value AS configured, value_in_use AS active
FROM sys.configurations
WHERE name = 'clr enabled';
```

This is the canonical method shown in community and docs; `1` = enabled, `0` = disabled.[7](https://stackoverflow.com/questions/4804873/sql-server-how-to-check-if-clr-is-enabled)

---

### References
- **`sys.dm_clr_loaded_assemblies`** & examples (permissions, join to `sys.assemblies`) — Microsoft Learn: *Returns a row for each managed user assembly loaded…* [1](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-clr-loaded-assemblies-transact-sql?view=azuresqldb-current)  
- **`sys.dm_clr_appdomains`** (maps to database via `db_id`, appdomain states) — Microsoft Learn [2](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-clr-appdomains-transact-sql?view=azuresqldb-current)  
- **`sys.assemblies`** (per‑DB assembly catalog) — Microsoft Learn [3](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-assemblies-transact-sql?view=sql-server-ver17)  
- **`sys.assembly_modules` / `sys.assembly_types`** (mapping assemblies to procs/functions/triggers/UDTs) — community pattern & docs [4](https://stackoverflow.com/questions/3155542/sql-server-how-to-list-all-clr-functions-procedures-objects-for-assembly)  
- **Managing CLR assemblies & security guidance** — Microsoft Learn (*Manage CLR integration assemblies*) [6](https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/assemblies/managing-clr-integration-assemblies?view=sql-server-ver17)  
- **SSIS Script Task** (uses .NET via VSTA; not SQLCLR) — Microsoft Learn (*Script Task – SSIS*) [5](https://learn.microsoft.com/en-us/sql/integration-services/control-flow/script-task?view=sql-server-ver17)

---

If you want, I can wrap §2–§3 into a **single stored procedure** that:
1) builds a server‑wide SQLCLR inventory,
2) highlights **currently loaded** ones, and
3) flags **SSIS packages** that reference those objects (plus Script Task/Component presence).