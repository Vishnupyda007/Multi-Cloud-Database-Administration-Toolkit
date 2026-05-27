

/****** Object:  Table [dbo].[PAAS_DR_Replication_Error_Alert_Mail]    Script Date: 2/15/2025 8:11:02 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PAAS_DR_Replication_Error_Alert_Mail](
	[publisher] [nvarchar](200) NOT NULL,
	[publisher_db] [nvarchar](200) NOT NULL,
	[publication] [nvarchar](400) NULL,
	[alert_error_text] [nvarchar](max) NOT NULL,
	[alert_error_code] [nvarchar](200) NOT NULL,
	[article] [nvarchar](400) NULL,
	[subscriber] [nvarchar](200) NOT NULL,
	[subscriber_db] [nvarchar](200) NOT NULL,
	[time] [datetime] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


