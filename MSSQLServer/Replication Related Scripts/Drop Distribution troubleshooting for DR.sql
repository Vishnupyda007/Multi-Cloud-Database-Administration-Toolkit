--remove subscriber force
--Even after dropping pubs,subs and distribution, still unable to configure distribution as system table in msdb still has distribution db mapping.


EXEC sp_dropsubscription 
  @publication = 'EDS_GSMS', 
  @article = N'all',
  @subscriber = '10.142.196.14',
  @ignore_distributor = 1

--remove publication force

EXEC sp_droppublication 
  @publication = 'EDS_GSMS', 
  @ignore_distributor = 1

--remove DB in publication

EXEC sp_removedbreplication 'OneC_GSMS'

--drop distibutor

EXEC sp_dropdistributor @no_checks = 1

--If error check this 

EXEC sp_dropdistributor
USE master
EXEC sp_dropdistributor @no_checks = 1 

select * from msdb.dbo.MSdistpublishers 
delete from msdb.dbo.MSdistpublishers where distribution_db='distribution'

-- Check jobs. If there is any existing jobs clear it. Then create distributor and run publisher scripts.


select * from distribution.dbo.MSreplservers

--begin tran 
update  distribution.dbo.MSreplservers set srvname='ctsazdrmibcpgn.inso1a101c37461fa.database.windows.net' where srvid=1
--commit tran

select @@SERVERNAME
--drop database distribution;


--select *  from distribution.dbo.MSreplservers ss

--select @@SERVERNAME

--begin tran 
--update  distribution.dbo.MSreplservers set srvname='ctsazdrmibcpst.inso1a101c37461fa.database.windows.net' where srvid=1

--commit tran



--IF any REplcmds issue.

--1. check DB owner 
--sp_changedbowner 'SA'

--2. Clear existing jobs.

















