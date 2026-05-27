SELECT 
    TE.name AS EventName,
    T.DatabaseName,
    T.ObjectName,
    T.ObjectType,
    T.StartTime,
    T.LoginName,
    T.HostName,
    T.ApplicationName
FROM fn_trace_gettable(
        CONVERT(NVARCHAR(256), 
            (SELECT TOP 1 value 
             FROM sys.fn_trace_getinfo(NULL) 
             WHERE property = 2)
        ), DEFAULT) T
JOIN sys.trace_events TE ON T.EventClass = TE.trace_event_id
WHERE TE.name = 'Object:Deleted'
  AND T.StartTime >= DATEADD(DAY, -7, GETDATE()) -- Change -7 to desired number of days
ORDER BY T.StartTime DESC;


--object_type-8277:Table,8275-Stored Procedure,8276-View,8272-Function,8273-Trigger,8274-Index,8278-Synonym,8280-Sequence,208-User Table (older trace),56-Stored Procedure (older trace)
