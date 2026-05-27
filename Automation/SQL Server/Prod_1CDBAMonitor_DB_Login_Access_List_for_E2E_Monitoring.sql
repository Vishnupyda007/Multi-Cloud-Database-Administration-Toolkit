use master
go
CREATE LOGIN [1CDBAMonitor] WITH PASSWORD=N'1cdbmon@2025#', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
CREATE USER [1CDBAMonitor] FOR LOGIN [1CDBAMonitor];
go
GRANT VIEW SERVER STATE TO [1CDBAMonitor]
go
grant select on master.sys.databases to [1CDBAMonitor]
go
grant select on master.dbo.sysperfinfo to [1CDBAMonitor]
go
grant select on master.sys.partitions to [1CDBAMonitor]
go
grant select on master.sys.allocation_units to [1CDBAMonitor]
go
grant select on master.sys.internal_tables to [1CDBAMonitor]
go
grant select on master.sys.filegroups to [1CDBAMonitor]
go
grant select on master.sys.database_files to [1CDBAMonitor]
go
GRANT SELECT ON master.dbo.sysprocesses TO [1CDBAMonitor] 
GO 
GRANT SELECT ON master.dbo.spt_values TO [1CDBAMonitor] 
GO 
GRANT SELECT ON master.dbo.sysfiles TO [1CDBAMonitor] 
GO 
GRANT SELECT ON master.dbo.sysindexes TO [1CDBAMonitor] 
GO 
GRANT SELECT ON master.dbo.sysperfinfo TO [1CDBAMonitor] 
GO 
GRANT SELECT ON master.dbo.sysobjects TO [1CDBAMonitor] 
GO 
GRANT SELECT ON master.dbo.syscurconfigs TO [1CDBAMonitor] 
GO 
USE [msdb]
GO
CREATE USER [1CDBAMonitor] FOR LOGIN [1CDBAMonitor]
GO
USE [msdb]
GO
ALTER USER [1CDBAMonitor] WITH DEFAULT_SCHEMA=[dbo]
GO
use msdb
go
grant select on msdb.dbo.sysjobsteps to [1CDBAMonitor]
go
grant select on msdb.dbo.sysjobs to [1CDBAMonitor]
go
Grant select on msdb.dbo.syscategories to [1CDBAMonitor]
go
Grant select on msdb.dbo.sysjobhistory to [1CDBAMonitor]
Go

use master; GRANT CONNECT  TO [1CDBAMonitor]
use master; GRANT ALTER ANY LINKED SERVER TO [1CDBAMonitor]
use master; GRANT ALTER ANY LOGIN TO [1CDBAMonitor]
use master; GRANT CONTROL SERVER TO [1CDBAMonitor]
use master; GRANT VIEW SERVER STATE TO [1CDBAMonitor]
use master; GRANT SELECT ON [dbo].[spt_values] TO [1CDBAMonitor]
use msdb; GRANT CONNECT  TO [1CDBAMonitor]
use msdb; GRANT SELECT ON [dbo].[sysjobhistory] TO [1CDBAMonitor]
use msdb; GRANT SELECT ON [dbo].[sysjobs] TO [1CDBAMonitor]
use msdb; GRANT SELECT ON [dbo].[sysjobsteps] TO [1CDBAMonitor]
use msdb; GRANT SELECT ON [dbo].[syscategories] TO [1CDBAMonitor]
 

