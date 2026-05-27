-- Active and offline databases in server
SELECT name, state_desc
FROM sys.databases
WHERE state_desc in ('ONLINE','OFFLINE')
ORDER BY state_desc DESC;
 
---- Offline databases
--SELECT name, state_desc
--FROM sys.databases
--WHERE state_desc = 'OFFLINE';