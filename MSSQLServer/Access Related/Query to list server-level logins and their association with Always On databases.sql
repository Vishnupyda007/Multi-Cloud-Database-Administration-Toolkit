-- Query to list server-level logins and their association with Always On databases
SELECT
sp.name AS LoginName,
    sp.type_desc AS LoginType,
    sp.is_disabled AS IsDisabled,
    CASE
        WHEN ag.database_id IS NOT NULL THEN 'Always On'
        ELSE 'Not Always On'
    END AS AvailabilityStatus,
d.name AS DatabaseName
FROM
    sys.server_principals sp
LEFT JOIN
    sys.database_principals dp
    ON sp.sid = dp.sid
LEFT JOIN
    sys.databases d
    ON dp.principal_id IS NOT NULL AND d.database_id = dp.principal_id
LEFT JOIN
    sys.dm_hadr_database_replica_states ag
    ON d.database_id = ag.database_id
WHERE
    sp.type IN ('S', 'U','X','E','G','C','R')  -- 'S' for SQL logins, 'U' for Windows logins
    AND d.database_id IS NOT NULL  -- Ensure mapping to databases
ORDER BY
sp.name, AvailabilityStatus;

--select distinct type from sys.server_principals