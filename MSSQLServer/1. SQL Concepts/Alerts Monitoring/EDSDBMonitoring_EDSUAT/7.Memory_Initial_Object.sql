use [EDSMonitoring]
go

CREATE TABLE [dbo].[Memory_Percent](
	[EndTime] [Datetime] NOT NULL,
	[Avg_Memory_percent] [decimal] (18,2) NOT NULL)
	
CREATE TABLE [dbo].[What_is_Running_Memory](
	[Spid] [smallint] NOT NULL,
	[ecid] [smallint] NOT NULL,
	[Database] [nvarchar](128) NULL,
	[User] [nchar](128) NOT NULL,
	[Status] [nvarchar](30) NOT NULL,
	[Wait] [nvarchar](60) NULL,
	[Individual Query] [nvarchar](max) NULL,
	[Parent Query] [nvarchar](max) NULL,
	[Program] [nchar](128) NOT NULL,
	[Hostname] [nchar](128) NOT NULL,
	[nt_domain] [nchar](128) NOT NULL,
	[start_time] [datetime] NOT NULL,
	[Logical_Reads] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

create table dbo.whoisactive_Memory(
[dd hh:mm:ss.mss] varchar(1000)
,[start_time] datetime
,[session_id] int
,[sql_text] xml
,[status] varchar(50)
,[wait_info] varchar(500)
,[tempdb_allocations] varchar(100)
,[tempdb_current] varchar(100)
,[reads] varchar(100)
,[writes] varchar(100)
,[host_name] varchar(100)
,[database_name] varchar(100)
,[program_name]varchar(100)
)

/*
select * from Memory_PERCENT
select * from dbo.[What_is_Running_Memory] 
select * from dbo.whoisactive_Memory b 

select 
		 b.[dd hh:mm:ss.mss]
		,b.[start_time]
		,b.[session_id]
		,b.[sql_text]
		,a.[Parent Query]
		,b.[status]
		,case 
		WHEN (b.[wait_info] IS NULL) THEN '-'
		ELSE b.[wait_info]
		END AS wait_info
		,b.[reads]
		,b.[tempdb_allocations]
		,b.[tempdb_current]
		,b.[reads]
		,b.[writes]
		,b.[host_name]
		,b.[database_name]
		,b.[program_name]
from EDSMonitoring.dbo.[What_is_Running_Memory] a 
INNER JOIN EDSMonitoring.dbo.whoisactive_Memory b 
on a.spid=b.session_id 
and a.program=b.program_name and a.hostname=b.host_name and a.start_time=b.start_time
and a.[Database]=b.database_name 
where program NOT IN ('TdService')
*/

