use master
go
CREATE LOGIN [db_monitoring_bot] WITH PASSWORD=N'dbmon@2025@#', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
CREATE USER db_monitoring_bot FOR LOGIN db_monitoring_bot;
go
GRANT VIEW SERVER STATE TO db_monitoring_bot
go
grant select on master.sys.databases to db_monitoring_bot
go
grant select on master.dbo.sysperfinfo to db_monitoring_bot
go
grant select on master.sys.partitions to db_monitoring_bot
go
grant select on master.sys.allocation_units to db_monitoring_bot
go
grant select on master.sys.internal_tables to db_monitoring_bot
go
grant select on master.sys.filegroups to db_monitoring_bot
go
grant select on master.sys.database_files to db_monitoring_bot
go
GRANT SELECT ON master.dbo.sysprocesses TO db_monitoring_bot 
GO 
GRANT SELECT ON master.dbo.spt_values TO db_monitoring_bot 
GO 
GRANT SELECT ON master.dbo.sysfiles TO db_monitoring_bot 
GO 
GRANT SELECT ON master.dbo.sysindexes TO db_monitoring_bot 
GO 
GRANT SELECT ON master.dbo.sysperfinfo TO db_monitoring_bot 
GO 
GRANT SELECT ON master.dbo.sysobjects TO db_monitoring_bot 
GO 
GRANT SELECT ON master.dbo.syscurconfigs TO db_monitoring_bot 
GO 
USE [msdb]
GO
CREATE USER [db_monitoring_bot] FOR LOGIN [db_monitoring_bot]
GO
USE [msdb]
GO
ALTER USER [db_monitoring_bot] WITH DEFAULT_SCHEMA=[dbo]
GO
use msdb
go
grant select on msdb.dbo.sysjobsteps to db_monitoring_bot
go
grant select on msdb.dbo.sysjobs to db_monitoring_bot
go
Grant select on msdb.dbo.syscategories to db_monitoring_bot
go
Grant select on msdb.dbo.sysjobhistory to db_monitoring_bot
Go

use master; GRANT CONNECT  TO [db_monitoring_bot]
use master; GRANT ALTER ANY LINKED SERVER TO [db_monitoring_bot]
use master; GRANT ALTER ANY LOGIN TO [db_monitoring_bot]
use master; GRANT CONTROL SERVER TO [db_monitoring_bot]
use master; GRANT VIEW SERVER STATE TO [db_monitoring_bot]
use master; GRANT SELECT ON [dbo].[spt_values] TO [db_monitoring_bot]
use msdb; GRANT CONNECT  TO [db_monitoring_bot]
use msdb; GRANT SELECT ON [dbo].[sysjobhistory] TO [db_monitoring_bot]
use msdb; GRANT SELECT ON [dbo].[sysjobs] TO [db_monitoring_bot]
use msdb; GRANT SELECT ON [dbo].[sysjobsteps] TO [db_monitoring_bot]
use msdb; GRANT SELECT ON [dbo].[syscategories] TO [db_monitoring_bot]
 

--sp_helplogins 'db_monitoring_bot'