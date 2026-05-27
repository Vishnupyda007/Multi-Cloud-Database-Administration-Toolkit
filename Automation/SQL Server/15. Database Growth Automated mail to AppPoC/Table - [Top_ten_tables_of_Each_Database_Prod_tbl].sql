USE [1CDBAMonitoring]
GO

/****** Object:  Table [dbo].[Top_ten_tables_of_Each_Database_Prod_tbl]    Script Date: 7/21/2025 4:30:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Top_ten_tables_of_Each_Database_Prod_tbl](
	[ServerName] [nvarchar](128) NULL,
	[DatabaseName] [nvarchar](128) NULL,
	[TableName] [nvarchar](256) NULL,
	[TotalRows] [bigint] NULL,
	[TableSizeGB] [decimal](18, 2) NULL,
	[CaptureDate] [datetime] NULL
) ON [PRIMARY]
GO


