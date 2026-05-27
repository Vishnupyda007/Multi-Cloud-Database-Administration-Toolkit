use msdb
go
select j.name as 'job name', SUSER_SNAME(owner_sid) as 'owner'
from dbo.sysjobs j
where SUSER_SNAME(owner_sid) = 'sa'
