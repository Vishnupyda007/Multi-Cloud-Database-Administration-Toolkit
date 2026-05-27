/****** Object:  Table [dbo].[DR_MI_Index]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DRMI_Index_CRS](
	[DateT] [datetime] NULL,
	[Servername] [nvarchar](128) NULL,
	[Database_Name] [nvarchar](128) NULL,
	[Index_Details] [nvarchar](max) NULL,
	[pointer] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DR_MI_Servers_Roles]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DRscripts_MI_Servers_Roles](
	[DateT] [datetime] NULL,
	[Servername] [nvarchar](128) NULL,
	[Database_Name] [nvarchar](128) NULL,
	[createrolescript] [nvarchar](max) NULL,
	[pointer] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DR_MI_Users_Roles]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DRscripts_MI_Users_Roles](
	[DateT] [datetime] NULL,
	[Servername] [nvarchar](128) NULL,
	[Database_Name] [nvarchar](128) NULL,
	[name] [nvarchar](128) NULL,
	[createscript] [nvarchar](max) NULL,
	[pointer] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

