Absolutely—there are a few **PostgreSQL-native ways** to measure WAL size and WAL usage that work in **Cloud SQL for PostgreSQL** (subject to permissions). Below are ready‑to‑run queries with context on what they report and when they work.

***

## 1) **Total size of WAL files currently on disk (pg\_wal directory)**

> Uses the built-in function **`pg_ls_waldir()`** (PostgreSQL 10+) to list files in the WAL directory and sum their sizes. Requires a role that can execute `pg_ls_waldir()` (typically `postgres` or a user with `cloudsqlsuperuser` in Cloud SQL). [\[postgresql.org\]](https://www.postgresql.org/docs/current/functions-admin.html), [\[dba.stacke...change.com\]](https://dba.stackexchange.com/questions/192564/is-there-a-query-to-check-the-current-wal-size-in-postgresql)

```sql
-- Total WAL directory size in bytes
SELECT SUM(size) AS wal_dir_bytes
FROM pg_ls_waldir();

-- Human-readable
SELECT pg_size_pretty(SUM(size)) AS wal_dir_pretty
FROM pg_ls_waldir();
```

**Notes (Cloud SQL):**

*   If you hit `permission denied for function pg_ls_waldir`, run the query as the **`postgres`** user (which exists by default) or a user with **`cloudsqlsuperuser`**. Granting `EXECUTE` on this function to other users may be restricted in some managed environments; in Cloud SQL, privileges are limited versus full superuser. [\[cloud.google.com\]](https://cloud.google.com/sql/docs/postgres/users), [\[stackoverflow.com\]](https://stackoverflow.com/questions/77841904/how-can-i-grant-permissions-to-pg-catalog-functions-in-google-cloudsql-postgres)

**Why this works:** `pg_ls_waldir()` returns `(name, size, modification)` for each file in `pg_wal` and summing `size` gives the **current total occupied size** of WAL files on disk. [\[pgpedia.info\]](https://pgpedia.info/p/pg_ls_waldir.html)

***

## 2) **WAL generated since last reset (cumulative counters)**

> Use the **`pg_stat_wal`** view (PostgreSQL 14+) which includes **`wal_bytes`**—the total WAL bytes generated since `stats_reset`. This reflects **usage/generation**, not the on‑disk file count. [\[postgresql.org\]](https://www.postgresql.org/docs/current/monitoring-stats.html), [\[pgpedia.info\]](https://pgpedia.info/p/pg_stat_wal.html)

```sql
-- Overall WAL generation since last reset
SELECT wal_bytes,
       pg_size_pretty(wal_bytes) AS wal_bytes_pretty,
       stats_reset
FROM pg_stat_wal;
```

You can reset the counters (e.g., after a checkpoint or tuning change) with:

```sql
-- Reset cumulative WAL stats (affects pg_stat_wal counters)
SELECT pg_stat_reset_shared('wal');
```

> (Reset mechanisms and available columns vary by version; check the docs for your server version.) [\[postgresql.org\]](https://www.postgresql.org/docs/current/monitoring-stats.html)

***

## 3) **WAL generated over a period (LSN-diff method)**

> If you want **WAL volume over an interval** (e.g., last hour/day), record LSNs and compute differences with **`pg_wal_lsn_diff()`** or direct `pg_lsn` subtraction. [\[stackoverflow.com\]](https://stackoverflow.com/questions/39221598/how-to-query-wal-generation-rate-by-sql-query-in-postgresql), [\[pgpedia.info\]](https://pgpedia.info/p/pg_wal_lsn_diff.html)

```sql
-- Current WAL position (LSN)
SELECT pg_current_wal_lsn();

-- Example: compute bytes between two LSNs (replace with real samples)
SELECT pg_wal_lsn_diff('7/A25801C8', '7/A2000000') AS wal_bytes_diff;
```

A practical approach is to **snapshot `pg_current_wal_lsn()` periodically** (e.g., via `pg_cron`) and then compute differences to get WAL throughput over time. [\[estuary.dev\]](https://estuary.dev/blog/measuring-postgresql-wal-throughput/)

***

## 4) **Per-query WAL generation (for tuning)**

If you’ve enabled `pg_stat_statements`, you can look at **`wal_bytes`** per query (PG 13+), and with EXPLAIN you can include WAL metrics:

```sql
-- Top queries by WAL bytes (requires pg_stat_statements)
SELECT queryid, wal_bytes, calls,
       (wal_bytes / GREATEST(calls,1))::bigint AS wal_bytes_per_call
FROM pg_stat_statements
ORDER BY wal_bytes DESC
LIMIT 25;

-- Plan-level WAL metrics (PG 13+)
EXPLAIN (ANALYZE, BUFFERS, WAL)
<your_write_query_here>;
```

These are useful to reduce WAL pressure (e.g., batching writes, index choices, autovacuum tuning). [\[postgres.ai\]](https://postgres.ai/docs/postgres-howtos/performance-optimization/monitoring/how-to-reduce-wal-generation-rates)

***

## 5) **Extra: count WAL segments by filename**

Because a WAL segment has a fixed size (often 16 MiB, but configurable), counting segment files gives another angle. On PG ≥10, you can do:

```sql
-- Count segments and compute total based on configured segment size
WITH segs AS (
  SELECT COUNT(*) AS n
  FROM pg_ls_waldir()
  WHERE name <> 'archive_status'
)
SELECT n * pg_size_bytes(current_setting('wal_segment_size')) AS wal_bytes,
       pg_size_pretty(n * pg_size_bytes(current_setting('wal_segment_size'))) AS wal_pretty
FROM segs;
```

PostgreSQL 10+ exposes `wal_segment_size`; earlier versions assumed 16 MiB. [\[dba.stacke...change.com\]](https://dba.stackexchange.com/questions/192564/is-there-a-query-to-check-the-current-wal-size-in-postgresql)

***

### Permission & Managed-Platform caveats (Cloud SQL)

*   Cloud SQL does **not** grant full superuser; it provides **`cloudsqlsuperuser`** which is sufficient for many admin functions but not all grants on catalog functions in some cases. Prefer executing `pg_ls_waldir()` as **`postgres`**. [\[cloud.google.com\]](https://cloud.google.com/sql/docs/postgres/users), [\[stackoverflow.com\]](https://stackoverflow.com/questions/77841904/how-can-i-grant-permissions-to-pg-catalog-functions-in-google-cloudsql-postgres)
*   If third‑party monitoring tools require `pg_ls_waldir()` and fail with permission errors, grant `EXECUTE` if your environment allows; some managed services block this (community examples show such errors). [\[github.com\]](https://github.com/prometheus-community/postgres_exporter/issues/1100), [\[support.zabbix.com\]](https://support.zabbix.com/browse/ZBX-19734)

***

## Which query should you use?

*   **“Total size of WAL files on disk right now”** → `SUM(size)` from `pg_ls_waldir()` (Section 1). [\[pgpedia.info\]](https://pgpedia.info/p/pg_ls_waldir.html), [\[dba.stacke...change.com\]](https://dba.stackexchange.com/questions/192564/is-there-a-query-to-check-the-current-wal-size-in-postgresql)
*   **“How much WAL have we generated since X?”** → `pg_stat_wal.wal_bytes` (cumulative) or **LSN sampling** with `pg_wal_lsn_diff()` (periodic). [\[pgpedia.info\]](https://pgpedia.info/p/pg_stat_wal.html), [\[stackoverflow.com\]](https://stackoverflow.com/questions/39221598/how-to-query-wal-generation-rate-by-sql-query-in-postgresql)
*   **“Which queries generate the most WAL?”** → `pg_stat_statements.wal_bytes` + `EXPLAIN (… WAL)`. [\[postgres.ai\]](https://postgres.ai/docs/postgres-howtos/performance-optimization/monitoring/how-to-reduce-wal-generation-rates)

***

If you share your **Cloud SQL version** (e.g., PG 14/15/16) and whether you can run queries as **`postgres`**, I can tailor a **copy‑paste script** that picks the best method automatically and returns both **raw bytes** and **human‑readable sizes**.
