That's an excellent and very important infrastructure question.

The direct answer is: **You cannot query for *allocated* IOPS from within PostgreSQL itself.**

IOPS (Input/Output Operations Per Second) is an infrastructure-level metric that defines the performance of the underlying storage disk. The PostgreSQL database engine is a software layer that runs *on top* of this infrastructure; it is not aware of the specific performance characteristics it has been allocated.

Think of it like this: A car's engine knows its own RPM, but it doesn't know the speed limit of the road it's on. The database knows how much I/O it's *doing*, but it doesn't know the *limit* set by the cloud provider.

Therefore, to find your allocated IOPS, you must check the Cloud SQL instance settings. To see your *actual* I/O usage, you use Cloud Monitoring metrics.

---

### **Part 1: How to Check Your *Allocated* IOPS**

This is determined by your instance's machine type and disk size. You can find this information in the Google Cloud Console.

1.  Navigate to the **Google Cloud Console**.
2.  Go to **SQL** from the navigation menu.
3.  Click on your PostgreSQL instance name to open its **Overview** page.
4.  In the **Configuration** section, look for **Storage > Disk type and Disk size**.

The allocated IOPS are directly tied to these settings. For SSDs, Google Cloud provides a baseline performance that scales with the disk size.

*   **Read IOPS:** Scales between a baseline and a max limit based on vCPU count.
*   **Write IOPS:** Scales between a baseline and a max limit based on vCPU count.

For the exact numbers, you must refer to the [official Cloud SQL for PostgreSQL pricing and performance documentation](https://cloud.google.com/sql/docs/postgres/instance-settings#performance), as Google updates these values periodically. As of late 2023, the performance for SSDs scales at **30 IOPS per GB** for both reads and writes, up to a maximum defined by the instance's vCPU count.

---

### **Part 2: How to Check Your *Actual* I/O Usage**

While you can't query for the *limit*, you can monitor your *current* usage. This is crucial for performance tuning and identifying bottlenecks.

#### **Method A: The Cloud Console Metrics (Recommended)**

This is the best and easiest way to see your actual IOPS usage over time.

1.  On your Cloud SQL instance page, click the **"METRICS"** tab. (It may also be labeled "MONITORING").
2.  Look for the charts titled:
    *   **`Disk read I/O operations`** (This is your read IOPS)
    *   **`Disk write I/O operations`** (This is your write IOPS)
3.  You can adjust the time frame (e.g., last hour, last 6 hours) to see your usage patterns. If these charts are consistently flat at a high number, you may be hitting your IOPS limit (throttling).

#### **Method B: Querying Inside PostgreSQL (For Cumulative Stats)**

You can get cumulative I/O statistics from PostgreSQL's `pg_statio` views. This does **not** give you a real-time IOPS rate, but it shows the total number of blocks read, which can be useful for identifying "hot" tables.

**Script to Find Tables with the Most I/O Activity:**

```sql
SELECT
    relname AS "Table Name",
    pg_size_pretty(pg_relation_size(relid)) as "Table Size",
    heap_blks_read AS "Heap Blocks Read",
    heap_blks_hit AS "Heap Blocks Hit (in-memory)",
    idx_blks_read AS "Index Blocks Read",
    idx_blks_hit AS "Index Blocks Hit (in-memory)"
FROM
    pg_statio_user_tables
ORDER BY
    (heap_blks_read + idx_blks_read) DESC
LIMIT 20;
```

**What this tells you:**
*   **`heap_blks_read`**: The number of disk blocks read from the table itself. A high number indicates heavy disk I/O.
*   **`heap_blks_hit`**: The number of blocks read from PostgreSQL's shared buffer cache (in memory). A high `hit` vs. `read` ratio is good—it means you are not going to disk.
*   This query helps you find which tables are responsible for the most disk I/O since the last statistics reset.

### **Summary Table**

| What do you want to know? | How do you find it? | Tool |
| :--- | :--- | :--- |
| **Allocated IOPS** (My Limit) | Check the instance's Disk Size and Machine Type. | **Google Cloud Console (Instance Overview)** |
| **Actual IOPS Usage** (Real-Time Rate) | View the "Disk read/write I/O operations" charts. | **Cloud SQL Metrics / Monitoring Tab** |
| **Which tables cause the most I/O?** | Query the `pg_statio_user_tables` view. | **pgAdmin / SQL Query Tool** |