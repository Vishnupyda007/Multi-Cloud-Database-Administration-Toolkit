USE [DBAdmin]
GO

/****** Object:  Table [dbo].[MI_Prod_Servers_Tempdb_Usage_Queries]    Script Date: 2/26/2025 10:16:54 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MI_Prod_Servers_Tempdb_Usage_Queries](
	[Servername] [nvarchar](200) NOT NULL,
	[session_id] [int] NULL,
	[login_name] [nvarchar](128) NULL,
	[host_name] [nvarchar](128) NULL,
	[program_name] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[status] [nvarchar](30) NULL,
	[tempdb_alloc_mb] [int] NULL,
	[tempdb_current_mb] [int] NULL,
	[query_start_time] [datetime2](3) NULL,
	[query_runtime_seconds] [varchar](50) NULL
) ON [PRIMARY]
GO


