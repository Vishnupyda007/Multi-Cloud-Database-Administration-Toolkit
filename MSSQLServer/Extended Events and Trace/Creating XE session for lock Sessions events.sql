**Creating XE session for lock events**

I need to provide a sample XE session that captures "lock_acquired" and "lock_released" events, including sql_text and session info, and writes them to a file. I should mention the potential overhead and suggest filtering by database or object_id to reduce it. I'll include a script for creating the XE session and explain how to read the output files. I'll also briefly touch on extracting data from the system_health ring buffer for deadlock graphs. Lastly, I’ll show how to correlate this with DMVs. I'll keep it concise and under six sections. 

I'll also suggest a follow-up for further exploration.
### Short answer
You cannot query **past** locks from DMVs — `sys.dm_tran_locks` and `sys.dm_exec_requests` only show *current* state. To capture historical lock activity (old locks) you must **record** it: use an Extended Events session (recommended) or a server-side trace / SQL Audit to log `lock_acquired` / `lock_released` (or deadlock graphs). The deadlock XML in `system_health` already gives you the locks involved in deadlocks, but not a full history of every lock.

---

### Options to capture old/historical locks
- **Extended Events (XE)** — best practice: create a server-side XE session that captures `lock_acquired` and `lock_released` (and optionally `sql_text`, `session_id`, `database_id`, `object_id`) and writes to file. You can filter by database, object, or application to limit overhead.  
- **Server-side trace / Profiler** — deprecated; can capture lock events but use XE instead.  
- **SQL Audit** — can capture certain activity but not fine-grained lock acquire/release events the way XE can.  
- **system_health** — already captures deadlock graphs (useful for deadlock-related locks only).  
- **fn_dblog / transaction log** — not a reliable or supported way to enumerate historical locks; not recommended for this purpose.  
- **Third-party monitoring / APM** — many monitoring tools can record historical blocking/lock events with less manual setup.

---

### Example: Extended Events session to record lock acquire/release
This example creates an XE session that records `lock_acquired` and `lock_released` with SQL text and session info, writing to a file. **Filter** it (by `database_id`, `object_id`, `sql_text`, or `client_app_name`) to reduce volume and overhead.

```sql
CREATE EVENT SESSION [CaptureLocks] ON SERVER
ADD EVENT sqlserver.lock_acquired(
    ACTION(sqlserver.sql_text, sqlserver.session_id, sqlserver.client_app_name, sqlserver.database_id)
    WHERE (sqlserver.database_id = 5) -- optional filter: change DB id or remove
),
ADD EVENT sqlserver.lock_released(
    ACTION(sqlserver.sql_text, sqlserver.session_id, sqlserver.client_app_name, sqlserver.database_id)
    WHERE (sqlserver.database_id = 5)
)
ADD TARGET package0.event_file(SET filename = N'C:\XE\CaptureLocks.xel', max_file_size=(50), max_rollover_files=5)
WITH (MAX_MEMORY=4096 KB, EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS, MAX_DISPATCH_LATENCY=30 SECONDS, TRACK_CAUSALITY=ON);
GO

ALTER EVENT SESSION [CaptureLocks] ON SERVER STATE = START;
GO
```

**How to read the files**:

```sql
-- Read events from the XE file(s)
SELECT
    event_data.value('(event/@name)[1]', 'varchar(50)') AS event_name,
    event_data.value('(event/action[@name="session_id"]/value)[1]', 'int') AS session_id,
    event_data.value('(event/action[@name="client_app_name"]/value)[1]', 'varchar(200)') AS client_app,
    event_data.value('(event/action[@name="database_id"]/value)[1]', 'int') AS database_id,
    event_data.value('(event/data[@name="lock_mode"]/value)[1]', 'varchar(20)') AS lock_mode,
    event_data.value('(event/data[@name="resource_type"]/value)[1]', 'varchar(50)') AS resource_type,
    event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS sql_text,
    event_data.value('(event/@timestamp)[1]', 'datetime2') AS ts
FROM
(
  SELECT CAST(event_data AS XML) AS event_data
  FROM sys.fn_xe_file_target_read_file('C:\XE\CaptureLocks*.xel', NULL, NULL, NULL)
) x;
```

---

### Practical guidance and tradeoffs
- **Filter aggressively** (database_id, object_id, application name, or specific SPIDs) to avoid huge files and performance impact.  
- **Retention and storage**: XE files can grow quickly; set rollover and retention policies.  
- **Overhead**: `lock_acquired`/`lock_released` are high-frequency events on busy systems — consider sampling or capturing only `lock_acquired` with filters, or capture only when blocking exceeds a threshold (use `blocked_process_report` or custom logic).  
- **Deadlocks**: keep `system_health` and/or trace flag 1222 enabled to capture deadlock graphs (these show the locks involved in deadlocks without capturing every lock).  
- **Post-capture analysis**: correlate XE events with `sys.dm_exec_sessions`/`sys.dm_exec_requests` and application logs to identify root causes and offending SQL.

---

If you want, I can:
- provide a **filtered XE session** tuned for your database (tell me the database name or id and any app names to include/exclude), or  
- show a **script to parse existing `system_health` deadlock XML** and highlight the victim, owners, waiters, and captured SQL text.
