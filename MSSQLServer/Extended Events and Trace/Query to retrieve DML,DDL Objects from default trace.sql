---it will have recent history only

SELECT 
    TE.name AS EventType,
    DT.DatabaseName,
    DT.ObjectName,
    DT.ObjectType,
    DT.TextData AS SqlCommand,
    DT.LoginName,
    DT.NTUserName AS UserName,
    DT.HostName,
    DT.ApplicationName,
    DT.StartTime AS EventDate
FROM fn_trace_gettable(
    CONVERT(VARCHAR(255), (SELECT value FROM sys.fn_trace_getinfo(NULL) WHERE property = 2)), DEFAULT
) AS DT
JOIN sys.trace_events AS TE ON DT.EventClass = TE.trace_event_id 
WHERE DT.StartTime >= DATEADD(MINUTE, -120, GETDATE()) --and DT.DatabaseName='test'
--WHERE TE.name IN ('Create Object', 'Alter Object', 'Drop Object')
ORDER BY DT.StartTime DESC;
