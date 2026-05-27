
DECLARE @path NVARCHAR(256)

SELECT @path = CONVERT(VARCHAR(256), value)
FROM sys.fn_trace_getinfo(NULL)
WHERE property = 2

SELECT 
    TE.name AS EventName,
    T.DatabaseName,
    T.ObjectName,
    T.TextData,
    T.StartTime,
    T.LoginName,
    T.ApplicationName
FROM fn_trace_gettable(@path, DEFAULT) T
JOIN sys.trace_events TE ON T.EventClass = TE.trace_event_id
WHERE TE.name = 'Object:Deleted'
AND T.ObjectType = 8277  -- Table
AND T.StartTime >= DATEADD(DAY, -7, GETDATE())
ORDER BY T.StartTime DESC
