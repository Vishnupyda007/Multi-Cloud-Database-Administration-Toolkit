/* Recent DROP LOGIN events from the default trace */
DECLARE @tracepath NVARCHAR(4000);
SELECT TOP (1) @tracepath = path
FROM sys.traces
WHERE is_default = 1;

-- 46/47 in many docs are Object create/delete; for logins, use the audit event:
-- Audit Server Principal Management (event class varies by version)
SELECT 
    TE.name               AS EventName,        -- e.g., 'Audit Server Principal Management'
    T.LoginName,                              -- who performed it
    T.TargetLoginName,                        -- which login was affected
    T.StartTime, 
    T.TextData
FROM sys.fn_trace_gettable(@tracepath, DEFAULT) AS T
JOIN sys.trace_events AS TE
  ON T.EventClass = TE.trace_event_id
WHERE TE.name IN ('Audit Server Principal Management', 'Audit Addlogin Event')
  AND T.EventSubClass = 2   -- 2 = DROP LOGIN (subclass value for removal)
  AND T.StartTime >= DATEADD(DAY, -7, GETDATE())
ORDER BY T.StartTime DESC;