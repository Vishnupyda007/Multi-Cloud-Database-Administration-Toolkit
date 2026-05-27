You **can** set `max_worker_processes = 20` with 16 vCPUs — there's no hard rule preventing it. But it's **not recommended** and here's why:

---

### The relationship between vCPUs and max_worker_processes

`max_worker_processes` defines the **total background worker slots** available across the entire PostgreSQL instance. The general rule is:

```
max_worker_processes >= max_parallel_workers + other background workers
```

PostgreSQL's own default formula ties it loosely to CPU count, but it's **not a hard 1:1 constraint**.

---

### Why 20 workers on 16 vCPUs is problematic

| Concern | Explanation |
|---|---|
| **Oversubscription** | 20 workers competing for 16 vCPUs causes context switching overhead — workers wait for CPU time |
| **parallel_workers relationship** | `max_parallel_workers` ≤ `max_worker_processes` — if you set workers > vCPUs, parallel queries don't actually run faster |
| **Cloud SQL PaaS limits** | Google Cloud SQL may **cap or override** `max_worker_processes` based on instance tier — you may not even be able to set it higher than the platform allows |
| **Memory pressure** | Each worker consumes `work_mem` — more workers = more memory usage simultaneously |

---

### Recommended values for 16 vCPUs

```
max_worker_processes        = 16    -- match vCPU count
max_parallel_workers        = 8     -- 50% of vCPUs for parallel query
max_parallel_workers_per_gather  = 4     -- per query parallelism
max_parallel_maintenance_workers = 4     -- for VACUUM, CREATE INDEX
```

---

### What happens if you set it to 20

```
max_worker_processes = 20   ← allowed but...
├── 16 vCPUs available
├── 20 workers can be spawned
├── at peak: 4 workers will always be waiting for CPU
└── net result: slower, not faster
```

---

### Cloud SQL PaaS additional constraint

Google Cloud SQL **restricts certain parameters** based on instance size and may:
- **Silently cap** `max_worker_processes` to the number of vCPUs
- **Reject** values above a platform-defined threshold
- **Override** the setting after instance restart

You can verify what's actually in effect vs what you set:

```sql
-- What is currently active
SHOW max_worker_processes;

-- What was requested vs what's running
SELECT name, setting, boot_val, reset_val, source
FROM pg_settings
WHERE name IN (
    'max_worker_processes',
    'max_parallel_workers',
    'max_parallel_workers_per_gather',
    'max_parallel_maintenance_workers'
);
```

---

### Bottom line

| Setting | Technically allowed | Recommended |
|---|---|---|
| `max_worker_processes = 20` on 16 vCPU | ✅ Possible | ❌ Not ideal |
| `max_worker_processes = 16` on 16 vCPU | ✅ Possible | ✅ Optimal |
| `max_worker_processes = 8` on 16 vCPU | ✅ Possible | ⚠️ Conservative but safe |

Set it to **match your vCPU count (16)** and tune `max_parallel_workers` downward if you want to reserve workers for background tasks like autovacuum and logical replication.