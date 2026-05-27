USE [master]
GO

/****** Object:  Table [dbo].[atLogspaceBCApps1]    Script Date: 6/20/2025 2:41:14 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[atLogspaceBCApps1](
	[DBName] [varchar](200) NULL,
	[logSize_MB] [numeric](20, 2) NULL,
	[UsedSpace_Per] [numeric](20, 2) NULL,
	[status] [int] NULL,
	[Instancename] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[atLogspaceBCApps1] ADD  DEFAULT (@@servername) FOR [Instancename]
GO


