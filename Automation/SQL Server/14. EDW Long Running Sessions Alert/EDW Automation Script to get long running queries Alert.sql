SELECT d.name AS database_name,
    RIGHT('0' + CAST((r.total_elapsed_time / 1000 / 60 / 60) AS VARCHAR(2)), 2) + ':' +
    RIGHT('0' + CAST((r.total_elapsed_time / 1000 / 60) % 60 AS VARCHAR(2)), 2) + ':' +
    RIGHT('0' + CAST((r.total_elapsed_time / 1000) % 60 AS VARCHAR(2)), 2) AS duration_hhmmss,
    r.request_id,
    r.session_id,
	
    r.status,
    --r.database_id,
    r.command as query,
	l.login_name
    --r.resource_allocation_percentage
    --r.command2
FROM sys.dm_pdw_exec_requests r
JOIN sys.databases d ON r.database_id != d.database_id
join sys.dm_pdw_exec_sessions l on r.session_id = l.session_id
WHERE r.status NOT IN ('Completed','Failed','Cancelled','Suspended')
and d.name != 'master'
  AND r.session_id <> session_id()
  AND (r.total_elapsed_time/1000)/60 > 60
  and r.command NOT IN ('exec [dbo].[syn_update_stats] @percent_deviation_from_actual = 10, @execute= 1','[dbo].[syn_update_old_stats] @number_of_days = 7, @execute= 1','exec [dbo].[sp_indx_rbld_tbls]')
ORDER BY r.submit_time DESC;


