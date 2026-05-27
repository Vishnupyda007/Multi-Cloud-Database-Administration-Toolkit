USE [master]
GO

/****** Object:  Table [dbo].[atLogspace]    Script Date: 6/17/2025 10:44:35 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[atLogspace](
	[DBName] [varchar](200) NULL,
	[logSize_MB] [numeric](20, 2) NULL,
	[UsedSpace_Per] [numeric](20, 2) NULL,
	[status] [int] NULL,
	[Instancename] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[atLogspace] ADD  DEFAULT (@@servername) FOR [Instancename]
GO


