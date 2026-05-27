SELECT
    @@Servername as ServerName,
    r.session_id,
	r.blocking_session_id,
    r.status,
    r.start_time as Query_Start_time,
	 -- Convert seconds to DD:HH:MM:SS format
    CONVERT(VARCHAR, DATEDIFF(SECOND, r.start_time, GETDATE()) / 86400) + ':' +
    RIGHT('0' + CONVERT(VARCHAR, (DATEDIFF(SECOND, r.start_time, GETDATE()) % 86400) / 3600), 2) + ':' +
    RIGHT('0' + CONVERT(VARCHAR, (DATEDIFF(SECOND, r.start_time, GETDATE()) % 3600) / 60), 2) + ':' +
    RIGHT('0' + CONVERT(VARCHAR, DATEDIFF(SECOND, r.start_time, GETDATE()) % 60), 2) AS [DD HH:MM:SS],
	--r.total_elapsed_time / 1000 AS total_elapsed_seconds, -- converting to seconds
    r.command,
    r.cpu_time/1000 as cpu_time_seconds,
    r.reads,
    r.writes,
    r.logical_reads,
    s.login_name,
	db.name as Database_name,
    s.host_name,
    s.program_name,
    t.text AS query_text
    --qp.query_plan
FROM sys.dm_exec_requests AS r with(nolock)
INNER JOIN sys.dm_exec_sessions AS s with(nolock) ON r.session_id = s.session_id
Inner join sys.sysdatabases as db with(nolock) ON db.dbid=r.database_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
--CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp
--WHERE DATEDIFF(MINUTE, r.start_time, GETDATE()) > 10 and 
--where datediff(hour, r.start-time,getdate()) > 2
where s.login_name !='NT AUTHORITY\SYSTEM'
ORDER BY r.total_elapsed_time DESC;