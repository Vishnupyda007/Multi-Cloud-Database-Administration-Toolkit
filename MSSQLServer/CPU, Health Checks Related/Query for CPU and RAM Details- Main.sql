------Query for CPU details
SELECT
    cpu_count AS 'Logical CPUs',
    hyperthread_ratio AS 'Hyperthread Ratio',
    physical_memory_kb / 1024.0 /1024.0 AS 'Physical Memory (GB)',
    sqlserver_start_time AS 'SQL Server Start Time'
FROM
    sys.dm_os_sys_info;

------Query for RAM details
	SELECT
    total_physical_memory_kb / 1024.0 / 1024.0 AS [Total RAM (GB)],
    available_physical_memory_kb / 1024.0 / 1024.0 AS [Available RAM (GB)]
FROM
    sys.dm_os_sys_memory;



-----for MI Servers, calculate memory as 5.1GB of ram per a vCore

In SQL MI, you're working in a Platform-as-a-Service (PaaS) environment, where the underlying infrastructure and physical resources are abstracted. The sys.dm_os_sys_memory and sys.dm_os_sys_info views provide details about the allocated memory and CPUs for your instance—not the physical host machine.
it reports the allocated resources for your instance based on its service tier (General Purpose or Business Critical) and vCores.