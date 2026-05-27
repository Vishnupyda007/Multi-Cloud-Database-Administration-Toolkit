Here's a complete guide to diagnosing and reclaiming WAL space in PostgreSQL:

---

### First — understand why WAL is large

```sql
-- Check current WAL size
SELECT pg_size_pretty(sum(size)) AS total_wal_size
FROM pg_ls_waldir();

-- Check individual WAL files
SELECT name, size, modification
FROM pg_ls_waldir()
ORDER BY modification DESC;

-- Check WAL settings currently in effect
SELECT name, setting, unit
FROM pg_settings
WHERE name IN (
    'wal_level',
    'max_wal_size',
    'min_wal_size',
    'wal_keep_size',
    'checkpoint_completion_target',
    'checkpoint_timeout',
    'archive_mode',
    'archive_command'
);
```

---

### Common reasons WAL accumulates

| Reason | Symptom | Fix |
|---|---|---|
| **Replication slot lag** | Slot not advancing | Drop or fix the slot |
| **Archiving stuck** | `archive_command` failing | Fix archive command |
| `wal_keep_size` too high | WAL retained unnecessarily | Reduce the value |
| `max_wal_size` too high | Checkpoints too infrequent | Tune checkpoint params |
| Long running transactions | WAL can't be recycled | Terminate or commit |
| High write load | Normal but large WAL generation | Tune `checkpoint_completion_target` |

---

### Step 1 — Check replication slots (most common culprit)

```sql
-- Check replication slots and their lag
SELECT
    slot_name,
    slot_type,
    active,
    active_pid,
    restart_lsn,
    confirmed_flush_lsn,
    pg_size_pretty(
        pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)
    )                           AS wal_retained_by_slot,
    wal_status,
    safe_wal_size
FROM pg_replication_slots
ORDER BY wal_retained_by_slot DESC;
```

If you see large `wal_retained_by_slot` values:

```sql
-- Drop an unused or stale replication slot
-- WARNING: Only drop if you're sure the consumer is gone
SELECT pg_drop_replication_slot('slot_name_here');
```

---

### Step 2 — Check archiving status

```sql
-- Check if archiving is stuck
SELECT
    archived_count,
    last_archived_wal,
    last_archived_time,
    failed_count,
    last_failed_wal,
    last_failed_time,
    EXTRACT(EPOCH FROM (now() - last_archived_time)) / 60 AS minutes_since_last_archive
FROM pg_stat_archiver;
```

If `failed_count` is high or `last_failed_time` is recent → fix the `archive_command` in `postgresql.conf`.

---

### Step 3 — Check for long running transactions blocking WAL recycling

```sql
-- Long running transactions holding WAL back
SELECT
    pid,
    usename,
    application_name,
    state,
    wait_event_type,
    wait_event,
    now() - xact_start           AS transaction_age,
    now() - query_start          AS query_age,
    left(query, 100)             AS query_snippet
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
  AND now() - xact_start > INTERVAL '5 minutes'
ORDER BY transaction_age DESC;

-- Terminate if needed
-- SELECT pg_terminate_backend(pid);
```

---

### Step 4 — Force a checkpoint to flush and recycle WAL

```sql
-- Force checkpoint (flushes dirty pages, allows WAL recycling)
CHECKPOINT;

-- Check LSN position after checkpoint
SELECT pg_current_wal_lsn(), pg_current_wal_insert_lsn();
```

---

### Step 5 — Tune WAL parameters to prevent future bloat

```sql
-- In postgresql.conf or Cloud SQL flags:

-- Max WAL size before forced checkpoint (default 1GB — reduce if WAL grows too large)
max_wal_size = 2GB              -- tune based on your write load

-- Minimum WAL to keep (don't set too high)
min_wal_size = 128MB

-- How long to keep WAL for standbys (set 0 if using replication slots instead)
wal_keep_size = 0               -- MB, 0 = let replication slots handle it

-- Spread checkpoint I/O over more time (reduces WAL spike)
checkpoint_completion_target = 0.9

-- How often checkpoints happen (default 5min)
checkpoint_timeout = 10min
```

---

### Step 6 — pg_switch_wal to force WAL segment rotation

```sql
-- Force switch to a new WAL segment (superuser only)
-- Old segment becomes eligible for recycling after checkpoint
SELECT pg_switch_wal();
```

---

### Step 7 — On Cloud SQL PaaS specifically

Since you're on **Cloud SQL**, you don't have direct filesystem access but you can:

1. **Check WAL retention settings** in Cloud SQL flags:
   - `max_wal_size`
   - `wal_keep_size`
   - `checkpoint_timeout`

2. **Replication slots** — check and drop unused ones (biggest culprit on managed PaaS)

3. **PITR (Point-in-Time Recovery)** — Cloud SQL retains WAL for PITR window:
   ```
   GCP Console → Cloud SQL instance → Backups
   → Check "Retained transaction logs" days
   → Reduce PITR retention window if WAL storage is a concern
   ```

4. **Storage autoresize** — Cloud SQL auto-grows storage but doesn't shrink automatically. Reclaiming requires:
   - Fixing the root cause (slots, archiving, PITR window)
   - Storage usage will naturally reduce as old WAL is recycled

---

### Quick diagnosis flow

```
WAL size is large
      │
      ├── pg_replication_slots → any slot with large wal_retained_by_slot?
      │         └── YES → drop unused slot → WAL reclaimed immediately
      │
      ├── pg_stat_archiver → failed_count > 0?
      │         └── YES → fix archive_command → WAL reclaimed after archiving catches up
      │
      ├── pg_stat_activity → long running transactions?
      │         └── YES → terminate or wait → WAL recycled after commit/rollback
      │
      └── None of the above?
                └── Tune max_wal_size + checkpoint_timeout + run CHECKPOINT
```