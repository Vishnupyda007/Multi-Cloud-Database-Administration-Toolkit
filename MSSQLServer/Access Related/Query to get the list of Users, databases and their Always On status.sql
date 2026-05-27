---- Enable advanced options
--EXEC sp_configure 'show advanced options', 1;
--RECONFIGURE;
 
---- Enable the Always On feature
--EXEC sp_configure 'availability groups', 1;
--RECONFIGURE;
 
-- Query to get the list of databases and their Always On status
SELECT
d.name AS DatabaseName,
    CASE
        WHEN ag.database_id IS NOT NULL THEN 'Always On'
        ELSE 'Not Always On'
    END AS AvailabilityStatus,
sp.name AS UserName,
    sp.type_desc AS UserType
FROM
    sys.databases d
LEFT JOIN
    sys.dm_hadr_database_replica_states ag
ON
    d.database_id = ag.database_id
CROSS APPLY
    (SELECT name, type_desc FROM sys.database_principals WHERE type IN ('S', 'U','X','E','G')) sp
WHERE
    d.state_desc = 'ONLINE'  -- Only online databases
    AND d.database_id > 4;   -- Exclude system databases (master, model, msdb, tempdb)
