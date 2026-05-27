USE [1CDBAMonitoring]
GO

/****** Object:  Table [dbo].[ApplicationInventory]    Script Date: 7/19/2025 1:22:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ApplicationInventory](
	[ServerName] [nvarchar](300) NULL,
	[DatabaseName] [nvarchar](300) NULL,
	[Environment] [nvarchar](100) NULL,
	[ServerType] [nvarchar](100) NULL,
	[ApplicationID] [bigint] NULL,
	[ApplicationName] [nvarchar](300) NULL,
	[CurrentCriticality] [nvarchar](100) NULL,
	[RevisedCriticality] [nvarchar](100) NULL,
	[AppPoC] [nvarchar](300) NULL,
	[SerialNumber] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
GO

