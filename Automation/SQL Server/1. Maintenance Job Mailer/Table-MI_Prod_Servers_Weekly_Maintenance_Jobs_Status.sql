USE [DBAdmin]
GO

/****** Object:  Table [dbo].[MI_Prod_Servers_Weekly_Maintenance_Jobs_Status]    Script Date: 11/12/2024 11:49:02 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MI_Prod_Servers_Weekly_Maintenance_Jobs_Status](
	[Servername] [nvarchar](200) NULL,
	[JobName] [nvarchar](200) NULL,
	[LastRun_StartTime] [datetime] NOT NULL,
	[LastRun_EndTime] [datetime] NOT NULL,
	[Job_Enable_Status] [char](100) NOT NULL,
	[Job_LastRun_Status] [char](100) NOT NULL,
	[Next_Run_Date] [date] NOT NULL
) ON [PRIMARY]
GO


