USE [1CDBAMonitoring]
GO

/****** Object:  Table [dbo].[MI_Prod_Servers_Tempdb_Usage_Queries]    Script Date: 7/5/2025 5:25:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MI_Prod_Long_Running_Sessions_tbl](
	[Servername] [nvarchar](200) NOT NULL,
	[session_id] [int] NULL,
	blocking_session_id [int] NULL,
	[login_name] [nvarchar](128) NULL,
	[host_name] [nvarchar](128) NULL,
	[program_name] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[status] [nvarchar](200) NULL,
	command [nvarchar](128) NULL,
	reads [bigint] null,
	writes [bigint] null,
	logical_reads [bigint] null,
	[query_start_time] [datetime2](3) NULL,
	[query_runtime_ddhhmmss] [varchar](50) NULL,
	cpu_time_seconds [int] NULL,
	query_text [nvarchar](max) null
) ON [PRIMARY]
GO



