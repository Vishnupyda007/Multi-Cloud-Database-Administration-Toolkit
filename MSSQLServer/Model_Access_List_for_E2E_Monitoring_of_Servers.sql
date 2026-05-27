use master
go
CREATE LOGIN [SQL_Login_Name] WITH PASSWORD=N'XXXXXXX', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
CREATE USER SQL_Login_Name FOR LOGIN SQL_Login_Name;
go
GRANT VIEW SERVER STATE TO SQL_Login_Name
go
grant select on master.sys.databases to SQL_Login_Name
go
grant select on master.dbo.sysperfinfo to SQL_Login_Name
go
grant select on master.sys.partitions to SQL_Login_Name
go
grant select on master.sys.allocation_units to SQL_Login_Name
go
grant select on master.sys.internal_tables to SQL_Login_Name
go
grant select on master.sys.filegroups to SQL_Login_Name
go
grant select on master.sys.database_files to SQL_Login_Name
go
GRANT SELECT ON master.dbo.sysprocesses TO SQL_Login_Name 
GO 
GRANT SELECT ON master.dbo.spt_values TO SQL_Login_Name 
GO 
GRANT SELECT ON master.dbo.sysfiles TO SQL_Login_Name 
GO 
GRANT SELECT ON master.dbo.sysindexes TO SQL_Login_Name 
GO 
GRANT SELECT ON master.dbo.sysperfinfo TO SQL_Login_Name 
GO 
GRANT SELECT ON master.dbo.sysobjects TO SQL_Login_Name 
GO 
GRANT SELECT ON master.dbo.syscurconfigs TO SQL_Login_Name 
GO 
USE [msdb]
GO
CREATE USER [SQL_Login_Name] FOR LOGIN [SQL_Login_Name]
GO
USE [msdb]
GO
ALTER USER [SQL_Login_Name] WITH DEFAULT_SCHEMA=[dbo]
GO
use msdb
go
grant select on msdb.dbo.sysjobsteps to SQL_Login_Name
go
grant select on msdb.dbo.sysjobs to SQL_Login_Name
go
Grant select on msdb.dbo.syscategories to SQL_Login_Name
go
Grant select on msdb.dbo.sysjobhistory to SQL_Login_Name
Go

use master; GRANT CONNECT  TO [SQL_Login_Name]
use master; GRANT ALTER ANY LINKED SERVER TO [SQL_Login_Name]
use master; GRANT ALTER ANY LOGIN TO [SQL_Login_Name]
use master; GRANT CONTROL SERVER TO [SQL_Login_Name]
use master; GRANT VIEW SERVER STATE TO [SQL_Login_Name]
use master; GRANT SELECT ON [dbo].[spt_values] TO [SQL_Login_Name]
use msdb; GRANT CONNECT  TO [SQL_Login_Name]
use msdb; GRANT SELECT ON [dbo].[sysjobhistory] TO [SQL_Login_Name]
use msdb; GRANT SELECT ON [dbo].[sysjobs] TO [SQL_Login_Name]
use msdb; GRANT SELECT ON [dbo].[sysjobsteps] TO [SQL_Login_Name]
use msdb; GRANT SELECT ON [dbo].[syscategories] TO [SQL_Login_Name]
 