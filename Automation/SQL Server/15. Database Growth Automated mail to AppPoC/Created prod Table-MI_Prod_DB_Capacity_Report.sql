USE [1CDBAMonitoring]
GO

/****** Object:  Table [dbo].[MI_Prod_DB_Capacity_Report]    Script Date: 5/27/2025 2:18:52 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MI_Prod_DB_Capacity_Report](
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[Name] [nvarchar](128) NULL,
	[FileId] [int] NULL,
	[PhysicalName] [nvarchar](260) NULL,
	[TotalSizeGB] [nvarchar](50) NULL,
	[AvailableSpaceGB] [nvarchar](50) NULL,
	[UsedSpaceGB] [nvarchar](50) NULL,
	[PercentageUsed] [nvarchar](50) NULL,
	[TotalDatabaseSizeGB] [nvarchar](50) NULL,
	[PercentageOfTotalGBUsed] [nvarchar](10) NULL,
	[TotalDataFileSizeGB] [nvarchar](50) NULL,
	[TotalLogFileSizeGB] [nvarchar](50) NULL,
	[Datetime] [datetime] NULL
) ON [PRIMARY]
GO


