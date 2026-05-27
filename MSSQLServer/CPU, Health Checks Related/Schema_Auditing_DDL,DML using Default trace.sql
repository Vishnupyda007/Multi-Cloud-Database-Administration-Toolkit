--The script uses the default trace, which is enabled and running by default and contains a lot of useful information.

--The default trace logs data into 5 files of 20 MB each, rotating over time.
--So, if you need this type of audit on a permanent basis, consider either configuring a dedicated auditing process or regularly saving the collected trace data to a table.

--https://learn.microsoft.com/en-us/sql/relational-databases/event-classes/objecttype-trace-event-column?view=sql-server-ver17

--Note:
--Accessing sys.traces is logged in the default trace itself.
--If your company uses security monitoring tools, this access might trigger alerts. Keep that in mind!
--To check if the default trace is enabled and running:

IF EXISTS (SELECT 1 FROM sys.traces WHERE is_default = 1 AND status = 1)
 PRINT 'Default trace is enabled and running.'
ELSE
 PRINT 'Default trace is disabled or stopped.'

-------------------------------

WITH otype (id, typename)
AS (
    SELECT 16964, 'Database' UNION ALL
    SELECT 8277, 'Table' UNION ALL
    SELECT 8278, 'View' UNION ALL
    SELECT 22601, 'Index' UNION ALL
    SELECT 21587, 'Statistics'
    /*
     more types here:
     https://lnkd.in/e4hQhyNt
     */
)
SELECT DISTINCT
    ft.StartTime,
    ft.SPID,
    ft.LoginName,
    ft.ApplicationName,
    ft.ClientProcessID,
    ft.Hostname,
    te.name AS [Event],
    -- ### CHANGE HERE: Translate DatabaseID to the friendly name ###
    DB_NAME(ft.DatabaseID) AS [DatabaseName],
    ISNULL(ft.ObjectName, N'--->') AS [ObjectName],
    ISNULL(o.typename, CONVERT(VARCHAR(10), ft.ObjectType)) AS [ObjectType]
FROM
    sys.traces st
CROSS APPLY
    ::fn_trace_gettable(LEFT(st.path, LEN(st.path) - CHARINDEX('_', REVERSE(st.path))) + RIGHT(st.path, 4), st.max_files) ft
INNER JOIN
    sys.trace_events te ON ft.EventClass = te.trace_event_id
LEFT JOIN
    otype o ON o.id = ft.ObjectType
WHERE
    te.name LIKE 'Object%'
    -- ### CHANGE HERE: Filter using the friendly name ###
    AND DB_NAME(ft.DatabaseID) != 'tempdb'
    AND st.is_default = 1
    AND st.status = 1
ORDER BY
    ft.StartTime DESC;


--The Cause: Azure SQL Database Internals
--In the Azure SQL Database platform, the database you create has a user-friendly "logical" name (e.g., MyWebAppDB). However, internally, to ensure global uniqueness and manage the database across Microsoft's massive infrastructure, Azure assigns it a unique physical name, which is the GUID (Globally Unique Identifier) you are seeing (e.g., e918aa60-780a-4cd8-94e6-b1ee3f5542ec).

--The SQL Server Default Trace, which you are querying with fn_trace_gettable, captures events at a low level. In the Azure environment, it often records the internal physical name (the GUID) instead of the logical name you are familiar with.

--The Solution: Using DB_NAME()
--The solution is straightforward. The trace data also includes the DatabaseID. You can use the built-in DB_NAME() function to translate this DatabaseID back into its current, user-friendly logical name.

----for below query
--The Root Cause: DB_NAME() Returns NULL
--Trace Captures the Event: When you execute DROP DATABASE MyTestDB, the Default Trace correctly captures this event. At that exact moment, it records the DatabaseID that MyTestDB used to have (e.g., ID 8).

--Query Runs Later: Your query runs after the database has been dropped.

--The DB_NAME() Function Fails: When your query processes the row for the "Drop Database" event, it takes the recorded DatabaseID (e.g., 8) and passes it to the DB_NAME(8) function. Since the database with ID 8 no longer exists, DB_NAME() returns NULL.

--The WHERE Clause Filters the Row: Your WHERE clause contains the condition AND DB_NAME(ft.DatabaseID) != 'tempdb'. When DB_NAME() returns NULL, this condition becomes AND NULL != 'tempdb'. In SQL, a comparison to NULL results in UNKNOWN, which is not TRUE. Therefore, the WHERE clause discards the row for the dropped database event.

--The Solution: Handle the NULL
--The fix is to wrap the DB_NAME() function in ISNULL() or COALESCE(). This allows you to handle the NULL case for dropped databases and ensure the row is not accidentally filtered out.

--Here is the corrected script. The only change is in the WHERE clause.


--------------or More Precise----------

WITH otype (id, typename)
AS (
    SELECT 16964, 'Database' UNION ALL
    SELECT 8277, 'Table' UNION ALL
    SELECT 8278, 'View' UNION ALL
    SELECT 22601, 'Index' UNION ALL
    SELECT 21587, 'Statistics' UNION ALL
    SELECT 8272, 'Stored Procedure'
)
SELECT DISTINCT
    ft.StartTime,
    ft.SPID,
    ft.LoginName,
    ft.ApplicationName,
    ft.ClientProcessID,
    ft.Hostname,
    te.name AS [Event],
    -- For a dropped DB, this will now correctly show NULL
    DB_NAME(ft.DatabaseID) AS [DatabaseName],
    ISNULL(ft.ObjectName, N'--->') AS [ObjectName],
    ISNULL(o.typename, CONVERT(VARCHAR(10), ft.ObjectType)) AS [ObjectType],
    CAST(ft.TextData AS nvarchar(max)) AS TextData
FROM
    sys.traces st
CROSS APPLY
    ::fn_trace_gettable(LEFT(st.path, LEN(st.path) - CHARINDEX('_', REVERSE(st.path))) + RIGHT(st.path, 4), st.max_files) ft
INNER JOIN
    sys.trace_events te ON ft.EventClass = te.trace_event_id
LEFT JOIN
    otype o ON o.id = ft.ObjectType
WHERE
    te.name IN (
        'Object:Created',
        'Object:Altered',
        'Object:Deleted',
        'Databases:Create Database',
        'Databases:Drop Database',
        'RPC:Completed',
        'SQL:StmtCompleted'
    )
    -- ### FIX HERE: Wrap DB_NAME in a function to handle NULLs ###
    AND ISNULL(DB_NAME(ft.DatabaseID), '') != 'tempdb'
    AND st.is_default = 1
    AND st.status = 1
ORDER BY
    ft.StartTime DESC;

