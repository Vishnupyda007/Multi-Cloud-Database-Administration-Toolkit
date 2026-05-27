SELECT 

    RIGHT('00' + CAST(r.total_elapsed_time / 86400000 AS VARCHAR), 2) + ' ' +  -- Days

    RIGHT('00' + CAST((r.total_elapsed_time % 86400000) / 3600000 AS VARCHAR), 2) + ':' +  -- Hours

    RIGHT('00' + CAST((r.total_elapsed_time % 3600000) / 60000 AS VARCHAR), 2) + ':' +  -- Minutes

    RIGHT('00' + CAST((r.total_elapsed_time % 60000) / 1000 AS VARCHAR), 2) + '.' +  -- Seconds

    RIGHT('000' + CAST(r.total_elapsed_time % 1000 AS VARCHAR), 3) AS [dd hh:mm:ss.mss],

    r.session_id,

	t.text AS sql_text,

    r.status,

    r.start_time,

    r.command,

	p.blocked,

	p.program_name,

	DB_NAME(r.database_id) AS database_name,

    r.cpu_time,

    r.total_elapsed_time,

    p.waittime,

    p.lastwaittype,

    p.hostname,

    p.loginame

FROM sys.dm_exec_requests r

CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t

JOIN sys.sysprocesses p ON r.session_id = p.spid

--WHERE r.session_id > 50 
order by [dd hh:mm:ss.mss] desc

  --AND r.status = 'running';
 