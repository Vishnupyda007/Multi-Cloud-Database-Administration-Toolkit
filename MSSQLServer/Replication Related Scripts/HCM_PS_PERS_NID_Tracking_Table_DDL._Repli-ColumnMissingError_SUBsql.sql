
CREATE TABLE [dbo].[HCM_PS_PERS_NID_STG_CURR_Tracking](
	[TrackingID] [int] IDENTITY(1,1) NOT NULL,
	[OperationType] [varchar](10) NULL,
	[ChangedData] [nvarchar](max) NULL,
	[PreviousData] [nvarchar](max) NULL,
	[ExecutedBy] [sysname] NOT NULL,
	[ApplicationName] [nvarchar](128) NULL,
	[HostName] [nvarchar](128) NULL,
	[ChangeTime] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[TrackingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[HCM_PS_PERS_NID_STG_CURR_Tracking] ADD  DEFAULT (getdate()) FOR [ChangeTime]
GO


