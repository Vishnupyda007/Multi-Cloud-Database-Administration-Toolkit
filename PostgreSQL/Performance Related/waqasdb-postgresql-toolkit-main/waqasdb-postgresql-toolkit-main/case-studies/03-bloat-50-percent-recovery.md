
# Case Study: PostgreSQL Bloat Analysis — 50% Storage Recovery on 5M Row Table

> **"وَلَا تُسْرِفُوا ۚ إِنَّهُ لَا يُحِبُّ الْمُسْرِفِينَ"**
>
> *"And do not waste. Indeed, He does not love the wasteful."*
> — Surah Al-A'raf 7:31

---

## Overview

| Field | Detail |
|-------|--------|
| **Type** | Lab Experiment (Fully Reproducible) |
| **Date** | February 2026 |
| **Author** | Waqas Ahmad — WaqasDB |
| **Database** | PostgreSQL 17 |
| **Dataset** | 5,000,000 rows (user_sessions) |
| **Tools** | pgstattuple, pg_freespacemap |
| **Scripts** | [01-bloat-analysis/](../01-bloat-analysis/) |

---

## The Problem

Every time PostgreSQL executes an `UPDATE`, it does NOT modify the row in place.
Instead it:

1. Creates a **new version** of the row (new tuple)
2. Marks the **old version** as dead
3. The dead version stays on disk until `VACUUM` cleans it

This is called **MVCC (Multi-Version Concurrency Control)**.

The critical issue: `VACUUM` marks dead space as **reusable** but
**never returns it to the operating system**. The file never shrinks.

Over time, tables grow far beyond their actual data size.
This is **bloat** — the silent performance killer.

Most teams never notice because:
- `VACUUM` reports success ("0 dead tuples")
- Table seems healthy at the surface
- The real waste is hidden **inside the pages**

---

## The Experiment

### Environment

```
Database:     PostgreSQL 17
Table:        user_sessions
Columns:      id (BIGSERIAL), user_id (INT), session_token (VARCHAR),
              ip_address (INET), device_info (JSONB),
              created_at (TIMESTAMP), updated_at (TIMESTAMP),
              is_active (BOOLEAN)
Initial Rows: 5,000,000
Extensions:   pgstattuple, pg_freespacemap
```

### Workload

Simulated a production SaaS workload where user sessions
are constantly updated (heartbeats, status changes, activity tracking):

```sql
-- 10 rounds × 500,000 random updates = 5,000,000 total UPDATEs
DO $$
BEGIN
    FOR i IN 1..10 LOOP
        UPDATE user_sessions
        SET updated_at = NOW(), is_active = NOT is_active
        WHERE id IN (
            SELECT id FROM user_sessions
            ORDER BY random() LIMIT 500000
        );
    END LOOP;
END $$;
```

This is realistic because in production:
- Session tables receive constant UPDATEs
- User activity flags toggle frequently
- Timestamps update on every request
- Status fields change throughout user lifecycle

---

## Results

### Phase 1: Bloat Measurement (Tuple Level)

After 5M UPDATEs, `pgstattuple` revealed:

| Metric | Value |
|--------|-------|
| Table file size | 1,693 MB (1,775,247,360 bytes) |
| Live tuples | 5,000,000 |
| Live data size | 779 MB (816,941,144 bytes) |
| Live data % | 46.02% |
| Dead tuples | 193,507 |
| Dead data size | 30 MB (31,616,827 bytes) |
| Dead data % | 1.78% |
| Free space | 806 MB (845,296,816 bytes) |
| Free space % | **47.62%** |

**Key Finding:** Autovacuum had already cleaned most dead tuples
(from ~5M down to 193K). But 47.62% of the table was **free space
trapped inside the file** that autovacuum could not reclaim.

```
TABLE COMPOSITION:
══════════════════

████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░  46.02% Live Data
█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   1.78% Dead Tuples
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  47.62% WASTED SPACE
████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   4.58% Headers/Alignment

█ = Useful    ░ = Waste
```

### Phase 2: Deep Analysis (Page Level)

Standard tuple-level analysis only shows the summary.
To understand the **true damage**, I inspected every individual
8KB page using `pg_freespacemap`.

**Total pages analyzed: 216,704**

| Page Health | Pages | Size (MB) | % of Table | Description |
|-------------|-------|-----------|------------|-------------|
| 🟢 Fully Packed | 2,516 | 19.66 | 1.2% | Zero free bytes — perfect |
| 🟡 Minor Gaps | 18,789 | 146.79 | 8.7% | 1-1,024 bytes free |
| 🟠 Moderate Holes | 13,216 | 103.25 | 6.1% | 1-2 KB free per page |
| 🔴 Heavy Damage | 42,837 | 334.66 | 19.8% | 2-4 KB free per page |
| 🔴 Severely Empty | 105,426 | 823.64 | 48.7% | 4-6 KB free per page |
| 🔴 Near Empty | 33,920 | 265.00 | 15.6% | 6-8 KB free per page |

```
PAGE HEALTH VISUALIZATION:
══════════════════════════

🟢 Fully Packed     █                                      1.2%
🟡 Minor Gaps       █████                                  8.7%
🟠 Moderate Holes   ████                                   6.1%
🔴 Heavy Damage     ████████████                          19.8%
🔴 Severely Empty   ███████████████████████████████       48.7%
🔴 Near Empty       ██████████                            15.6%
```

**Critical Findings:**
- Only **1.2%** of pages were fully packed (healthy)
- **64.3%** of all pages were more than **half empty**
- The majority of pages (48.7%) had 4-6 KB of free space
  out of 8 KB total — meaning they held just a few live tuples
  surrounded by empty space

**What this means:**
- PostgreSQL reads ENTIRE pages, not individual rows
- A sequential scan reads all 216,704 pages including the waste
- Buffer cache stores full pages — 47% of cache holds empty space
- Every query does roughly **2x more I/O** than necessary

### Phase 3: Recovery Comparison

Three recovery methods tested on the same bloated table:

| Method | Size Before | Size After | Reduction | Locks Table? | Production Safe? |
|--------|-------------|------------|-----------|--------------|------------------|
| `VACUUM` | 1,693 MB | **1,693 MB** | **0%** | No lock | ✅ Yes |
| `VACUUM FULL` | 1,693 MB | **847 MB** | **50%** | Full exclusive lock | ❌ Causes downtime |
| `pg_repack` | 1,693 MB | **~847 MB** | **50%** | Brief lock at end only | ✅ Yes |

**After VACUUM FULL:**

| Metric | Bloated | Fixed |
|--------|---------|-------|
| Table Size | 1,693 MB | 847 MB |
| Dead Tuples | 193,507 | 0 |
| Free Space % | 47.62% | **1.51%** |
| Fully Packed Pages | 1.2% | **~99%** |
| Bloat Ratio | 2.6x | **1.0x** |

**Why 1.51% free space (not 0%)?**

This is physically unavoidable and perfectly healthy.
Each page is 8,192 bytes. Each tuple is ~163 bytes.
8,192 / 163 = 50.25 tuples per page.
You cannot fit 0.25 of a tuple — the remaining bytes
become free space. Plus page headers (24 bytes) and
tuple pointers (4 bytes each) add overhead.

Any `free_pct` below 5% is considered **optimal**.

### Phase 4: Prevention (Autovacuum Tuning)

After fixing the bloat, I applied per-table autovacuum tuning
and re-ran the **identical** UPDATE workload:

**Default Settings (Why They Fail):**

```
autovacuum_vacuum_scale_factor = 0.2  (20%)
For 5M rows: 5,000,000 × 0.2 = 1,000,000 dead rows before vacuum triggers!
```

**Tuned Settings:**

```sql
ALTER TABLE user_sessions SET (
    autovacuum_vacuum_scale_factor = 0.01,      -- 1% (not 20%)
    autovacuum_vacuum_threshold = 1000,          -- Minimum 1000 dead rows
    autovacuum_analyze_scale_factor = 0.005,     -- Re-analyze at 0.5%
    autovacuum_vacuum_cost_delay = 2,            -- Faster vacuum cycles
    autovacuum_vacuum_cost_limit = 1000          -- More work per cycle
);

-- MATH: 5,000,000 × 0.01 + 1000 = 51,000 dead rows trigger
-- That's 20x more aggressive than default!
```

**Results After Tuning:**

| Metric | Default Autovacuum | Tuned Autovacuum |
|--------|-------------------|------------------|
| Dead Tuples After Workload | 193,507 | **0** ✅ |
| Autovacuum Runs | ~1 | **3** ✅ |
| Free Space % | 47.62% | 49.52% |
| Table Size | 1,693 MB | 1,693 MB |

**Key Insight:**

Tuned autovacuum cleaned dead tuples **3x more aggressively**,
leaving zero dead rows. However, the table file size remained
the same because VACUUM (even aggressive autovacuum) does not
shrink files.

**Why this still matters in production:**

This lab ran 5M updates in seconds (extreme burst).
In real production, updates spread over hours/days.
With tuned autovacuum:

- Dead tuples cleaned **between** update bursts
- New updates **reuse** freed space instead of allocating new pages
- Table growth stays controlled at **1.2-1.3x** instead of **2.6x**
- Combined with monthly `pg_repack`, bloat stays near zero

---

## Business Impact Analysis

### At Different Scales

| Database Size | Wasted Storage (47% bloat) | Monthly AWS gp3 Cost | Annual Waste |
|---------------|---------------------------|---------------------|--------------|
| 100 GB | 47 GB | $3.76 | $45 |
| 500 GB | 235 GB | $18.80 | $226 |
| 1 TB | 470 GB | $37.60 | $451 |
| 5 TB | 2.35 TB | $188.00 | $2,256 |
| 10 TB | 4.7 TB | $376.00 | $4,512 |
| **18 TB** | **8.5 TB** | **$680.00** | **$8,160** |

### Hidden Costs Beyond Storage

| Impact Area | Effect |
|-------------|--------|
| **Query Speed** | Sequential scans read 2x more pages than necessary |
| **Buffer Cache** | 47% of shared_buffers holds empty pages — effective cache is halved |
| **Backup Size** | pgBackRest/pg_dump backs up the FULL file including bloat |
| **Backup Time** | 2x longer backups = wider backup window = more risk |
| **Replication** | WAL generated from bloated tables = more network traffic to replicas |
| **Instance Size** | Teams upgrade to larger instances instead of fixing bloat — overpaying |
| **Recovery Time** | Crash recovery replays WAL for entire bloated table — slower RTO |

### Real Client Example

At a previous client (18TB Fintech/KYC PostgreSQL cluster):

- Primary server was crashing daily
- Bloat was one contributing factor
- Combined with WAL/checkpoint tuning and query optimization:
  - Achieved **100% uptime for 5+ months**
  - Reduced backup footprint from **18TB to 7.5TB** using pgBackRest
  - Reduced database operations by **57%** per API request

---

## Three-Layer Prevention Strategy

```
COMPLETE PRODUCTION DEFENSE:
════════════════════════════

LAYER 1: Autovacuum Tuning (Continuous)
├── Prevents dead tuple accumulation
├── Keeps buffer cache clean
├── Reduces crash recovery time
├── Helps with space reuse over time
└── Cost: Zero — just configuration

LAYER 2: Scheduled pg_repack (Weekly/Monthly)
├── Actually shrinks the file on disk
├── No table lock during operation
├── Run during low-traffic window
├── Reclaims the free space autovacuum cannot
└── Cost: Brief CPU/IO spike during repack

LAYER 3: Table Partitioning (Architectural)
├── Partition by time range (monthly/weekly)
├── DROP old partitions instead of DELETE
├── Each partition stays smaller and manageable
├── Eliminates bloat problem at design level
└── Cost: Schema change (one-time migration)

All three layers together = near-zero bloat
```

---

## How to Reproduce This Lab

### Prerequisites

```bash
# PostgreSQL 14+ installed
createdb bloat_lab
```

### Execute

```bash
cd 01-bloat-analysis/

# Step 1: Setup (5M rows)
psql -d bloat_lab -f scripts/01-create-table.sql

# Step 2: Baseline measurement
psql -d bloat_lab -f scripts/02-baseline-measurement.sql

# Step 3: Create bloat (5M UPDATEs)
psql -d bloat_lab -f scripts/03-create-bloat.sql

# Step 4: Measure tuple-level bloat
psql -d bloat_lab -f scripts/04-measure-bloat-tuples.sql

# Step 5: Measure page-level bloat
psql -d bloat_lab -f scripts/05-measure-bloat-pages.sql

# Step 6: Try VACUUM (observe: 0% size change)
psql -d bloat_lab -f scripts/06-fix-vacuum.sql

# Step 7: Fix with VACUUM FULL (observe: 50% reduction)
psql -d bloat_lab -f scripts/07-fix-vacuum-full.sql

# Step 8: Verify fix
psql -d bloat_lab -f scripts/08-verify-fix.sql

# Step 9: Apply autovacuum tuning
psql -d bloat_lab -f scripts/09-autovacuum-tuning.sql

# Step 10: Re-run workload with tuning
psql -d bloat_lab -f scripts/10-rerun-with-tuning.sql
```

Full scripts: [01-bloat-analysis/scripts/](../01-bloat-analysis/scripts/)

---

## Quick Diagnostic — Check YOUR Database

Run this query on any PostgreSQL database to find bloated tables:

```sql
SELECT
    schemaname || '.' || relname AS table_name,
    pg_size_pretty(pg_relation_size(relid)) AS size,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    ROUND(n_dead_tup::numeric /
        NULLIF(n_live_tup, 0) * 100, 2) AS dead_pct,
    CASE
        WHEN n_dead_tup::numeric / NULLIF(n_live_tup, 0) > 0.20
        THEN 'CRITICAL — Vacuum immediately'
        WHEN n_dead_tup::numeric / NULLIF(n_live_tup, 0) > 0.10
        THEN 'WARNING — Schedule maintenance'
        WHEN n_dead_tup::numeric / NULLIF(n_live_tup, 0) > 0.05
        THEN 'MONITOR — Watch this table'
        ELSE 'HEALTHY'
    END AS status
FROM pg_stat_user_tables
WHERE n_live_tup > 0
ORDER BY n_dead_tup DESC
LIMIT 20;
```

If any table shows `CRITICAL`, you're burning money every day.

---

## Key Takeaways

```
1. VACUUM ≠ Space Reclamation
   It cleans dead tuples but NEVER shrinks the file.
   The space is marked "reusable" but stays allocated.

2. Surface Metrics Lie
   "0 dead tuples" does NOT mean "healthy table."
   You must inspect at the PAGE level to see true damage.

3. Default Autovacuum Is Too Slow
   20% scale factor means millions of dead rows accumulate
   before cleanup on large tables. Tune per-table.

4. Prevention Requires Three Layers
   Autovacuum tuning + pg_repack + partitioning
   No single tool solves bloat completely.

5. The Cost Is Hidden But Real
   Bloat wastes storage, slows queries, pollutes cache,
   inflates backups, and delays recovery.
   At scale, this costs thousands per month.
```

---

## Honesty Statement (Amānah)

This is a **lab experiment**, not a production case study.
The workload (5M updates in seconds) is more extreme than
typical production patterns. In real-world scenarios with
spread-out updates, tuned autovacuum is more effective at
preventing bloat accumulation.

The measurements are **real and reproducible**. Anyone can
run these scripts and get similar results on PostgreSQL 14+.
---

## Author

**Waqas Ahmad** — PostgreSQL Performance Consultant

| | |
|---|---|
| 🌐 Website | [waqasdb.com](https://waqasdb.com) |
| 📩 Email | consulting@waqasdb.com |
| 💼 LinkedIn | [Waqas Ahmad](https://www.linkedin.com/in/waqas-ahmad-2110aa15b/) |

> *"إِنَّ اللَّهَ يُحِبُّ إِذَا عَمِلَ أَحَدُكُمْ عَمَلًا أَنْ يُتْقِنَهُ"*
>
> *"Allah loves that when one of you does something,
> he does it with Itqān (excellence)."*
> — Prophet Muhammad ﷺ

---

*Part of [PostgreSQL Performance Toolkit](../README.md)*   
*License: MIT — Free to use and learn from*