USE [1CDBAMonitoring]
GO

/****** Object:  Table [dbo].[ProdReplicationTablesList]    Script Date: 3/3/2026 2:31:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[QAUATReplicationTablesList](
	[SourceServer] [nvarchar](300) NULL,
	[Publication] [nvarchar](300) NULL,
	[Article] [nvarchar](300) NULL,
	[SourceSchema] [nvarchar](300) NULL,
	[Subscriber] [nvarchar](300) NULL,
	[DestinationDatabase] [nvarchar](300) NULL,
	[DestinationSchema] [nvarchar](300) NULL,
	[CaptureDate] [datetime] NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[QAUATReplicationTablesList] ADD  DEFAULT (getdate()) FOR [CaptureDate]
GO


