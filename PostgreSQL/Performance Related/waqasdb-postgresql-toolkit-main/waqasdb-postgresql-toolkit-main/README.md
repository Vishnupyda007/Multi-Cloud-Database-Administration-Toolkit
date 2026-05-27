<div align="center">

# بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ

# PostgreSQL Performance Toolkit

### Open-Source Database Performance Labs, Audits & Best Practices

**By [Waqas Ahmad](https://waqasdb.com) — PostgreSQL Performance Consultant**

</div>

---

> **"إِنَّ اللَّهَ يُحِبُّ إِذَا عَمِلَ أَحَدُكُمْ عَمَلًا أَنْ يُتْقِنَهُ"**
>
> *"Allah loves that when one of you does something, he does it with Itqān (excellence)."*
> — Prophet Muhammad ﷺ

---

## What Is This?

A collection of **reproducible PostgreSQL performance labs** with real benchmarks, real data, and real results. Every claim is backed by scripts you can run yourself.

Built from **8 years of production experience** including stabilizing an **18TB Fintech PostgreSQL cluster** from daily crashes to 5+ months of 100% uptime.

---

## Labs

### Phase 1: PostgreSQL Internals

| # | Lab | Status | Key Result |
|---|-----|--------|------------|
| 01 | [Bloat Analysis & Recovery](01-bloat-analysis/) | ✅ Complete | 50% storage recovered, 216K pages analyzed |
| 02 | [WAL & Checkpoints](02-wal-checkpoints/) | 🔄 Coming Soon | — |
| 03 | [Indexing Strategies](03-indexing-strategies/) | 🔄 Coming Soon | — |
| 04 | [Query Profiling](04-query-profiling/) | 🔄 Coming Soon | — |

### Phase 2: AWS RDS & Aurora

| # | Lab | Status |
|---|-----|--------|
| 05 | [RDS Setup & Optimization](05-rds-setup-optimization/) | 🔄 Coming Soon |
| 06 | [Aurora Architecture](06-aurora-architecture/) | 🔄 Coming Soon |
| 07 | [Connection Pooling](07-aurora-architecture/) | 🔄 Coming Soon |
| 08 | [Backup & Disaster Recovery](08-backup-disaster-recovery/) | 🔄 Coming Soon |

### Phase 3: Advanced Patterns

| # | Lab | Status |
|---|-----|--------|
| 09 | [Partitioning at Scale](09-partitioning/) | 🔄 Coming Soon |
| 10 | [Logical Replication & CDC](10-logical-replication/) | 🔄 Coming Soon |
| 11 | [NestJS + PostgreSQL](11-nestjs-optimization/) | 🔄 Coming Soon |
| 12 | [Monitoring & Alerting](12-monitoring-alerting/) | 🔄 Coming Soon |

---

## Quick Health Check

Run this on **any** PostgreSQL database to find bloated tables:

```sql
SELECT
    schemaname || '.' || relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS size,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    ROUND(n_dead_tup::numeric /
        NULLIF(n_live_tup, 0) * 100, 2) AS dead_pct,
    CASE
        WHEN n_dead_tup::numeric / NULLIF(n_live_tup, 0) > 0.20
        THEN 'CRITICAL'
        WHEN n_dead_tup::numeric / NULLIF(n_live_tup, 0) > 0.10
        THEN 'WARNING'
        ELSE 'HEALTHY'
    END AS status
FROM pg_stat_user_tables
WHERE n_live_tup > 0
ORDER BY n_dead_tup DESC
LIMIT 20;

```

If any table shows `CRITICAL` or `WARNING`, check the [Bloat Analysis Lab](01-bloat-analysis/) for the fix.

---
## Resources

| Resource | Description |
|----------|-------------|
| [Emergency Runbook](cheatsheets/emergency-runbook.md) | Quick commands when production is down |
| [Case Studies](case-studies/03-bloat-50-percent-recovery.md) | Real-world results |

---

## Values

This project is guided by three principles:

**Itqān (إتقان)** — Excellence. Every script is tested and documented.

**Amānah (أمانة)** — Trust. All results are real and reproducible.

**Nafa'a (نفع)** — Benefit. This knowledge is shared freely.

> *"When a person dies, their deeds end except for three: ongoing charity, **beneficial knowledge**, or a righteous child who prays for them."*
> — Prophet Muhammad ﷺ

---

## Tech Stack

PostgreSQL 14-17 | Aurora PostgreSQL | AWS RDS | pgBackRest | Node.js | NestJS | TypeScript | PgBouncer | Docker | Linux

---

## Author

**Waqas Ahmad** — PostgreSQL Performance Consultant

| | |
|---|---|
| 🌐 Website | [waqasdb.com](https://waqasdb.com) |
| 📩 Email | consulting@waqasdb.com |
| 💼 LinkedIn | [linkedin.com/in/waqas-ahmad](https://www.linkedin.com/in/waqas-ahmad-2110aa15b/) |
| 📋 Upwork | [upwork.com/freelancers/waqas](https://www.upwork.com/freelancers/~013273d290579a26c7) |

### Hire Me For

- Emergency PostgreSQL Performance Tuning
- Database Architecture Audit
- AWS RDS/Aurora Cost Optimization
- Backup Strategy Overhaul (pgBackRest)
- NestJS/Node.js Backend Optimization

---

## License

MIT License — See [LICENSE](LICENSE) for details.

Free to use in personal and commercial projects.

