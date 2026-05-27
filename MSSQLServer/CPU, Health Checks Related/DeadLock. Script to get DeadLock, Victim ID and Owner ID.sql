-- 1. Extract latest deadlock XML into a temp table
;WITH xe AS (
  SELECT CAST(target_data AS XML) AS target_data
  FROM sys.dm_xe_session_targets t
  JOIN sys.dm_xe_sessions s ON t.event_session_address = s.address
  WHERE s.name = 'system_health' AND t.target_name = 'ring_buffer'
)
SELECT TOP (1)
  CAST(x.value('(event/data/value/deadlock)[1]', 'nvarchar(max)') AS xml) AS deadlock_xml
INTO #deadlock_xml
FROM xe
CROSS APPLY target_data.nodes('//RingBufferTarget/event') AS T(x)
WHERE x.value('@name', 'varchar(50)') = 'xml_deadlock_report';

-- 2. Extract victim SPID
SELECT deadlock_xml.value('(/deadlock/victim-list/victim/@id)[1]', 'int') AS victim_spid
INTO #victim
FROM #deadlock_xml;

-- 3. Extract processes from the deadlock XML (use a safe alias name)
SELECT
  pnode.value('@id', 'int') AS spid,
  pnode.value('@hostname', 'varchar(128)') AS host_name,
  pnode.value('@loginname', 'varchar(128)') AS login_name_xml,
  pnode.value('@program', 'varchar(256)') AS program,
  pnode.value('(inputbuf)[1]', 'nvarchar(max)') AS inputbuf
INTO #dl_processes
FROM #deadlock_xml
CROSS APPLY deadlock_xml.nodes('/deadlock/process-list/process') AS P(pnode);

-- 4. Correlate to DMVs to get current login and current statement (if still present)
SELECT
  p.spid,
  ISNULL(s.login_name, p.login_name_xml) AS login_name,
  ISNULL(s.host_name, p.host_name) AS host_name,
  ISNULL(s.program_name, p.program) AS program_name,
  p.inputbuf AS captured_inputbuf,
  SUBSTRING(t.text,
            (r.statement_start_offset/2)+1,
            (CASE WHEN r.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), t.text))*2
                  ELSE r.statement_end_offset END - r.statement_start_offset)/2 + 1) AS current_statement,
  CASE WHEN v.victim_spid = p.spid THEN 1 ELSE 0 END AS is_victim
FROM #dl_processes p
LEFT JOIN sys.dm_exec_sessions s ON s.session_id = p.spid
LEFT JOIN sys.dm_exec_requests r ON r.session_id = p.spid
OUTER APPLY (SELECT text FROM sys.dm_exec_sql_text(r.sql_handle)) t
CROSS JOIN #victim v
ORDER BY is_victim DESC, p.spid;

-- 5. Show resource ownership/wait edges to help identify the root/causing session
SELECT
  R.res.value('local-name(.)', 'varchar(50)') AS resource_type,
  R.res.value('@lockMode', 'varchar(20)') AS lock_mode,
  R.res.value('@owner', 'int') AS owner_spid,
  R.res.value('@waiter', 'int') AS waiter_spid,
  R.res.value('@id', 'varchar(200)') AS resource_id
FROM #deadlock_xml X
CROSS APPLY X.deadlock_xml.nodes('/deadlock/resource-list/*') AS R(res)
ORDER BY owner_spid, waiter_spid;

-- Cleanup temp tables if desired
DROP TABLE #deadlock_xml;
DROP TABLE #dl_processes;
DROP TABLE #victim;