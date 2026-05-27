--"Login failed" – but what application, process ID, and hostname?

-- a handy script that helps gather additional information about failed login attempts, beyond what's shown in the SQL Server error log (just IP and login name).

--The script uses the default trace and the sys.traces catalog view.
--It provides extra details about the failed login, including:
--- SPID
--- Application Name
--- Client Process ID
--- Hostname

--These details can be helpful for troubleshooting:
--- The application name can identify which app is using incorrect credentials.
--- The client process ID (PID) can be useful when the application name is generic, as it reveals the specific client-side process.

--Notes:
--Accessing sys.traces is itself recorded in the default trace, which may trigger alerts in your organization's security monitoring tools (if in place).
--The default trace consists of only 5 files of 20MB each, and is overwritten over time. If you need to retain this information long-term, consider storing it in a table via a scheduled process.

--Caveats:
--This script may fail in the following cases:
--- If the default trace file name contains more than one underscore (_) character.
--- If any trace file is corrupted or inaccessible.

--hashtag#mssql hashtag#mssqldba

--Script:

exec xp_readerrorlog 0,1,N'Login failed'

SELECT ft.StartTime
 ,te.name [Event]
 ,ft.SPID
 ,ft.LoginName
 ,ft.ApplicationName
 ,ft.ClientProcessID
 ,ft.Hostname
 ,ft.DatabaseName
 ,ft.Error
FROM sys.traces st
CROSS APPLY::fn_trace_gettable(left(st.path, len(st.path) - charindex('_', reverse(st.path))) + right(st.path, 4), st.max_files) ft
INNER JOIN sys.trace_events te ON ft.EventClass = te.trace_event_id
WHERE te.name = N'Audit Login Failed'
 AND st.is_default = 1
 AND st.STATUS = 1
ORDER BY ft.StartTime DESC;


--The image below shows a comparison between the error message in the SQL Server error log and the query output.