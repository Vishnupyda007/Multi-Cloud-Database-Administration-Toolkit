There's a syntax error in your `CREATE MATERIALIZED VIEW` (trailing comma before `FROM`). Here's the corrected full script with the `pg_cron` job:

```sql
-- 1. Create the materialized view (fix trailing comma)
CREATE MATERIALIZED VIEW localats_rmg_rr AS
  SELECT rmg_rr, status, skills_reqd
  FROM ent_data_store_fdw.vw_centralrepository_rmg_resourcerequest
  WHERE status = 'Open'
    AND skills_reqd IS NOT NULL
    AND skills_reqd <> '';

-- 2. Indexes
CREATE INDEX ON localats_rmg_rr (rmg_rr);
CREATE INDEX ON localats_rmg_rr (skills_reqd);

-- 3. Schedule refresh every 1 hour at IST (UTC+5:30)
-- pg_cron runs in UTC, so IST = UTC - 5:30.
-- "Every 1 hour" → run at minute 30 of every hour to align to IST :00
-- e.g. 00:30 UTC = 06:00 IST, 01:30 UTC = 07:00 IST, etc.
SELECT cron.schedule(
  'refresh_localats_rmg_rr',         -- job name
  '30 * * * *',                       -- every hour at :30 UTC = :00 IST
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY localats_rmg_rr$$
);
```

---

### Key notes

| Point | Detail |
|---|---|
| **Trailing comma fix** | Removed the `,` after `skills_reqd` in the SELECT list |
| **CONCURRENTLY** | Allows reads during refresh — requires at least one unique index. If `rmg_rr` is unique, add `UNIQUE` to that index (see below) |
| **UTC offset** | pg_cron uses UTC. IST = UTC+5:30, so `30 * * * *` fires at XX:30 UTC = XX+1:00:00 IST (every full hour IST) |
| **Database** | The `cron.schedule()` call must run in the **same database** where the view lives |

---

### If `rmg_rr` is unique, change the index to:

```sql
CREATE UNIQUE INDEX ON localats_rmg_rr (rmg_rr);
```

This enables `REFRESH MATERIALIZED VIEW CONCURRENTLY` (non-blocking refresh).

---

### To verify the job was registered:

```sql
SELECT jobid, jobname, schedule, command, active
FROM cron.job
WHERE jobname = 'refresh_localats_rmg_rr';
```

### To remove the job later:

```sql
SELECT cron.unschedule('refresh_localats_rmg_rr');
```



---------------------------


Let me check which databases are available and where `pg_cron` is installed.I can see the full picture now. `pg_cron` lives in the **`postgres`** database but can target other databases via the `database` parameter. Your materialized view will be in a specific DB (like `ent_data_store` or one of the `OneC_*` databases). 

Which database is the `localats_rmg_rr` mat view being created in?

Based on the pattern I see in your existing cron jobs (e.g. `refresh_fdw_EDS_views_OneC_5013_PT`), here's the exact script to use — just replace `<YOUR_TARGET_DB>`:

```sql
-- Run this in the postgres database (where pg_cron lives)
SELECT cron.schedule_in_database(
  'refresh_localats_rmg_rr',           -- job name
  '30 * * * *',                         -- every hour at :30 UTC = :00 IST
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY localats_rmg_rr$$,
  '<YOUR_TARGET_DB>'                    -- e.g. 'ent_data_store' or 'OneC_4681'
);
```

Or using the `database` column style (consistent with your existing jobs like `OneC_5013`):

```sql
INSERT INTO cron.job (schedule, command, nodename, nodeport, database, jobname, active)
VALUES (
  '30 * * * *',
  'REFRESH MATERIALIZED VIEW CONCURRENTLY localats_rmg_rr',
  'localhost',
  5432,
  '<YOUR_TARGET_DB>',
  'refresh_localats_rmg_rr',
  true
);
```

**Tell me which DB** (`ent_data_store`, `OneC_4681`, etc.) and I'll give you the exact ready-to-run command.





----------------------------------to schedule at every 12hrs IST


## Every 12 Hours IST = `30 6,18 * * *` in UTC

IST is **UTC+5:30**, so:

| IST Time | UTC Time |
|----------|----------|
| 12:00 AM IST (Midnight) | 06:30 PM UTC (18:30) |
| 12:00 PM IST (Noon) | 06:30 AM UTC (06:30) |

---

```sql
SELECT cron.schedule_in_database(
    'Mat Views Refresh Every 12hours for 5013',
    '30 6,18 * * *',        -- 06:30 UTC & 18:30 UTC = 12:00 PM & 12:00 AM IST
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY localats_rmg_rr$$,
    'ent_data_store'
);
```

---

## Verify Schedule

```sql
-- Check job is created
SELECT jobid, jobname, schedule, database, active
FROM cron.job
WHERE jobname = 'Mat Views Refresh Every 12hours for 5013'
```

---

## Alternative IST Timings If Needed

| Requirement | IST Times | UTC Cron |
|-------------|-----------|----------|
| Midnight & Noon | 00:00 & 12:00 IST | `30 6,18 * * *` |
| 6AM & 6PM | 06:00 & 18:00 IST | `30 0,12 * * *` |
| 8AM & 8PM | 08:00 & 20:00 IST | `30 2,14 * * *` |

> ✅ Replace `'ent_data_store'` with your actual target database name.


## ✅ Already Handled — No Slash Used

The solution I provided `30 6,18 * * *` already uses **comma notation**, not slash:

```sql
SELECT cron.schedule_in_database(
    'Mat Views Refresh Every 12hours for 5013',
    '30 6,18 * * *',    -- ✅ No slash, comma separated specific hours
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY localats_rmg_rr$$,
    'ent_data_store'
);
```

---

## Cron Breakdown

```
30  6,18  *  *  *
│   │
│   └── At hour 6 (06:30 UTC = 12:00 PM IST) 
│       AND hour 18 (18:30 UTC = 12:00 AM IST)
└── At minute 30
```

| Notation | Meaning |
|----------|---------|
| `*/12` | ❌ Every 12 hours from midnight UTC — not IST aligned |
| `6,18` | ✅ Explicit hours — IST aligned, no slash needed |

> `6,18` explicitly fires at **exactly 06:30 and 18:30 UTC** which equals **12:00 PM and 12:00 AM IST** — no slash required.




SELECT cron.schedule_in_database(
  'Mat Views Refresh Every 12hours for 5013',           -- job name
  '30 6,18 * * *',                         -- every hour at :30 UTC = :00 IST
  $$REFRESH MATERIALIZED VIEW CONCURRENTLY  evn_schema.mv_eds_associate;
    REFRESH MATERIALIZED VIEW  evn_schema.mv_eds_academic_credentials;$$,
  'OneC_5013'                    -- e.g. 'ent_data_store' or 'OneC_4681'
);