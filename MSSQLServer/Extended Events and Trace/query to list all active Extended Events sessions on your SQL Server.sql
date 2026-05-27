SELECT 
  *
FROM sys.dm_xe_sessions s
JOIN sys.dm_xe_session_events e ON s.address = e.event_session_address
ORDER BY s.name;
