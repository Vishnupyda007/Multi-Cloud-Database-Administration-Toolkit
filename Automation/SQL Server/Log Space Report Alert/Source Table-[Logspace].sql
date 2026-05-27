USE [master]
GO

/****** Object:  Table [dbo].[Logspace]    Script Date: 6/17/2025 10:44:44 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Logspace](
	[DBName] [varchar](200) NULL,
	[OldSize] [numeric](20, 2) NULL,
	[CurSize_MB] [numeric](20, 2) NULL,
	[UsedSize] [numeric](20, 2) NULL,
	[GrowthTime] [datetime] NULL,
	[status] [int] NULL,
	[RecoveryModel] [nvarchar](100) NULL,
	[LogWait_Description] [nvarchar](100) NULL
) ON [PRIMARY]
GO


