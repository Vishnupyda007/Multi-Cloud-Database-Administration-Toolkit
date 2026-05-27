select [message] 
from [msdb].[dbo].[sysjobhistory]
where step_name like 'db_name'
