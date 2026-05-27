# Lab 01: PostgreSQL Bloat Analysis & Recovery

> **"وَلَا تُسْرِفُوا ۚ إِنَّهُ لَا يُحِبُّ الْمُسْرِفِينَ"**
>
> *"And do not waste. Indeed, He does not love the wasteful."*
> — Surah Al-A'raf 7:31

---

## What This Lab Proves

UPDATE-heavy PostgreSQL tables silently accumulate internal
fragmentation (bloat) that **standard VACUUM cannot fix**.

### Key Results

| Metric | Baseline | Bloated | After VACUUM | After VACUUM FULL |
|--------|----------|---------|--------------|-------------------|
| Table Size | 650 MB | 1,693 MB | 1,693 MB | 847 MB |
| Dead Tuples | 0 | 193,507 | 0 | 0 |
| Free Space % | ~2% | 47.62% | ~47% | 1.51% |
| Packed Pages | ~98% | 1.2% | 1.2% | ~99% |

**VACUUM recovered 0% of disk space. VACUUM FULL recovered 50%.**

### Page-Level Analysis (216,704 pages inspected)

| Page Health | Pages | % of Table |
|-------------|-------|------------|
| Fully Packed | 2,516 | 1.2% |
| Minor Gaps | 18,789 | 8.7% |
| Moderate Holes | 13,216 | 6.1% |
| Heavy Damage | 42,837 | 19.8% |
| Severely Empty | 105,426 | 48.7% |
| Near Empty | 33,920 | 15.6% |

**64.3% of all pages were more than half empty.**

### Autovacuum Tuning Results

| Metric | Default Settings | Tuned Settings |
|--------|-----------------|----------------|
| Dead Tuples After Workload | 193,507 | 0 |
| Autovacuum Runs | ~1 | 3 |
| Free Space % | 47.62% | 49.52% |

---

## How to Run

```bash
# Create test database
createdb bloat_lab

# Execute scripts in order
psql -d bloat_lab -f scripts/01-create-table.sql
psql -d bloat_lab -f scripts/02-baseline-measurement.sql
psql -d bloat_lab -f scripts/03-create-bloat.sql
psql -d bloat_lab -f scripts/04-measure-bloat-tuples.sql
psql -d bloat_lab -f scripts/05-measure-bloat-pages.sql
psql -d bloat_lab -f scripts/06-fix-vacuum.sql
psql -d bloat_lab -f scripts/07-fix-vacuum-full.sql
psql -d bloat_lab -f scripts/08-verify-fix.sql
psql -d bloat_lab -f scripts/09-autovacuum-tuning.sql
psql -d bloat_lab -f scripts/10-rerun-with-tuning.sql

```
---

## Scripts

| # | Script | Purpose |
|---|--------|---------|
| 01 | create-table.sql | Create table + insert 5M rows |
| 02 | baseline-measurement.sql | Record initial healthy state |
| 03 | create-bloat.sql | 10 × 500K random UPDATEs |
| 04 | measure-bloat-tuples.sql | pgstattuple analysis |
| 05 | measure-bloat-pages.sql | pg_freespacemap page inspection |
| 06 | fix-vacuum.sql | Regular VACUUM (0% size reduction) |
| 07 | fix-vacuum-full.sql | VACUUM FULL (50% size reduction) |
| 08 | verify-fix.sql | Comprehensive health verification |
| 09 | autovacuum-tuning.sql | Per-table prevention settings |
| 10 | rerun-with-tuning.sql | Test tuned settings under load |
| 11 | diagnostic-toolkit.sql | Reusable audit queries for any DB |

---

## Business Impact at Scale

| Database Size | Wasted at 47% Bloat | Monthly AWS Cost (gp3) |
|---------------|---------------------|----------------------|
| 100 GB | 47 GB | $3.76 |
| 1 TB | 470 GB | $37.60 |
| 5 TB | 2.35 TB | $188 |
| 18 TB | 8.5 TB | $680 |

Plus: Every query reads 2x more disk pages than necessary.

---

## Prevention Strategy

### Layer 1: Autovacuum Tuning
```sql
ALTER TABLE your_table SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_vacuum_threshold = 1000,
    autovacuum_analyze_scale_factor = 0.005,
    autovacuum_vacuum_cost_delay = 2,
    autovacuum_vacuum_cost_limit = 1000
);
```

### Layer 2: Scheduled pg_repack (Weekly/Monthly)
```bash
pg_repack -d your_database -t your_table --no-superuser-check
```

### Layer 3: Table Partitioning
DROP old partitions instead of DELETE — instant, zero bloat.

---

## Requirements

- PostgreSQL 14+
- Extensions: pgstattuple, pg_freespacemap
- ~2 GB free disk space for lab data

---

## Author

**Waqas Ahmad** | [WaqasDB](https://waqasdb.com)   
PostgreSQL Performance Consultant   
consulting@waqasdb.com

