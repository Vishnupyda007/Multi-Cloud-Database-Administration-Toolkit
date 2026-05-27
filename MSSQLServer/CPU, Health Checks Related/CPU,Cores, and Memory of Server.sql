SELECT physical_memory_in_use_kb / 1024.0 AS sql_physical_memory_in_use_MB,
       large_page_allocations_kb / 1024 AS sql_large_page_allocations_MB,
       locked_page_allocations_kb / 1024 AS sql_locked_page_allocations_MB,
       virtual_address_space_reserved_kb / 1024 AS sql_VAS_reserved_MB,
       virtual_address_space_committed_kb / 1024 AS sql_VAS_committed_MB,
       virtual_address_space_available_kb / 1024 AS sql_VAS_available_MB,
       page_fault_count AS sql_page_fault_count,
       memory_utilization_percentage AS sql_memory_utilization_percentage,
       process_physical_memory_low AS sql_process_physical_memory_low,
       process_virtual_memory_low AS sql_process_virtual_memory_low
FROM sys.dm_os_process_memory;

-------------------------------------

select * from sys.dm_os_process_memory

------------------------------------

select distinct scheduler_id, cpu_id, status, is_online,* 
from sys.dm_os_schedulers 

------------------------------------

SET NOCOUNT ON

SELECT 'physical_cpu' = cpu_count / hyperthread_ratio
    ,'cores' = CASE 
        WHEN hyperthread_ratio = cpu_count
            THEN cpu_count
        ELSE (cpu_count / hyperthread_ratio) * ((cpu_count - hyperthread_ratio) / (cpu_count / hyperthread_ratio))
        END
    ,'logical_cpu' = CASE 
        WHEN hyperthread_ratio = cpu_count
            THEN cpu_count
        ELSE ((cpu_count - hyperthread_ratio) / (cpu_count / hyperthread_ratio))
        END
FROM master.sys.dm_os_sys_info


