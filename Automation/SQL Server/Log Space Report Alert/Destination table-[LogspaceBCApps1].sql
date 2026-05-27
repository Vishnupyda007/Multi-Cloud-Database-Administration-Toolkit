USE [master]
GO

/****** Object:  Table [dbo].[LogSpaceBCApps1]    Script Date: 6/20/2025 2:41:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LogspaceBCApps1](
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


