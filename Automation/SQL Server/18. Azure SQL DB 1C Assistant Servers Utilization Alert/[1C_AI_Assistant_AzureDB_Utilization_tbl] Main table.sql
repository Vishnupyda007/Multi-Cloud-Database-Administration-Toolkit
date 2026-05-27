USE [1CDBAMonitoring]
GO

/****** Object:  Table [dbo].[1C_AI_Assistant_AzureDB_Utilization_tbl]    Script Date: 12/27/2025 7:19:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[1C_AI_Assistant_AzureDB_Utilization_tbl](
	[ServerName] [nvarchar](250) NULL,
	[avg_cpu_percent] [decimal](5, 2) NULL,
	[avg_log_write_percent] [decimal](5, 2) NULL,
	[avg_memory_usage_percent] [decimal](5, 2) NULL,
	[max_worker_percent] [decimal](5, 2) NULL,
	[avg_instance_cpu_percent] [decimal](5, 2) NULL,
	[avg_instance_memory_percent] [decimal](5, 2) NULL,
	AllocatedDataGB [decimal](10, 2) NULL,
	UsedDataGB [decimal](10, 2) NULL,
	AllocatedLogGB [decimal](10, 2) NULL,
	UsedLogGB [decimal](10, 2) NULL,
	TotalAllocatedGB [decimal](10, 2) NULL,
	TotalUsedGB [decimal](10, 2) NULL,
	FreeInsideFilesGB [decimal](10, 2) NULL,
	DatabaseMaxDataSizeGB [decimal](10, 2) NULL,
	FreeToMaxGB [decimal](10, 2) NULL,
	FreeInsideFilesPct [decimal](10, 2) NULL,
	FreeToMaxPct [decimal](10, 2) NULL,
	DataUsedPctOfMax [decimal](10, 2) NULL,
	LogUsedPctOfAllocated [decimal](10, 2) NULL,
	[Captured_time] [datetime] NULL
) ON [PRIMARY]
GO


