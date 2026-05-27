DECLARE @memoryUsagePercent INT
SET @memoryUsagePercent = (SELECT (total_physical_memory_kb * 100 / available_physical_memory_kb)
                           FROM sys.dm_os_sys_memory);
 
IF @memoryUsagePercent > 80
BEGIN
    DECLARE @TopMemoryQuery NVARCHAR(MAX);
 
    SELECT TOP 1
        @TopMemoryQuery = 'Query: ' + SUBSTRING(text, 1, 2000) + ' | Memory Used (KB): ' + CAST(used_memory_kb AS NVARCHAR(10))
    FROM
        sys.dm_exec_query_memory_grants AS mg
    CROSS APPLY
        sys.dm_exec_sql_text(mg.sql_handle)
    WHERE
        mg.requested_memory_kb > 0
    ORDER BY
        mg.requested_memory_kb DESC;
 
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'CRS',  -- Replace with your Database Mail profile name
@recipients = 'sneha.s5@cognizant.com',  -- Replace with your email address
        @subject = 'SQL Server High Memory Usage Alert';
        --@body = CONCAT('Memory usage has spiked above 80%.', CHAR(10), 'Query consuming the most memory:', CHAR(10), @TopMemoryQuery);
END;