create database EDSMonitoring
go
USE EDSMonitoring
CREATE TABLE [dbo].[EDS_Log_Usage](
	[MI] [nvarchar](128) NULL,	
	[DatabaseName] [varchar] (128) NULL,
	[Log_Size_in_MB] [decimal](18,2) NULL,
	[Log_Space_Used_%] [decimal](18,2) NULL,
	[Status] [int] NULL,
	Log_reuse_wait_desc [varchar](255),
	[Table_Status] [int] NULL,
	Date_Collection datetime
) ON [PRIMARY]
GO

--select * from [EDS_Log_Usage] order by Date_Collection desc