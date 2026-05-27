USE [ADT_Audit]
GO
/****** Object:  Table [dbo].[Prod_CRSDB]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Prod_CRSDB](
	[servername] [varchar](150) NULL,
	[dbname] [varchar](50) NULL,
	[Name] [varchar](50) NULL,
	[type] [varchar](50) NULL,
	[create_date] [varchar](50) NULL,
	[modify_date] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[Test]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Test]
AS
SELECT dbo.Prod_CRSDB.servername, dbo.CRS_Activelogin.dbservername, dbo.Prod_CRSDB.dbname, dbo.CRS_Activelogin.dbname AS Expr1, dbo.Prod_CRSDB.Name, dbo.CRS_Activelogin.ploginassociateid, dbo.CRS_Activelogin.sloginassociateid
FROM   dbo.Prod_CRSDB CROSS JOIN
             dbo.CRS_Activelogin
GO
/****** Object:  Table [dbo].[ActiveLogins]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActiveLogins](
	[dbservername] [varchar](100) NULL,
	[dbname] [varchar](200) NULL,
	[ploginassociateid] [varchar](100) NULL,
	[sloginassociateid] [varchar](100) NULL,
	[validity_starttime] [datetime2](3) NULL,
	[validity_endtime] [datetime2](3) NULL,
	[logincreation_status] [varchar](20) NULL,
	[login_name] [varchar](200) NULL,
	[crsviews] [varchar](max) NULL,
	[GL_ApprovalStatus] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ADT_ActiveTrack]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ADT_ActiveTrack](
	[GlobalAppId] [nvarchar](max) NULL,
	[TrackName] [varchar](200) NULL,
	[Status] [varchar](200) NULL,
	[DBReadEnabled] [decimal](18, 0) NULL,
	[DBName] [varchar](200) NULL,
	[DBServerName] [varchar](200) NOT NULL,
	[environment] [varchar](200) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CPU_Utilization_Status]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPU_Utilization_Status](
	[Server_Type] [varchar](200) NULL,
	[Server_Name] [nvarchar](200) NULL,
	[Status] [varchar](200) NULL,
	[CPU Utilization (%)] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CRS_Logfilegrowthhistory]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_Logfilegrowthhistory](
	[ExecutionTime] [datetime] NULL,
	[ServerName] [nvarchar](128) NULL,
	[DatabaseName] [nvarchar](128) NULL,
	[LogSizeInMB] [numeric](18, 5) NULL,
	[LogSpaceUsedInPercentage] [numeric](18, 5) NULL,
	[Pointer] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CRS_MI_Daily_Helpdb_space]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_MI_Daily_Helpdb_space](
	[Datetime] [datetime] NULL,
	[Servername] [nvarchar](128) NULL,
	[Name] [nvarchar](128) NULL,
	[size_MBs] [decimal](10, 2) NULL,
	[size_GBs] [decimal](10, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CRS_MI_Daily_Helpdb_space_Monthly_difference]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_MI_Daily_Helpdb_space_Monthly_difference](
	[Servername] [nvarchar](128) NULL,
	[Name] [nvarchar](128) NULL,
	[SizeDifference] [decimal](10, 2) NULL,
	[LogSizeinGB] [decimal](10, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CRS_MI_WeeklySpace]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_MI_WeeklySpace](
	[Servername] [nvarchar](128) NULL,
	[dbName] [nvarchar](128) NULL,
	[FileName] [nvarchar](128) NULL,
	[type_desc] [nvarchar](128) NULL,
	[CurrentSizeMB] [decimal](10, 2) NULL,
	[FreeSpaceMB] [decimal](10, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CRS_MI_WeeklySpace_Helpdb_weeklydata]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_MI_WeeklySpace_Helpdb_weeklydata](
	[Datetime] [datetime] NULL,
	[Servername] [nvarchar](128) NULL,
	[Name] [nvarchar](128) NULL,
	[size_MBs] [decimal](10, 2) NULL,
	[size_GBs] [decimal](10, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CRS_NonProd_DBSIZE]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_NonProd_DBSIZE](
	[NAME] [nvarchar](128) NULL,
	[Size_MBs] [bigint] NULL,
	[Size_GBs] [bigint] NULL,
	[Servername] [nvarchar](128) NULL,
	[datetime] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CRS_NONPROD_Space]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRS_NONPROD_Space](
	[dbName] [nvarchar](128) NULL,
	[FileName] [nvarchar](128) NULL,
	[type_desc] [nvarchar](128) NULL,
	[CurrentSizeMB] [numeric](10, 2) NULL,
	[FreeSpaceMB] [numeric](10, 2) NULL,
	[Servername] [nvarchar](128) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CRSMAS_Replication_Status]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CRSMAS_Replication_Status](
	[status] [int] NULL,
	[warning] [int] NULL,
	[subscriber] [nvarchar](128) NULL,
	[subscriber_db] [nvarchar](128) NULL,
	[publisher_db] [nvarchar](128) NULL,
	[publication] [nvarchar](128) NULL,
	[publication_type] [int] NULL,
	[subtype] [int] NULL,
	[latency] [int] NULL,
	[latencythreshold] [int] NULL,
	[agentnotrunning] [int] NULL,
	[agentnotrunningthreshold] [int] NULL,
	[timetoexpiration] [int] NULL,
	[expirationthreshold] [int] NULL,
	[last_distsync] [datetime] NULL,
	[distribution_agentname] [nvarchar](128) NULL,
	[mergeagentname] [nvarchar](128) NULL,
	[mergesubscriptionfriendlyname] [nvarchar](128) NULL,
	[mergeagentlocation] [nvarchar](128) NULL,
	[mergeconnectiontype] [nvarchar](128) NULL,
	[mergePerformance] [nvarchar](128) NULL,
	[mergerunspeed] [nvarchar](128) NULL,
	[mergerunduration] [nvarchar](128) NULL,
	[monitorranking] [int] NULL,
	[distributionagentjobid] [nvarchar](128) NULL,
	[mergeagentjobid] [int] NULL,
	[distributionagentid] [int] NULL,
	[distributionagentprofileid] [int] NULL,
	[mergeagentid] [int] NULL,
	[mergeagentprofileid] [int] NULL,
	[logreaderagentname] [nvarchar](128) NULL,
	[publisher] [nvarchar](128) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Daily_Space_monitor_TEMpP15mins]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Daily_Space_monitor_TEMpP15mins](
	[Datetime] [datetime] NULL,
	[Servername] [nvarchar](128) NULL,
	[name] [nvarchar](128) NULL,
	[size_GBs] [decimal](10, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Daily_Space_monitor_Today]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Daily_Space_monitor_Today](
	[Datetime] [datetime] NULL,
	[Servername] [nvarchar](128) NULL,
	[name] [nvarchar](128) NULL,
	[size_GBs] [decimal](10, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Daily_Space_monitor_Yesterday]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Daily_Space_monitor_Yesterday](
	[Datetime] [datetime] NULL,
	[Servername] [nvarchar](128) NULL,
	[name] [nvarchar](128) NULL,
	[size_GBs] [decimal](10, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DE_SQL_jobs]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DE_SQL_jobs](
	[Servername] [nvarchar](128) NULL,
	[JobName] [nvarchar](128) NULL,
	[Outcome] [varchar](7) NULL,
	[LastRunDatetime] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Destination - Query]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Destination - Query](
	[ServerName] [nvarchar](128) NULL,
	[ReplicaRole] [nvarchar](128) NULL,
	[EndpointURL] [nvarchar](256) NULL,
	[DatabaseName] [nvarchar](128) NULL,
	[synchronization_state_desc] [nvarchar](60) NULL,
	[synchronization_health_desc] [nvarchar](60) NULL,
	[lag_in_seconds] [bigint] NULL,
	[last_commit_time] [datetime] NULL,
	[last_hardened_time] [datetime] NULL,
	[last_redone_time] [datetime] NULL,
	[LastRedoDelaySec] [numeric](16, 6) NULL,
	[log_send_queue_size] [bigint] NULL,
	[redo_queue_size] [bigint] NULL,
	[dbName] [nvarchar](128) NULL,
	[FileName] [nvarchar](128) NULL,
	[type_desc] [nvarchar](128) NULL,
	[CurrentSizeMB] [numeric](10, 2) NULL,
	[FreeSpaceMB] [numeric](10, 2) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DR_CRSMAS_replication_status]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DR_CRSMAS_replication_status](
	[status] [int] NULL,
	[warning] [int] NULL,
	[subscriber] [nvarchar](128) NULL,
	[subscriber_db] [nvarchar](128) NULL,
	[publisher_db] [nvarchar](128) NULL,
	[publication] [nvarchar](128) NULL,
	[publication_type] [int] NULL,
	[subtype] [int] NULL,
	[latency] [int] NULL,
	[latencythreshold] [int] NULL,
	[agentnotrunning] [int] NULL,
	[agentnotrunningthreshold] [int] NULL,
	[timetoexpiration] [int] NULL,
	[expirationthreshold] [int] NULL,
	[last_distsync] [datetime] NULL,
	[distribution_agentname] [nvarchar](128) NULL,
	[mergeagentname] [nvarchar](128) NULL,
	[mergesubscriptionfriendlyname] [nvarchar](128) NULL,
	[mergeagentlocation] [nvarchar](128) NULL,
	[mergeconnectiontype] [nvarchar](128) NULL,
	[mergePerformance] [nvarchar](128) NULL,
	[mergerunspeed] [nvarchar](128) NULL,
	[mergerunduration] [nvarchar](128) NULL,
	[monitorranking] [int] NULL,
	[distributionagentjobid] [nvarchar](128) NULL,
	[mergeagentjobid] [int] NULL,
	[distributionagentid] [int] NULL,
	[distributionagentprofileid] [int] NULL,
	[mergeagentid] [int] NULL,
	[mergeagentprofileid] [int] NULL,
	[logreaderagentname] [nvarchar](128) NULL,
	[publisher] [nvarchar](128) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DRMI_Index_CRS]    Script Date: 3/20/2025 5:59:25 PM ******/
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
/****** Object:  Table [dbo].[DRscripts_MI_Servers_Roles]    Script Date: 3/20/2025 5:59:25 PM ******/
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
/****** Object:  Table [dbo].[DRscripts_MI_Users_Roles]    Script Date: 3/20/2025 5:59:25 PM ******/
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
/****** Object:  Table [dbo].[EDS_Prod_Replication_Status]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EDS_Prod_Replication_Status](
	[status] [int] NULL,
	[warning] [int] NULL,
	[subscriber] [nvarchar](128) NULL,
	[subscriber_db] [nvarchar](128) NULL,
	[publisher_db] [nvarchar](128) NULL,
	[publication] [nvarchar](128) NULL,
	[publication_type] [int] NULL,
	[subtype] [int] NULL,
	[latency] [int] NULL,
	[latencythreshold] [int] NULL,
	[agentnotrunning] [int] NULL,
	[agentnotrunningthreshold] [int] NULL,
	[timetoexpiration] [int] NULL,
	[expirationthreshold] [int] NULL,
	[last_distsync] [datetime] NULL,
	[distribution_agentname] [nvarchar](128) NULL,
	[mergeagentname] [nvarchar](128) NULL,
	[mergesubscriptionfriendlyname] [nvarchar](128) NULL,
	[mergeagentlocation] [nvarchar](128) NULL,
	[mergeconnectiontype] [nvarchar](128) NULL,
	[mergePerformance] [nvarchar](128) NULL,
	[mergerunspeed] [nvarchar](128) NULL,
	[mergerunduration] [nvarchar](128) NULL,
	[monitorranking] [int] NULL,
	[distributionagentjobid] [nvarchar](128) NULL,
	[mergeagentjobid] [int] NULL,
	[distributionagentid] [int] NULL,
	[distributionagentprofileid] [int] NULL,
	[mergeagentid] [int] NULL,
	[mergeagentprofileid] [int] NULL,
	[logreaderagentname] [nvarchar](128) NULL,
	[publisher] [nvarchar](128) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Final_report]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Final_report](
	[servername] [varchar](150) NULL,
	[dbname] [varchar](50) NULL,
	[Name] [varchar](50) NULL,
	[type] [varchar](50) NULL,
	[create_date] [varchar](50) NULL,
	[modify_date] [varchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Indexdetails_Changedetails]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Indexdetails_Changedetails](
	[Servername] [nvarchar](128) NULL,
	[datetime] [datetime] NULL,
	[Table_Name] [nvarchar](128) NULL,
	[Index_Name] [nvarchar](128) NULL,
	[Index_Type] [nvarchar](60) NULL,
	[IndexSizeKB] [bigint] NULL,
	[NumOfSeeks] [bigint] NULL,
	[NumOfScans] [bigint] NULL,
	[NumOfLookups] [bigint] NULL,
	[NumOfUpdates] [bigint] NULL,
	[LastSeek] [datetime] NULL,
	[LastScan] [datetime] NULL,
	[LastLookup] [datetime] NULL,
	[LastUpdate] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Ispace_app_Jobs_Status]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Ispace_app_Jobs_Status](
	[name] [nvarchar](200) NULL,
	[run_status] [varchar](200) NULL,
	[durationHHMMSS] [varchar](200) NULL,
	[start_date] [varchar](200) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MI_Servers_Storage_Space_Daily]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MI_Servers_Storage_Space_Daily](
	[Servername] [nvarchar](200) NULL,
	[Total_TB] [decimal](9, 3) NULL,
	[Used_TB] [decimal](9, 3) NULL,
	[Available_GB] [decimal](9, 3) NULL,
	[Percent] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MonitorTransactionLogFileUsage]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MonitorTransactionLogFileUsage](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [sysname] NOT NULL,
	[LogSizeInMB] [decimal](18, 5) NULL,
	[LogSpaceUsedInPercentage] [decimal](18, 5) NULL,
	[Pointer] [int] NULL,
	[Servername] [nvarchar](200) NULL,
	[ExecutionTime] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Prod_Replication_Status]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Prod_Replication_Status](
	[status] [int] NULL,
	[warning] [int] NULL,
	[subscriber] [nvarchar](128) NULL,
	[subscriber_db] [nvarchar](128) NULL,
	[publisher_db] [nvarchar](128) NULL,
	[publication] [nvarchar](128) NULL,
	[publication_type] [int] NULL,
	[subtype] [int] NULL,
	[latency] [int] NULL,
	[latencythreshold] [int] NULL,
	[agentnotrunning] [int] NULL,
	[agentnotrunningthreshold] [int] NULL,
	[timetoexpiration] [int] NULL,
	[expirationthreshold] [int] NULL,
	[last_distsync] [datetime] NULL,
	[distribution_agentname] [nvarchar](128) NULL,
	[mergeagentname] [nvarchar](128) NULL,
	[mergesubscriptionfriendlyname] [nvarchar](128) NULL,
	[mergeagentlocation] [nvarchar](128) NULL,
	[mergeconnectiontype] [nvarchar](128) NULL,
	[mergePerformance] [nvarchar](128) NULL,
	[mergerunspeed] [nvarchar](128) NULL,
	[mergerunduration] [nvarchar](128) NULL,
	[monitorranking] [int] NULL,
	[distributionagentjobid] [nvarchar](128) NULL,
	[mergeagentjobid] [int] NULL,
	[distributionagentid] [int] NULL,
	[distributionagentprofileid] [int] NULL,
	[mergeagentid] [int] NULL,
	[mergeagentprofileid] [int] NULL,
	[logreaderagentname] [nvarchar](128) NULL,
	[publisher] [nvarchar](128) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ProdServers]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProdServers](
	[servername] [nvarchar](128) NULL,
	[dbname] [nvarchar](128) NULL,
	[Name] [nvarchar](128) NULL,
	[type] [nvarchar](128) NULL,
	[create_date] [datetime] NULL,
	[modify_date] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PST_2090]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PST_2090](
	[status] [int] NULL,
	[warning] [int] NULL,
	[subscriber] [nvarchar](128) NULL,
	[subscriber_db] [nvarchar](128) NULL,
	[publisher_db] [nvarchar](128) NULL,
	[publication] [nvarchar](128) NULL,
	[publication_type] [int] NULL,
	[subtype] [int] NULL,
	[latency] [int] NULL,
	[latencythreshold] [int] NULL,
	[agentnotrunning] [int] NULL,
	[agentnotrunningthreshold] [int] NULL,
	[timetoexpiration] [int] NULL,
	[expirationthreshold] [int] NULL,
	[last_distsync] [datetime] NULL,
	[distribution_agentname] [nvarchar](128) NULL,
	[mergeagentname] [nvarchar](128) NULL,
	[mergesubscriptionfriendlyname] [nvarchar](128) NULL,
	[mergeagentlocation] [nvarchar](128) NULL,
	[mergeconnectiontype] [nvarchar](128) NULL,
	[mergePerformance] [nvarchar](128) NULL,
	[mergerunspeed] [nvarchar](128) NULL,
	[mergerunduration] [nvarchar](128) NULL,
	[monitorranking] [int] NULL,
	[distributionagentjobid] [nvarchar](128) NULL,
	[mergeagentjobid] [int] NULL,
	[distributionagentid] [int] NULL,
	[distributionagentprofileid] [int] NULL,
	[mergeagentid] [int] NULL,
	[mergeagentprofileid] [int] NULL,
	[logreaderagentname] [nvarchar](128) NULL,
	[publisher] [nvarchar](128) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Replication_Lag_MI]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Replication_Lag_MI](
	[ServerName] [nvarchar](128) NULL,
	[ReplicaRole] [nvarchar](128) NULL,
	[EndpointURL] [nvarchar](256) NULL,
	[DatabaseName] [nvarchar](128) NULL,
	[synchronization_state_desc] [nvarchar](60) NULL,
	[synchronization_health_desc] [nvarchar](60) NULL,
	[lag_in_seconds] [bigint] NULL,
	[last_commit_time] [datetime] NULL,
	[last_hardened_time] [datetime] NULL,
	[last_redone_time] [datetime] NULL,
	[LastRedoDelaySec] [numeric](16, 6) NULL,
	[log_send_queue_size] [bigint] NULL,
	[redo_queue_size] [bigint] NULL,
	[Datetime] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Required_nonprod_dbspace]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Required_nonprod_dbspace](
	[NAME] [nvarchar](128) NULL,
	[Size_MBs] [bigint] NULL,
	[Size_GBs] [decimal](10, 2) NULL,
	[Servername] [nvarchar](128) NULL,
	[datetime] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TEMP_server_roles]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEMP_server_roles](
	[Servername] [nvarchar](128) NULL,
	[DateT] [datetime] NULL,
	[Database_Name] [nvarchar](128) NULL,
	[createrolescript] [nvarchar](max) NULL,
	[pointer] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Temp_User_role]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Temp_User_role](
	[Servername] [nvarchar](128) NULL,
	[DateT] [datetime] NULL,
	[Database_Name] [nvarchar](128) NULL,
	[pointer] [int] NULL,
	[name] [nvarchar](128) NULL,
	[createscript] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Tempdb_prodsize]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tempdb_prodsize](
	[datetime] [datetime] NULL,
	[Servername] [nvarchar](128) NULL,
	[TEMPDB_database size (GB)] [bigint] NULL
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[2090_RHMS_Replication_Status_MI]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,sukanya>
-- Create date: <August 2,2023,,>
-- Description:	<CRS_Replciation mailer_MI instance,,>
-- =============================================
CREATE PROCEDURE [dbo].[2090_RHMS_Replication_Status_MI] 
--	-- Add the parameters for the stored procedure here
--	<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
--	<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @tableHTML NVARCHAR(MAX) ;
SET @tableHTML =
N'<H3 align = "Left"><font face="verdana" color="green" size = "2">Transactional Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM PST_2090
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' ;
Print @tableHTML

declare @email2 varchar(100)

SELECT @email2 = [email_address] FROM [msdb].[dbo].[sysoperators] where name = 'CRS'

EXEC msdb.dbo.sp_send_dbmail @recipients=@email2,
    @subject = 'RHMS-EDS replication status',
	  @profile_name = 'crsdba_adt',
    @body = @tableHTML,
    @body_format = 'HTML' ;

--	EXEC msdb.dbo.sp_send_dbmail
--@profile_name='ADTAudit',
--@recipients='CISADPInfraSupportTeam@cognizant.com',
--@body = @tableHTML,
--@body_format ='HTML',
--@subject = 'ADT_Weekly_Audit' ;
END
GO
/****** Object:  StoredProcedure [dbo].[ADT_Audit_MI]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:      Sukanya Subbiah
-- Create date: FEb 2023
-- Description: Return all members
-- =============================================
--Store procedure name is --> stpGetAllMembers
CREATE PROCEDURE [dbo].[ADT_Audit_MI]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

 
 
update ProdServers  Set name = REPLACE (name,'@cognizant.com','') 
update ProdServers  Set name = REPLACE (name,'cts\','') 
update ProdServers Set servername = REPLACE (servername,'CTSINAZSIPDDB06','ctsinazsicsql01')
update ProdServers Set servername = REPLACE (servername,'CTSINAZSIPDDB05','ctsinazsicsql01')
update ProdServers Set servername = REPLACE (servername,'CTSINAZSIPDDB07','ctsinazsicsql02')
update ProdServers Set servername = REPLACE (servername,'CTSINAZSIPDDB08','ctsinazsicsql02')

update ProdServers  Set servername = REPLACE (servername,'ctsazmibcapps3.293366d454bb.database.windows.net','ctsazmifgapps3.293366d454bb.database.windows.net')

update ProdServers  Set servername = REPLACE (servername,'ctsazsimipddeapps1.293366d454bb.database.windows.net','ctsazsimifgdeapps1.293366d454bb.database.windows.net')
update ProdServers  Set servername = REPLACE (servername,'ctsazsimi','ctsazfgmi') where servername not like '%deapps1%'
 update ProdServers  Set servername = REPLACE (servername,'azsqlaiassistantpdsrvr','azsqlaiassistantpdsrvr.database.windows.net')


--select * from  [dbo].[ADT_ActiveTrack] 

--Select * from  activeLogins


 truncate table [dbo].[prod_crsdb]
 --truncate  table  [dbo].[ADT_ActiveTrack] 

 --select count(sloginassociateid) from  activeLogins where sloginassociateid <>'' 


Insert into Prod_CRSDB select * from ProdServers t1 where not exists (select 1 from
  activeLogins t2   where 
  t1.servername=t2.dbservername and 
  t1.dbname=t2.dbname and   
  t1.name=t2.ploginassociateid or t1.name=t2.sloginassociateid ) 

  Select * from Prod_CRSDB F1 where   
  exists (select 1 from
  [dbo].[ADT_ActiveTrack] F2  where 
  F1.servername=f2.dbservername  
   and F1.dbname=F2.dbname
  ) and
  dbname not like 'CentralRepository' and  name not like '%MSi%'	 ---- need to remove MSI login from package


      select * from Prod_CRSDB t1 where  not exists (select * from
  activelogins t2   where 
    t1.servername=t2.dbservername and 
  --t1.dbname=t2.dbname and   
  --t2.GL_approvalstatus = '1' and
   --t2.crsviews is  null and 
  t1.name=t2.ploginassociateid   or t1.name=t2.sloginassociateid) and name not like '%MSi%'	 and dbname like 'CentralRepository'



  
END
GO
/****** Object:  StoredProcedure [dbo].[CRS_Logfilegrowthhistory_everyhour]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<sukanya,240485>

-- =============================================
CREATE PROCEDURE [dbo].[CRS_Logfilegrowthhistory_everyhour]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


 
SELECT *

  FROM CRS_Logfilegrowthhistory where [LogSpaceUsedInPercentage] >70

declare @val int

	set @val= (select count(*) from [CRS_Logfilegrowthhistory] where logspaceusedinpercentage >=70)

if @val>=1

	BEGIN
 
DECLARE @xml NVARCHAR(MAX)

DECLARE @body NVARCHAR(MAX)
 
SET @xml = CAST(( SELECT [ServerName] AS 'td','',[DatabaseName] AS 'td','',[LogSizeInMB] AS 'td','', [LogSpaceUsedInPercentage] AS 'td','' from

[CRS_Logfilegrowthhistory] where [LogSpaceUsedInPercentage] >70

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))
 
 
SET @body ='<html><body><H4>Logspace Utilization Report</H4>

<table border = 1> 

<tr>

<th> ServerName </th> <th> DatabaseName </th> <th> LogSizeInMB </th> <th> LogSpaceUsedInPercentage </th></tr>'    

SET @body = @body + @xml +'</table></body></html>'
 
EXEC msdb.dbo.sp_send_dbmail

@profile_name='ADTAudit',

@recipients='CISADPInfraSupportTeam@cognizant.com', 

@body = @body,

@body_format ='HTML',

@subject = 'Logspace Utilization'
 
truncate table  [CRS_Logfilegrowthhistory]

END

else

truncate table  [CRS_Logfilegrowthhistory]


end
GO
/****** Object:  StoredProcedure [dbo].[CRS_MI_Daily_Helpdb_space_Monthly_difference_mailer]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<sukanya>
-- Create date: <March08>
-- Description:	<CRS_MI_Daily_Helpdb_space_Monthly_difference_mailer>
-- =============================================
CREATE PROCEDURE [dbo].[CRS_MI_Daily_Helpdb_space_Monthly_difference_mailer]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	Truncate table CRS_MI_Daily_Helpdb_space_Monthly_difference
    -- Insert statements for procedure here
	Insert  into CRS_MI_Daily_Helpdb_space_Monthly_difference SELECT distinct
    s1.servername,
    name,
    (SELECT size_GBs FROM CRS_MI_Daily_Helpdb_space s2 WHERE s2.servername = s1.servername AND s2.name = s1.name AND DAY(s2.datetime) = 1 AND MONTH(s2.datetime) 
	= MONTH(GETDATE()) AND YEAR(s2.datetime) = YEAR(GETDATE())) -
    (SELECT size_GBs FROM CRS_MI_Daily_Helpdb_space s3 WHERE s3.servername = s1.servername AND s3.name = s1.name AND DAY(s3.datetime) = 1 AND MONTH(s3.datetime)
	= MONTH(GETDATE()) - 1 AND YEAR(s3.datetime) = YEAR(GETDATE())) AS MonthlyGrowthinGB ,CAST(s4.CurrentSizeMB/1024 as int) AS LogSizeinGB
FROM
    CRS_MI_Daily_Helpdb_space s1  

	inner join CRS_MI_WeeklySpace S4  on s1.Servername=s4.Servername and s1.Name=s4.dbName and s4.type_desc ='LOG'

WHERE
    (DAY(s1.datetime) = 1 AND MONTH(s1.datetime) = MONTH(GETDATE()))
    OR (DAY(s1.datetime) = 1 AND MONTH(s1.datetime) = MONTH(GETDATE()) - 1) 
	--and

	--s4.type_desc ='LOG'
GROUP BY
    s1.Servername,s4.CurrentSizeMB,
    name
ORDER BY
    MonthlyGrowthinGB desc

	Begin 

	DECLARE @xml NVARCHAR(MAX)
	DECLARE @body NVARCHAR(MAX)
	Declare @date Nvarchar(MAX)


SET @xml = CAST(( SELECT top (10) [servername] AS 'td','',[name] AS 'td','', [SizeDifference] AS 'td','', [LogSizeinGB] AS 'td','' from
CRS_MI_Daily_Helpdb_space_Monthly_difference ORDER BY    SizeDifference desc
 

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))
---SET @date = DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(YEAR, -3, GETDATE())) + 1, 0);


SET @body ='
<html><body>

<table border = 1> 
<tr>
<th> Servername </th> <th> DBName </th> <th> MonthlyGrowthinGB</th> <th>LogSizeinGB</th> </tr>'  


 begin
SET @body = @body + @xml +'</table></body></html>'
end

----To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  


declare @sql varchar(8000)

select @sql = 'bcp "select ''Servername'',''Name'',''SizeDifference''union all select convert(nvarchar(128),[Servername]),convert(nvarchar(128),[Name]),convert(nvarchar(128),[SizeDifference]),convert(nvarchar(128),[LogSizeinGB])  FROM ADT_Audit..CRS_MI_Daily_Helpdb_space_Monthly_difference" queryout \\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\CRS_MI_Daily_Helpdb_space_Monthly_difference.csv -c -t, -T -S' + @@servername
exec master..xp_cmdshell @sql
DECLARE @filenames varchar(max)
DECLARE @file1 VARCHAR(MAX) = '\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\CRS_MI_Daily_Helpdb_space_Monthly_difference.csv'
SELECT @filenames = @file1

--else
--begin
--Set @body=@date+  ' <html><body><H3>No Expired logins<time> </H3>'
--end

select @body

EXEC msdb.dbo.sp_send_dbmail
@profile_name='ADTAudit',
@recipients='sukanya.Subbiah@cognizant.com;Tharani.Ravindran@cognizant.com',
@body = @body,
@body_format ='HTML',
@subject = 'CRS_MI_Monthly_DBSize_Difference' ,
@file_attachments = @filenames
END
ENd
GO
/****** Object:  StoredProcedure [dbo].[CRS_Prod_TEmpdb_space]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<sukanya>
-- Create date: <March08>
-- Description:	<CRS_MI_Daily_Helpdb_space_Monthly_difference_mailer>
-- =============================================
CREATE PROCEDURE [dbo].[CRS_Prod_TEmpdb_space]
	-- Add the parameters for the stored procedure here

AS
BEGIN


	DECLARE @xml NVARCHAR(MAX)
	DECLARE @body NVARCHAR(MAX)
	Declare @date Nvarchar(MAX)


SET @xml = CAST(( SELECT top (40) [Datetime] AS 'td','',[Servername] AS 'td','', [TEMPDB_database size (GB)] AS 'td','' from
[Tempdb_prodsize] ORDER BY    [TEMPDB_database size (GB)] desc

 

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))
---SET @date = DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(YEAR, -3, GETDATE())) + 1, 0);


SET @body ='
<html><body>

<table border = 1> 
<tr>
<th> datetime</th> <th> Servername (GB) </th> <th> TEMPDB_database size (GB)</th> </tr>'  


 begin
SET @body = @body + @xml +'</table></body></html>'
end

----To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  



--DECLARE @filenames varchar(max)
--DECLARE @file1 VARCHAR(MAX) = '\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\CRS_MI_Daily_Helpdb_space_Monthly_difference.csv'
--SELECT @filenames = @file1

--else
--begin
--Set @body=@date+  ' <html><body><H3>No Expired logins<time> </H3>'
--end

select @body

EXEC msdb.dbo.sp_send_dbmail
@profile_name='ADTAudit',
@recipients='CRSDBASUPPORT@cognizant.com;CISADPInfraSupportTeam@cognizant.com',
@body = @body,
@body_format ='HTML',
@subject = 'CRSProduction_Tempdb_size'

END

GO
/****** Object:  StoredProcedure [dbo].[CRS_Prod_TEmpdb_space_every30mins]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<sukanya>
-- Create date: <March08>
-- Description:	<CRS_MI_Daily_Helpdb_space_Monthly_difference_mailer>
-- =============================================
CREATE PROCEDURE [dbo].[CRS_Prod_TEmpdb_space_every30mins]
	-- Add the parameters for the stored procedure here

AS
BEGIN


	DECLARE @xml NVARCHAR(MAX)
	DECLARE @body NVARCHAR(MAX)
	Declare @date Nvarchar(MAX)
	Declare @count int 
	Print @count
	select @count  =count(1) from Tempdb_prodsize where [TEMPDB_database size (GB)] > 1000  
	Print @count
	IF @count >0
	begin

SET @xml = CAST(( SELECT top (40) [Datetime] AS 'td','',[Servername] AS 'td','', [TEMPDB_database size (GB)] AS 'td','' from
[Tempdb_prodsize] where [TEMPDB_database size (GB)] > 1000  ORDER BY    [TEMPDB_database size (GB)] desc
--+
-- SELECT top (40) [Datetime] AS 'td','',[Servername] AS 'td','', [TEMPDB_database size (GB)] AS 'td','' from
--[Tempdb_prodsize] where [TEMPDB_database size (GB)] > 1000  and servername ='ctsazsimipddeapps1.293366d454bb.database.windows.net'

 

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))
---SET @date = DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(YEAR, -3, GETDATE())) + 1, 0);


SET @body ='<html><body>

<table border = 1> 
<tr>
<th> datetime</th> <th> Servername (GB) </th> <th> TEMPDB_database size (GB)</th> </tr>'  


 begin
SET @body = @body + @xml +'</table></body></html>'
end

----To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  



--DECLARE @filenames varchar(max)
--DECLARE @file1 VARCHAR(MAX) = '\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\CRS_MI_Daily_Helpdb_space_Monthly_difference.csv'
--SELECT @filenames = @file1

--else
--begin
--Set @body=@date+  ' <html><body><H3>No Expired logins<time> </H3>'
--end

select @body

EXEC msdb.dbo.sp_send_dbmail
@profile_name='ADTAudit',
@recipients='CISADPInfraSupportTeam@cognizant.com',
@body = @body,
@body_format ='HTML',
@subject = 'CRSProduction_Tempdb_size'
END
END

GO
/****** Object:  StoredProcedure [dbo].[CRSMAS_Replication_Status_MI]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,sukanya>
-- Create date: <August 2,2023,,>
-- Description:	<CRS_Replciation mailer_MI instance,,>
-- =============================================
CREATE PROCEDURE [dbo].[CRSMAS_Replication_Status_MI] 
--	-- Add the parameters for the stored procedure here
--	<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
--	<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @tableHTML NVARCHAR(MAX) ;
SET @tableHTML =
N'<H3 align = "Left"><font face="verdana" color="green" size = "2">Transactional Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM CRSMAS_Replication_Status
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' ;
Print @tableHTML

declare @email2 varchar(100)

SELECT @email2 = [email_address] FROM [msdb].[dbo].[sysoperators] where name = 'MI_Repl_Status'

EXEC msdb.dbo.sp_send_dbmail @recipients=@email2,
    @subject = 'MI Replication Status Report',
	  @profile_name = 'crsdba_adt',
    @body = @tableHTML,
    @body_format = 'HTML' ;

--	EXEC msdb.dbo.sp_send_dbmail
--@profile_name='ADTAudit',
--@recipients='CISADPInfraSupportTeam@cognizant.com',
--@body = @tableHTML,
--@body_format ='HTML',
--@subject = 'ADT_Weekly_Audit' ;
END
GO
/****** Object:  StoredProcedure [dbo].[Daily_statusmailer]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



      
    
CREATE  PROCEDURE [dbo].[Daily_statusmailer]      
       
AS      
BEGIN     


CREATE TABLE #temp(      
 [Server_Type] [varchar](200) NULL,[Server_Name] [varchar](200) NULL,[Status] [varchar](200) NULL,CPU_Utilization_Percent  [varchar](200)
);     

INSERT INTO #temp select * from [CPU_Utilization_Status]       
      
       
      
Select * From #temp with(nolock)  
       
Declare @date Nvarchar(MAX) = convert(nvarchar,getdate(),101);     
--SET @date = GETDATE();      
DECLARE @html varchar(MAX) = '     
<p>        
<br> CPU Utilization<br>     
<br> <br>    
</p>    
<style>  
  
table, td, th {  
border:1px solid black;  
border-collapse: collapse;  
font-family:Serif;}  
th {  
padding:10px;  
text-align: center;  
vertical-align: middle;}  
</style>  
<table id="tablaPrincipal"      
<tr style="background:#87ceeb;; font-style:initial;style="height:80">                         
<th> Server_Type </th>   
<th> Server_Name </th>   
<th> Status </th>         
<th> CPU_Utilization_Percent </th>                       
</tr>  
'SELECT @html =  @html +   
'<td style="text-align: Center;">'+ Server_Type +'</td>  
<td style="text-align: Center;">'+ Server_Name + '</td>  
<td style="text-align: Center;">'+ Status  + '</td>   
<td style="text-align: Center;">'+ CPU_Utilization_Percent  + '</td>    
</tr>'    
FROM #temp with(nolock)  ORDER BY CPU_Utilization_Percent DESC
      
 
DROP TABLE #temp  

Select @html

	DECLARE @tableHTML NVARCHAR(MAX) ;
SET @tableHTML =

N'<H3 align = "Left"><font face="verdana" color="green" size = "2">CRSMAS MI Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
 FROM Prod_Replication_Status where publisher_db in  ('CentralRepository','ent_data_store_sub')
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' +


N'<H3 align = "Left"><font face="verdana" color="green" size = "2">EDS MI Replication Status Report:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM Prod_Replication_Status where publisher_db like 'ent_data_store'
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' 



--N'<H3 align = "Left"><font face="verdana" color="green" size = "2">Clearance-EDS Replication Status:</font></H3>' +
--N'<table border="1">' +
--N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
--N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
--CAST ( ( SELECT td =Publication, '',
--td = subscriber, '',
--td = CASE status 
--WHEN 1 THEN 'Started'
--WHEN 2 THEN 'Succeed'
--WHEN 3 THEN 'In progress'
--WHEN 4 THEN 'Idle'
--WHEN 5 THEN 'Retrying'
--WHEN 6 THEN 'Failed'
--END,'',
--td = CAST(latency as VARCHAR(50)), '',
--td = CAST(last_distsync as varchar(100)), ''
--FROM Prod_Replication_Status where subscriber_db like '%OneC_Clearance%'
--FOR XML PATH('tr'), TYPE 
--) AS NVARCHAR(MAX) ) +
--N'</font></table>' +


--N'<H3 align = "Left"><font face="verdana" color="green" size = "2">RHMS-EDS Replication Status:</font></H3>' +
--N'<table border="1">' +
--N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
--N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
--CAST ( ( SELECT td =Publication, '',
--td = subscriber, '',
--td = CASE status 
--WHEN 1 THEN 'Started'
--WHEN 2 THEN 'Succeed'
--WHEN 3 THEN 'In progress'
--WHEN 4 THEN 'Idle'
--WHEN 5 THEN 'Retrying'
--WHEN 6 THEN 'Failed'
--END,'',
--td = CAST(latency as VARCHAR(50)), '',
--td = CAST(last_distsync as varchar(100)), ''
--FROM Prod_Replication_Status where subscriber_db like '%OneC_2090%'
--FOR XML PATH('tr'), TYPE 
--) AS NVARCHAR(MAX) ) +
--N'</font></table>' ;

Print @tableHTML
-------------------[CPU_Utilization_Status]  -----------------
     
      

--------------------DESQLJOBS------------------
--To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  




declare @sql varchar(8000)


select @sql = 'bcp "select  ''servername'',''jobname'',''outcome'',''Lastrundate'' union all select convert(nvarchar(128),[Servername]),convert(nvarchar(128),isnull([jobname],'''')),convert(nvarchar(128),isnull([outcome],'''')),Convert(nvarchar(128),isnull([LastRunDatetime],'' ''))  FROM ADT_Audit..DE_SQL_jobs" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\DE_SQLjobs\DE_SQLjobs.csv -c -t, -T -S'+ @@Servername;

exec master..xp_cmdshell @sql

DECLARE @filenames varchar(max)
DECLARE @file1 VARCHAR(MAX) = '\\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\DE_SQLjobs\DE_SQLjobs.csv'

SELECT @filenames = @file1 


      
  

declare @email2 varchar(100)

SELECT @email2 = [email_address] FROM [msdb].[dbo].[sysoperators] where name = 'CISADP'
DECLARE @BODY NVARCHAR(MAX)
      SET @BODY ='Hi Team,                    
 
Please find the CPU utilization, Replication status and  DE_SQL_jobshistory'+
 @tableHTML + @html
EXEC msdb.dbo.sp_send_dbmail      
 @profile_name = 'adtaudit',      
@recipients='CISADPInfraSupportTeam@cognizant.com',      
@body = @BODY,      
@body_format ='HTML', 
  @file_attachments = @filenames,
@subject = 'Daily Replication ,CPU utilization status and DE SQL jobs' ;      
      
END      


-------------[dbo].[USP_CPU_Utilization_Status] 
       
GO
/****** Object:  StoredProcedure [dbo].[DE_SQL_JOBS1]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DE_SQL_JOBS1]
	
AS
BEGIN
	
--To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  




declare @sql varchar(8000)


select @sql = 'bcp "select  ''servername'',''jobname'',''outcome'',''Lastrundate'' union all select convert(nvarchar(128),[Servername]),convert(nvarchar(128),isnull([jobname],'''')),convert(nvarchar(128),isnull([outcome],'''')),Convert(nvarchar(128),isnull([LastRunDatetime],'' ''))  FROM ADT_Audit..DE_SQL_jobs" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\DE_SQLjobs\DE_SQLjobs.csv -c -t, -T -S'+ @@Servername;
--SELECT @sql =  'bcp "select studentid from tmseprd.dbo.Feith_Emas_Compare Where status = 'U' and counselor >199  and stage > 200 " queryout "C:\EMAS_Feith\advmove.txt" -c -t, -T  -S' + @@Servername;

--union all select convert(nvarchar(128),[Servername]),convert(nvarchar(128),[jobname]),convert(nvarchar128),[Outcome]) FROM ADT_Audit..DE_SQL_jobs" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\DE_SQLjobs\DE_SQLjobs.csv -c -t, -T -S' 
--select @sql = 'bcp "select ''servername'',''DBName'',''FileName'',''Type_desc'',''CurrentSizeMB'',''FreeSpaceMB''union all select convert(nvarchar(128),[Servername]),convert(nvarchar(128),[DBName]),convert(nvarchar(128),[FileName]),Convert(nvarchar(128),[Type_Desc]),Convert(nvarchar(128),[CurrentSizeMB]),Convert(nvarchar(128),[FreeSpaceMB]) FROM ADT_Audit..CRS_MI_WeeklySpace" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Datafilesizedetails.csv -c -t, -T -S' + @@servername

----bcp "select 'SalesOrderID', 'CarrierTrackingNumber','ModifiedDate','UpdateTime' union all SELECT 
----convert(varchar(20),[SalesOrderID]),convert(varchar(20),[CarrierTrackingNumber]),CONVERT(nvarchar(30), 
--[ModifiedDate], 120),CONVERT(nvarchar(30), [UpdateTime], 120) FROM [testdb].[dbo].[SalesOrderDetailIn]" 
--queryout D:\People.txt -t, -c -T  


----sqlcmd -s, -W -Q "set nocount on; select * from [DATABASE].[dbo].[TABLENAME]" | findstr /v /c:"-" /b > "c:\dirname\file.csv"


exec master..xp_cmdshell @sql

 


DECLARE @filenames varchar(max)
DECLARE @file1 VARCHAR(MAX) = '\\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\DE_SQLjobs\DE_SQLjobs.csv'

--DECLARE @file3 VARCHAR(MAX) = ';C:\Testfiles\Test3.csv'

 

-- Create list from optional files
SELECT @filenames = @file1 



 

-- Send the email
EXEC msdb.dbo.sp_send_dbmail
  @profile_name = 'adtaudit',
  @recipients= 'CISADPInfraSupportTeam@cognizant.com',
  @subject = 'DE_SQL_Jobs Status',
  @body= 'Hi Team,
Please find the attached DE_SQL_job status',
  @file_attachments = @filenames

END


GO
/****** Object:  StoredProcedure [dbo].[DR_CRSMAS_Replication_Status_MI]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,sukanya>
-- Create date: <August 2,2023,,>
-- Description:	<CRS_Replciation mailer_MI instance,,>
-- =============================================
CREATE PROCEDURE [dbo].[DR_CRSMAS_Replication_Status_MI] 
--	-- Add the parameters for the stored procedure here
--	<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
--	<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @tableHTML NVARCHAR(MAX) ;
SET @tableHTML =
N'<H3 align = "Left"><font face="verdana" color="green" size = "2">Transactional Replication Status in DR:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM DR_CRSMAS_replication_status
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' ;
Print @tableHTML

declare @email2 varchar(100)

SELECT @email2 = [email_address] FROM [msdb].[dbo].[sysoperators] where name = 'MI_Repl_Status'

EXEC msdb.dbo.sp_send_dbmail @recipients=@email2,
    @subject = 'DR_MI Replication Status Report',
	  @profile_name = 'ADTAudit',
    @body = @tableHTML,
    @body_format = 'HTML' ;

--	EXEC msdb.dbo.sp_send_dbmail
--@profile_name='ADTAudit',
--@recipients='CISADPInfraSupportTeam@cognizant.com',
--@body = @tableHTML,
--@body_format ='HTML',
--@subject = 'ADT_Weekly_Audit' ;
END
GO
/****** Object:  StoredProcedure [dbo].[DR_INDEX_USER_Roles_ACCESSSCripts]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Sukanya,,240485>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DR_INDEX_USER_Roles_ACCESSSCripts]
	
AS

BEGIN
	
--To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  




declare @sql varchar(8000)
declare @sql1 varchar(8000)
declare @sql2 varchar(8000)
select @sql = 'bcp "select ''DateT'',''Servername'',''Database_Name'',''name'',''createscript''union all select convert(nvarchar(128),[DateT]),convert(nvarchar(128),[Servername]),convert(nvarchar(128),[Database_Name]),Convert(nvarchar(128),[name]),Convert(nvarchar(128),[createscript]) FROM ADT_Audit..DRscripts_MI_Users_Roles where convert(Date,DateT)=convert(Date,getdate())" queryout \\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset\DRscripts_MI_Users_Roles.csv -c -t, -T -S' + @@servername
select @sql1 = 'bcp "select ''DateT'',''Servername'',''Database_Name'',''createrolescript''union all select convert(nvarchar(128),[DateT]),convert(nvarchar(128),[Servername]),convert(nvarchar(128),[Database_Name]),Convert(nvarchar(128),[createrolescript]) FROM ADT_Audit..DRscripts_MI_Servers_Roles where convert(Date,DateT)=convert(Date,getdate())" queryout \\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset\DRscripts_MI_Servers_Roles.csv -c -t, -T -S'+ @@servername
select @sql2 = 'bcp "select ''DateT'',''Servername'',''Database_Name'',''Index_Details''union all select convert(nvarchar(128),[DateT]),convert(nvarchar(128),[Servername]),convert(nvarchar(128),[Database_Name]),Convert(nvarchar(128),[Index_Details]) FROM ADT_Audit..DRMI_Index_CRS where convert(Date,DateT)=convert(Date,getdate())" queryout \\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset\DRMI_Index_CRS.csv -c -t, -T -S'+ @@servername

----bcp "select 'SalesOrderID', 'CarrierTrackingNumber','ModifiedDate','UpdateTime' union all SELECT 
----convert(varchar(20),[SalesOrderID]),convert(varchar(20),[CarrierTrackingNumber]),CONVERT(nvarchar(30), 
--[ModifiedDate], 120),CONVERT(nvarchar(30), [UpdateTime], 120) FROM [testdb].[dbo].[SalesOrderDetailIn]" 
--queryout D:\People.txt -t, -c -T  


----sqlcmd -s, -W -Q "set nocount on; select * from [DATABASE].[dbo].[TABLENAME]" | findstr /v /c:"-" /b > "c:\dirname\file.csv"


exec master..xp_cmdshell @sql
exec master..xp_cmdshell @sql1
exec master..xp_cmdshell @sql2
 


DECLARE @filenames varchar(max)
--DECLARE @file1 VARCHAR(MAX) = '\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset\DRscripts_MI_Users_Roles.csv'
--DECLARE @file2 VARCHAR(MAX) = ';\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset\DRscripts_MI_Servers_Roles.txt'
--DECLARE @file3 VARCHAR(MAX) = ';\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset\DRMI_Index_CRS.csv'

 

---- Create list from optional files
--SELECT @filenames = @file1 + @file3 + @file2
--+ @file3

--DECLARE @FolderPath VARCHAR(255) =  '\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset';
--DECLARE @ZipFilePath VARCHAR(255) = '\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset.zip';
--DECLARE @Command VARCHAR(1000);
 
--SET @Command = '7z a -r "' + @ZipFilePath + '" "' + @FolderPath + '"';
--EXEC master..xp_cmdshell @Command;


Set @filenames='\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Resultset.zip'
EXEC xp_cmdshell 'powershell.exe -ExecutionPolicy Bypass -File "\\ctsc00969373301\Backup\Daily_Server_Storagereport_Dontdelet\DR_INDEX_USER_Roles_ACCESS\Extract.ps1"'
 
-- DELETE FROM your_table
--WHERE your_datetime_column < DATEADD(day, -10, GETDATE()); --yet to update

-- Send the email
EXEC msdb.dbo.sp_send_dbmail
  @profile_name = 'adtaudit',

  @recipients= 'CISADPInfraSupportTeam@cognizant.com',
  @subject = 'DR_INDEX_USER_Roles_AccessScripts',
 
  @file_attachments = @filenames

Truncate table [dbo].[DRMI_Index_CRS]
Truncate table [dbo].[DRscripts_MI_Servers_Roles]
truncate  table [dbo].[DRscripts_MI_Users_Roles]

END


GO
/****** Object:  StoredProcedure [dbo].[EDS_ReplicationStatus_SP]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Sukanya Subbiah
-- Create date: FEb 2023
-- Description: Return all members
-- =============================================
--Store procedure name is --> stpGetAllMembers
CREATE PROCEDURE [dbo].[EDS_ReplicationStatus_SP]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

 DECLARE @tableHTML NVARCHAR(MAX) ;
SET @tableHTML =
N'<H3 align = "Left"><font face="verdana" color="green" size = "2">EDS MI Replication Status Report:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = 
"2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last 
Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM [dbo].[EDS_Prod_Replication_Status]
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' ;

declare @email2 varchar(100)

SELECT @email2 = [email_address] FROM [msdb].[dbo].[sysoperators] where name = 
'CISADP'

EXEC msdb.dbo.sp_send_dbmail @recipients=@email2,
    @subject = 'EDS MI Replication Status Report',
	   @profile_name = 'crsdba_adt',
    @body = @tableHTML,
    @body_format = 'HTML' ;
	   	   
END
GO
/****** Object:  StoredProcedure [dbo].[FinalReport]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[FinalReport]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

Truncate  table [dbo].[Final_report] 

  Insert into [dbo].[Final_report] 
EXEC[dbo].[ADT_Audit_MI]



BEGIN
	DECLARE @xml NVARCHAR(MAX)
	DECLARE @body NVARCHAR(MAX)
	Declare @date Nvarchar(MAX)


SET @xml = CAST(( SELECT [servername] AS 'td','',[dbname] AS 'td','', [Name] AS 'td' from
Final_report 


FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))
---SET @date = DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(YEAR, -3, GETDATE())) + 1, 0);
SET @date = GETDATE();

SET @body ='<html><body><H3>Logins of Expired requests<time> </H3> 

<table border = 1> 
<tr>
<th> Servername </th> <th> DBName </th> <th> Login </th></tr>'  

 if @xml is not null
 begin
SET @body =@date+ @body + @xml +'</table></body></html>'
end

else
begin
Set @body=@date+  ' <html><body><H3>No Expired logins<time> </H3>'
end

select @body

EXEC msdb.dbo.sp_send_dbmail
@profile_name='ADTAudit',
@recipients='CISADPInfraSupportTeam@cognizant.com',
@body = @body,
@body_format ='HTML',
@subject = 'ADT_Daily_audit' ;


END
END


--Exec [dbo].[FinalReport ]
GO
/****** Object:  StoredProcedure [dbo].[MI_Servers_Storage_Space_Report]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  StoredProcedure [dbo].[MI_Servers_Storage_Space_Report]    Script Date: 21-02-2023 5.10.03 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
------ =============================================
CREATE PROCEDURE [dbo].[MI_Servers_Storage_Space_Report]
	
AS
BEGIN
	 --SET NOCOUNT ON added to prevent extra result sets from
	 --interfering with SELECT statements.

--update MI_Servers_Storage_Space_Daily set [percent]	=
--(((Available_GB/(Total_TB*1024))*100))
----as 'percent' 
--from
--MI_Servers_Storage_Space_Daily 

CREATE TABLE #tempo(
 Servername nvarchar(200), total_TB Decimal(9,3), Used_TB decimal(9,3),Available_GB decimal(9,3) ,[percent] int 
)

INSERT INTO #tempo select * from MI_Servers_Storage_Space_Daily 

update #tempo set [percent]	=
(((Available_GB/(Total_TB*1024))*100))
--as 'percent' 
from
#tempo 

Select * From #tempo
 
Declare @date Nvarchar(MAX)
SET @date = GETDATE();
DECLARE @html varchar(MAX) = '
<table id="tablaPrincipal" border=2
<table border = 1> 
<tr style="background:#a7bfde;font-weight:bold;">                   
<th> Servername </th> <th> Total_TB </th> <th> Used_TB </th>   
<th> Available_GB </th> <th> Percent </th>                  
</tr>'SELECT @html =  @html + '<tr style="color:'+case when [percent] < 20 then 'red' else 'black' end +';"><td>'+
case when [percent] <10  then '<b>' else '' end +  
Servername + '</td><td>'+case when [percent] <10  then '<b>' else '' end    + cast(Total_TB as nvarchar(2000)) + '</td><td>'+case when [percent] <10  then '<b>' else '' end +cast(Used_TB as nvarchar(2000))
+ '</td> <td>' +case when [percent] <10  then '<b>' else '' end+cast(Available_GB as nvarchar(2000)) + '</td> <td>'+case when [percent] <10  then '<b>' else '' end  + cast([Percent] as nvarchar(2000)) +'</td> </tr>' 
FROM #tempo order by [percent] asc

--DECLARE @html varchar(MAX) = '<table id="tablaPrincipal" border=0>    
--<tr style="background:#a7bfde;font-weight:bold;">              
--<td>Servername</td>                        <td>Total_TB</td>     
--<td>Used_TB</td>                        <td>Available_GB</td>          
--<td>Percent</td>                 
--</tr>'SELECT @html = @html + '<tr  background= '+ case when [percent]>20  then 'red' else 'green' end
--+';"><td>' +  Servername + '</td><td>' + cast(Total_TB as nvarchar(2000)) + 
--'</td><td>' +cast(Used_TB as nvarchar(2000)) + '</td> <td>' +cast(Available_GB as nvarchar(2000))
--+ '</td> <td>' + cast([percent] as nvarchar(2000)) + '</td> </tr>' FROM #tempo
----bgcolor="black" style="font-weight:bold;color:white"
DROP TABLE #tempo

Select @html

EXEC msdb.dbo.sp_send_dbmail
@profile_name='ADTAudit',
@recipients='CISADPInfraSupportTeam@cognizant.com',
@body = @html,
@body_format ='HTML',
@subject = 'Daily_MI_Storage_Report' ;

END



--Exec [dbo].[FinalReport ]
GO
/****** Object:  StoredProcedure [dbo].[MI_Servers_Storage_Space_Report_notworking]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  StoredProcedure [dbo].[MI_Servers_Storage_Space_Report]    Script Date: 21-02-2023 5.10.03 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
---- =============================================
CREATE PROCEDURE [dbo].[MI_Servers_Storage_Space_Report_notworking]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.


update MI_Servers_Storage_Space_Daily set [percent]	=
(((Available_GB/(Total_TB*1024))*100))
--as 'percent' 
from
MI_Servers_Storage_Space_Daily 




BEGIN
	DECLARE @xml NVARCHAR(MAX)
	DECLARE @body NVARCHAR(MAX)
	Declare @date Nvarchar(MAX)



SET @xml = CAST(( SELECT [servername] AS 'td','',[Total_TB] AS 'td','', [Used_TB] AS 'td','',
[Available_GB] AS 'td','',[percent]  as 'td','' from
MI_Servers_Storage_Space_Daily 
FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

select @XML


--select floor(((Available_GB/(Total_TB*1024))*100)) as 'Percent',* from MI_Servers_Storage_Space_Daily


---SET @date = DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(YEAR, -3, GETDATE())) + 1, 0);
SET @date = GETDATE();

SET @body ='<html><body><H3>MI_Storage_Report<time> </H3> 

<table border = 1> 
<tr>
<th> Servername </th> <th> Total_TB </th> <th> Used_TB </th><th> Available_GB </th> <th> Free space in % </th>
</tr>'  

 if @xml is not null
 begin
SET @body =@date+ @body + @xml +'</table></body></html>'
end

--else
--begin
--Set @body=@date+  ' <html><body><H3>No Invalid Logins <time> </H3>'
--end

select @body

EXEC msdb.dbo.sp_send_dbmail
@profile_name='ADTAudit',
@recipients='sukanya.subbiah@cognizant.com',
@body = @body,
@body_format ='HTML',
@subject = 'MI_Storage_Report' ;


END
END


--Exec [dbo].[FinalReport ]
GO
/****** Object:  StoredProcedure [dbo].[MI_Servers_Storage_Space_Report_notworking2]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create PROCEDURE [dbo].[MI_Servers_Storage_Space_Report_notworking2]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.


update MI_Servers_Storage_Space_Daily set [percent]	=
(((Available_GB/(Total_TB*1024))*100))
--as 'percent' 
from
MI_Servers_Storage_Space_Daily 



BEGIN
	DECLARE @xml NVARCHAR(MAX)
	DECLARE @body NVARCHAR(MAX)
	Declare @date Nvarchar(MAX)



SET @xml = CAST(( SELECT [servername] AS 'td','',[Total_TB] AS 'td','', [Used_TB] AS 'td','',
[Available_GB] AS 'td','',[percent]  as 'td','' from
MI_Servers_Storage_Space_Daily 
FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

select @XML


--select floor(((Available_GB/(Total_TB*1024))*100)) as 'Percent',* from MI_Servers_Storage_Space_Daily


---SET @date = DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(YEAR, -3, GETDATE())) + 1, 0);
SET @date = GETDATE();

SET @body ='<html><body><H3>MI_Storage_Report<time> </H3> 

<table border = "1" width="100%"> 
<tr bgcolor="black" style="font-weight:bold;color:white" 

--<tr Space="red" style="font-weight:bold;color:white">

<th> Servername </th> <th> Total_TB </th> <th> Used_TB </th><th> Available_GB </th> <th> Free space in % </th>
</tr>'  


SELECT @Body = @body+'<tr ' + 'bgcolor='

FROM [MI_Servers_Storage_Space_Daily] 


--WHERE [percent] >20 + 'Space='

 --where [percent] < 20          
 --style="border-spacing: 0px;border-collapse:collapse ;
 --border:1px solid #D0D0CE;color:red;font-weight:bold"> 
 
 --<xsl:value-of select="WBStatus" />       
 --</td>

ORDER BY [percent] asc


 if @xml is not null
 begin
SET @body =@date+ @body + @xml +'</table></body></html>'
end



EXEC msdb.dbo.sp_send_dbmail
@profile_name='ADTAudit',
@recipients='sukanya.subbiah@cognizant.com',
@body = @body,
@body_format ='HTML',
@subject = 'MI_Storage_Report' ;


END
END


--Exec [dbo].[FinalReport ]
GO
/****** Object:  StoredProcedure [dbo].[MIReplStatus_SP]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Sukanya Subbiah
-- Create date: FEb 2023
-- Description: Return all members
-- =============================================
--Store procedure name is --> stpGetAllMembers
CREATE PROCEDURE [dbo].[MIReplStatus_SP]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

 DECLARE @tableHTML NVARCHAR(MAX) ;
SET @tableHTML =
N'<H3 align = "Left"><font face="verdana" color="green" size = "2">Transactional 
Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = 
"2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last 
Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM dbo.MIReplStatus
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' ;

declare @email2 varchar(100)

SELECT @email2 = [email_address] FROM [msdb].[dbo].[sysoperators] where name = 
'MIReplstatus'

EXEC msdb.dbo.sp_send_dbmail @recipients=@email2,
    @subject = 'MI Replication Status Report',
	  @profile_name = 'CRS',
    @body = @tableHTML,
    @body_format = 'HTML' ;




  
END
GO
/****** Object:  StoredProcedure [dbo].[PRODReplStatus_SP]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,sukanya>
-- Create date: <August 2,2023,,>
-- Description:	<PRODReplStatus_SP,,>
-- =============================================
CREATE PROCEDURE [dbo].[PRODReplStatus_SP] 
--	-- Add the parameters for the stored procedure here
--	<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
--	<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @tableHTML NVARCHAR(MAX) ;
SET @tableHTML =

N'<H3 align = "Left"><font face="verdana" color="green" size = "2">CRSMAS MI Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
 FROM Prod_Replication_Status where publisher_db in  ('CentralRepository','ent_data_store_sub')
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' +


N'<H3 align = "Left"><font face="verdana" color="green" size = "2">EDS MI Replication Status Report:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM Prod_Replication_Status where publisher_db like 'ent_data_store'
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' 



--N'<H3 align = "Left"><font face="verdana" color="green" size = "2">Clearance-EDS Replication Status:</font></H3>' +
--N'<table border="1">' +
--N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
--N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
--CAST ( ( SELECT td =Publication, '',
--td = subscriber, '',
--td = CASE status 
--WHEN 1 THEN 'Started'
--WHEN 2 THEN 'Succeed'
--WHEN 3 THEN 'In progress'
--WHEN 4 THEN 'Idle'
--WHEN 5 THEN 'Retrying'
--WHEN 6 THEN 'Failed'
--END,'',
--td = CAST(latency as VARCHAR(50)), '',
--td = CAST(last_distsync as varchar(100)), ''
--FROM Prod_Replication_Status where subscriber_db like '%OneC_Clearance%'
--FOR XML PATH('tr'), TYPE 
--) AS NVARCHAR(MAX) ) +
--N'</font></table>' +


--N'<H3 align = "Left"><font face="verdana" color="green" size = "2">RHMS-EDS Replication Status:</font></H3>' +
--N'<table border="1">' +
--N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
--N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
--CAST ( ( SELECT td =Publication, '',
--td = subscriber, '',
--td = CASE status 
--WHEN 1 THEN 'Started'
--WHEN 2 THEN 'Succeed'
--WHEN 3 THEN 'In progress'
--WHEN 4 THEN 'Idle'
--WHEN 5 THEN 'Retrying'
--WHEN 6 THEN 'Failed'
--END,'',
--td = CAST(latency as VARCHAR(50)), '',
--td = CAST(last_distsync as varchar(100)), ''
--FROM Prod_Replication_Status where subscriber_db like '%OneC_2090%'
--FOR XML PATH('tr'), TYPE 
--) AS NVARCHAR(MAX) ) +
--N'</font></table>' ;

Print @tableHTML

declare @email2 varchar(100)

SELECT @email2 = [email_address] FROM [msdb].[dbo].[sysoperators] where name = 'MI_Repl_Status'

EXEC msdb.dbo.sp_send_dbmail @recipients=@email2,
    @subject = 'MI Replication Status Report',
	  @profile_name = 'crsdba_adt',
    @body = @tableHTML,
    @body_format = 'HTML' ;

--	EXEC msdb.dbo.sp_send_dbmail
--@profile_name='ADTAudit',
--@recipients='CISADPInfraSupportTeam@cognizant.com',
--@body = @tableHTML,
--@body_format ='HTML',
--@subject = 'ADT_Weekly_Audit' ;
END
GO
/****** Object:  StoredProcedure [dbo].[PRODReplStatus_SP_tesing]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,sukanya>
-- Create date: <August 2,2023,,>
-- Description:	<PRODReplStatus_SP,,>
-- =============================================
CREATE PROCEDURE [dbo].[PRODReplStatus_SP_tesing] 
--	-- Add the parameters for the stored procedure here
--	<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
--	<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @tableHTML NVARCHAR(MAX) ;
SET @tableHTML =

N'<H3 align = "Left"><font face="verdana" color="green" size = "2">CRSMAS MI Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
 FROM Prod_Replication_Status where publisher_db in  ('CentralRepository','ent_data_store_sub')
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' +


N'<H3 align = "Left"><font face="verdana" color="green" size = "2">EDS MI Replication Status Report:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM Prod_Replication_Status where publisher_db like 'ent_data_store'
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' +



N'<H3 align = "Left"><font face="verdana" color="green" size = "2">Clearance-EDS Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM Prod_Replication_Status where subscriber_db like '%OneC_Clearance%'
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' +


N'<H3 align = "Left"><font face="verdana" color="green" size = "2">RHMS-EDS Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM Prod_Replication_Status where subscriber_db like '%OneC_2090%'
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' ;

Print @tableHTML

declare @email2 varchar(100)

SELECT @email2 = [email_address] FROM [msdb].[dbo].[sysoperators] where name = 'CISADP'

EXEC msdb.dbo.sp_send_dbmail @recipients=@email2,
    @subject = 'MI Replication Status Report',
	  @profile_name = 'crsdba_adt',
    @body = @tableHTML,
    @body_format = 'HTML' ;

--	EXEC msdb.dbo.sp_send_dbmail
--@profile_name='ADTAudit',
--@recipients='CISADPInfraSupportTeam@cognizant.com',
--@body = @tableHTML,
--@body_format ='HTML',
--@subject = 'ADT_Weekly_Audit' ;
END
GO
/****** Object:  StoredProcedure [dbo].[Replication_DB_Size_Monitoring_dailymailer]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
---- =============================================
CREATE PROCEDURE [dbo].[Replication_DB_Size_Monitoring_dailymailer] 
--	---- Add the parameters for the stored procedure here
--	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
--	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
truncate table  Daily_Space_monitor_Today
truncate table  Daily_Space_monitor_Yesterday


IF OBJECT_ID('tempdb..#temp') IS NOT NULL
	Drop table #temp

declare @Today_DBsize VARCHAR(100)
declare @Yesterday_DBsize VARCHAR(100)

 set @Today_DBsize =convert(date,getdate())
 set @Yesterday_DBsize =convert(date,getdate()-1)

------------

Select * From Daily_Space_monitor_Yesterday
Select * From Daily_Space_monitor_Today

insert into Daily_Space_monitor_Today SELECT Datetime,Servername,name,size_GBs FROM 
 [dbo].[CRS_MI_Daily_Helpdb_space] WHERE 
 [Servername] in ('ctsazsimicrsmas.inso1a101c37461fa.database.windows.net','CTSINTBMCRSDIST\CRSREP','CTSINTCOSEADB8') and
 name in ('distribution','CentralRepository','ent_data_store_sub') 
 and  cast ([Datetime] as date)=convert(date,getdate()) order by Datetime desc


 insert into Daily_Space_monitor_Yesterday SELECT Datetime,Servername,name,size_GBs FROM 
 [dbo].[CRS_MI_Daily_Helpdb_space] WHERE 
 [Servername] in ('ctsazsimicrsmas.inso1a101c37461fa.database.windows.net','CTSINTBMCRSDIST\CRSREP','CTSINTCOSEADB8') and
 name in ('distribution','CentralRepository','ent_data_store_sub') 
 and  cast ([Datetime] as date)=convert(date,getdate()-1) order by Datetime desc

--------INSERT INTO Daily_Space_monitor_Today (Datetime,Servername,name,size_GBs)
--------SELECT Datetime,Servername,name,size_GBs
--------FROM (
--------    SELECT *,
--------           ROW_NUMBER() OVER (ORDER BY Datetime DESC) AS rn
--------    FROM CRS_MI_Daily_Helpdb_space
--------     WHERE [Servername] in ('ctsazsimicrsmas.inso1a101c37461fa.database.windows.net','CTSINTBMCRSDIST\CRSREP','CTSINTCOSEADB8') and
--------name in ('distribution','CentralRepository','ent_data_store_sub')
--------) AS FilteredRecords 
----------order by datetime desc
--------WHERE rn <= 5 and   cast ([Datetime] as Date)=convert(date,getdate());


--------INSERT INTO Daily_Space_monitor_Yesterday (Datetime,Servername,name,size_GBs)
--------SELECT Datetime,Servername,name,size_GBs
--------FROM (
--------    SELECT *,
--------           ROW_NUMBER() OVER (ORDER BY Datetime DESC) AS rn
--------    FROM CRS_MI_Daily_Helpdb_space
--------     WHERE [Servername] in ('ctsazsimicrsmas.inso1a101c37461fa.database.windows.net','CTSINTBMCRSDIST\CRSREP','CTSINTCOSEADB8') and
--------name in ('distribution','CentralRepository','ent_data_store_sub')
--------) AS FilteredRecords
--------WHERE 
----------rn <= 5 and
--------Datetime >= DATEADD(day, -1, convert(date, GETDATE()))

 --insert into Daily_Space_monitor_Yesterday SELECT Datetime,Servername,name,size_GBs FROM 
 --[dbo].[CRS_MI_Daily_Helpdb_space] WHERE 
 --[Servername] in ('ctsazsimicrsmas.inso1a101c37461fa.database.windows.net','CTSINTBMCRSDIST\CRSREP','CTSINTCOSEADB8') and
 --name in ('distribution','CentralRepository','ent_data_store_sub')   
 --and  cast ([Datetime] as date)=convert(date,getdate()-1)
------ CREATE TABLE #temp(
------ Servername nvarchar(128), dbname nvarchar(128), Yesterday_DBsize decimal(10,2), Today_DBsize decimal(10,2)
------)
------ Insert into #temp
------seLECT t.servername as servername ,t.name as dbname,t.size_gbs as Yesterday_DBsize,d.size_gbs as Today_DBsize  FROM Daily_Space_monitor_new t 

------ inner join [ADT_Audit].[dbo].Daily_Space_monitor d on  d.servername=t.Servername
 --SELECT SUM(Yesterday_DBsize-Today_DBsize) AS [Space_difference]
 --from #temp

-- Select * From Daily_Space_monitor_Yesterday
--Select * From Daily_Space_monitor_Today

  --select servername,dbname,Yesterday_DBsize, Today_DBsize, Yesterday_DBsize-Today_DBsize as [Difference] from #temp


 CREATE TABLE #temp(
Servername nvarchar(128), dbname nvarchar(128), Yesterday_DBsize decimal(10,2), Today_DBsize decimal(10,2),Difference INT
)
Insert into #temp (Servername,dbname,Yesterday_DBsize,Today_DBsize )

seLECT t.servername as servername ,t.name as dbname, d.size_gbs as Yesterday_DBsize ,t.size_gbs as Today_DBsize  FROM Daily_Space_monitor_Today t   

inner join [ADT_Audit].[dbo].Daily_Space_monitor_Yesterday d on  d.servername=t.Servername and d.[name]=t.[name] 
  select servername,dbname,Yesterday_DBsize, Today_DBsize, Today_DBsize-Yesterday_DBsize as [Difference] from #temp

  --Select * from #temp
update #temp set [difference]=(Today_DBsize-Yesterday_DBsize) 
--as 'percent' 
 BEGIN
	DECLARE @xml NVARCHAR(MAX)
	DECLARE @body NVARCHAR(MAX)
	Declare @date Nvarchar(MAX)


SET @xml = CAST(( SELECT [Servername] AS 'td','',[DBname] AS 'td','', [Yesterday_DBsize] AS 'td','',[Today_DBsize] AS 'td','',[Difference] AS 'td','' from #temp

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))
---SET @date = DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(YEAR, -3, GETDATE())) + 1, 0);


SET @body ='<html>

<table border = 1> 
<tr>
<th> Servername </th> <th> DBName </th> <th>'+@Yesterday_DBsize+'</th> <th> '+@Today_DBsize+'</th> <th> Difference </th>
 </tr>'  

 if @xml is not null
 begin
SET @body = @body + @xml +'</table></body></html>'
end

select @body

EXEC msdb.dbo.sp_send_dbmail
@profile_name='ADTAudit',
@recipients='CISADPInfraSupportTeam@cognizant.com',
@body = @body,
@body_format ='HTML',
@subject ='Replication_DB_size';


END


END
GO
/****** Object:  StoredProcedure [dbo].[Replication_DB_Size_Monitoring_dailymailer_old]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
---- =============================================
CREATE PROCEDURE [dbo].[Replication_DB_Size_Monitoring_dailymailer_old] 
	---- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
truncate table  Daily_Space_monitor_Today
truncate table  Daily_Space_monitor_Yesterday


IF OBJECT_ID('tempdb..#temp') IS NOT NULL
	Drop table #temp

declare @Today_DBsize VARCHAR(100)
declare @Yesterday_DBsize VARCHAR(100)

 set @Today_DBsize =convert(date,getdate())
 set @Yesterday_DBsize =convert(date,getdate()-1)

------------

Select * From Daily_Space_monitor_Yesterday
Select * From Daily_Space_monitor_Today

insert into Daily_Space_monitor_Today SELECT Datetime,Servername,name,size_GBs FROM 
 [dbo].[CRS_MI_Daily_Helpdb_space] WHERE 
 [Servername] in ('ctsazsimicrsmas.inso1a101c37461fa.database.windows.net','CTSINTBMCRSDIST\CRSREP','CTSINTCOSEADB8') and
 name in ('distribution','CentralRepository','ent_data_store_sub') 
 and  cast ([Datetime] as date)=convert(date,getdate())


 insert into Daily_Space_monitor_Yesterday SELECT Datetime,Servername,name,size_GBs FROM 
 [dbo].[CRS_MI_Daily_Helpdb_space] WHERE 
 [Servername] in ('ctsazsimicrsmas.inso1a101c37461fa.database.windows.net','CTSINTBMCRSDIST\CRSREP','CTSINTCOSEADB8') and
 name in ('distribution','CentralRepository','ent_data_store_sub')   
 and  cast ([Datetime] as date)=convert(date,getdate()-1)
------ CREATE TABLE #temp(
------ Servername nvarchar(128), dbname nvarchar(128), Yesterday_DBsize decimal(10,2), Today_DBsize decimal(10,2)
------)
------ Insert into #temp
------seLECT t.servername as servername ,t.name as dbname,t.size_gbs as Yesterday_DBsize,d.size_gbs as Today_DBsize  FROM Daily_Space_monitor_new t 

------ inner join [ADT_Audit].[dbo].Daily_Space_monitor d on  d.servername=t.Servername
 --SELECT SUM(Yesterday_DBsize-Today_DBsize) AS [Space_difference]
 --from #temp

-- Select * From Daily_Space_monitor_Yesterday
--Select * From Daily_Space_monitor_Today

  --select servername,dbname,Yesterday_DBsize, Today_DBsize, Yesterday_DBsize-Today_DBsize as [Difference] from #temp


 CREATE TABLE #temp(
Servername nvarchar(128), dbname nvarchar(128), Yesterday_DBsize decimal(10,2), Today_DBsize decimal(10,2),Difference INT
)
Insert into #temp (Servername,dbname,Yesterday_DBsize,Today_DBsize )

seLECT t.servername as servername ,t.name as dbname, d.size_gbs as Yesterday_DBsize ,t.size_gbs as Today_DBsize  FROM Daily_Space_monitor_Today t   

inner join [ADT_Audit].[dbo].Daily_Space_monitor_Yesterday d on  d.servername=t.Servername and d.[name]=t.[name] 
  select servername,dbname,Yesterday_DBsize, Today_DBsize, Today_DBsize-Yesterday_DBsize as [Difference] from #temp

  --Select * from #temp
update #temp set [difference]=(Today_DBsize-Yesterday_DBsize) 
--as 'percent' 
 BEGIN
	DECLARE @xml NVARCHAR(MAX)
	DECLARE @body NVARCHAR(MAX)
	Declare @date Nvarchar(MAX)


SET @xml = CAST(( SELECT [Servername] AS 'td','',[DBname] AS 'td','', [Yesterday_DBsize] AS 'td','',[Today_DBsize] AS 'td','',[Difference] AS 'td','' from #temp

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))
---SET @date = DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(YEAR, -3, GETDATE())) + 1, 0);


SET @body ='<html>

<table border = 1> 
<tr>
<th> Servername </th> <th> DBName </th> <th>'+@Yesterday_DBsize+'</th> <th> '+@Today_DBsize+'</th> <th> Difference </th>
 </tr>'  

 if @xml is not null
 begin
SET @body = @body + @xml +'</table></body></html>'
end

select @body

EXEC msdb.dbo.sp_send_dbmail
@profile_name='ADTAudit',
@recipients='CISADPInfraSupportTeam@cognizant.com',
@body = @body,
@body_format ='HTML',
@subject ='Replication_DB_size';


END


END
GO
/****** Object:  StoredProcedure [dbo].[Replication_Latency_new]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/****** Object:  StoredProcedure [dbo].[MI_Servers_Storage_Space_Report]    Script Date: 21-02-2023 5.10.03 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
------ =============================================
CREATE PROCEDURE [dbo].[Replication_Latency_new]
	
AS
BEGIN
delete  FROM Replication_Lag_MI WHERE DATEDIFF(day,getdate(),datetime) < -45
Declare @date Nvarchar(MAX)
SET @date = GETDATE();
Declare @length int
DECLARE @body NVARCHAR(MAX)
SET @body ='<html><body><H3>Replication Latency with DR<time> </H3>'
DECLARE @html Nvarchar(MAX) = 
'
<table id="tablaPrincipal" border=2
<table border = 1> 
<tr> 
<th> Servername </th> <th> DatabaseName </th> 
 <th> Synchronization_state </th> <th> Synchronization_health </th> <th> lag_in_seconds </th> <th> last_commit_time </th></tr>' 
 SELECT @html =  @html + '<tr style="color:red;"><td>'+[servername] + '</td><td>'+[DatabaseName]+ '</td><td>'+ [synchronization_state_desc]+ '</td><td>' +[synchronization_health_desc] + '</td><td>'+ case when lag_in_seconds is null then CAST(0 AS VARCHAR(max))  else CAST(Lag_in_seconds AS VARCHAR(max)) end+'</td><td>'+Convert(Varchar,last_commit_time,120)+'</td></tr>'
from Replication_Lag_MI where synchronization_state_desc like'%NOT%'
and last_commit_time >DATEADD(minute, -59, GETDATE())
--= '2023-08-01 11:01:10.620'


Set @length= Len(@html)
SET @body =@date+ @body + @html +'</table></body></html>'

Print @length 
Print @html
if @length >250
begin
EXEC msdb.dbo.sp_send_dbmail
@profile_name='ADTAudit',
@recipients='Sukanya.Subbiah@cognizant.com;tharani.ravindran@cognizant.com',
@body = @body,
@body_format ='HTML',
@subject = 'Replication_Latency' ;

END
End



--Exec [dbo].[FinalReport ]
GO
/****** Object:  StoredProcedure [dbo].[Replication_Latency_notworking]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Replication_Latency_notworking]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	DECLARE @xml NVARCHAR(MAX)
	DECLARE @body NVARCHAR(MAX)
	Declare @date Nvarchar(MAX)



SET @xml = CAST(( SELECT [servername] AS 'td','',[DatabaseName] AS 'td',
'', [synchronization_state_desc] AS 'td',
'', [synchronization_health_desc] AS 'td',
'', [lag_in_seconds] AS 'td',
'', [last_commit_time] AS 'td'
from
Replication_Lag_MI where synchronization_state_desc ='NOT SYNCHRONIZING'  and convert(date,last_commit_time) =convert(date,getdate())


FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))
---SET @date = DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(YEAR, -3, GETDATE())) + 1, 0);
SET @date = GETDATE();

SET @body ='<html><body><H3>Replication Latency with DR<time> </H3> 

<table border = 1> 
<tr bgcolor="red"> 
<th> Servername </th> <th> DatabaseName </th> 
 <th> Synchronization_state </th> <th> Synchronization_health </th>
  <th> lag_in_seconds </th> <th> last_commit_time </th> 
  </tr>' 

  print @xml 
 if @xml is not null
 begin
SET @body =@date+ @body + @xml +'</table></body></html>'

EXEC msdb.dbo.sp_send_dbmail
@profile_name='ADTAudit',
@recipients='Sukanya.Subbiah@cognizant.com',
@body = @body,
@body_format ='HTML',
@subject = 'Replication_Latency' ;
end

--else
----begin
----Set @body=@date+  ' <html><body><H3>No Latency<time> </H3>'
----end

--select @body


END
End

GO
/****** Object:  StoredProcedure [dbo].[Required_non_prod]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Required_non_prod]
	
AS
BEGIN
	
--To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  

update [dbo].[Required_nonprod_dbspace] set Size_GBs=cast(size_mbs as decimal(10,4))/1024


declare @sql varchar(8000)
declare @sql1 varchar(8000)
--select @sql = 'bcp "select ''servername'',''DBName'',''FileName'',''Type_desc'',''CurrentSizeMB'',''FreeSpaceMB''union all select convert(nvarchar(128),[Servername]),convert(nvarchar(128),[DBName]),convert(nvarchar(128),[FileName]),Convert(nvarchar(128),[Type_Desc]),Convert(nvarchar(128),[CurrentSizeMB]),Convert(nvarchar(128),[FreeSpaceMB]) FROM ADT_Audit..CRS_MI_WeeklySpace" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Datafilesizedetails.csv -c -t, -T -S' + @@servername
select @sql1 = 'bcp "select ''Datetime'',''servername'',''Name'',''Size_MBs'',''Size_GBs''union all select convert(nvarchar(128),[Datetime]),convert(nvarchar(128),[Servername]),convert(nvarchar(128),[Name]),Convert(nvarchar(128),[Size_MBs]),Convert(nvarchar(128),[Size_GBs]) FROM ADT_Audit..Required_nonprod_dbspace" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Size_nonprod.csv -c -t, -T -S'+ @@servername
----bcp "select 'SalesOrderID', 'CarrierTrackingNumber','ModifiedDate','UpdateTime' union all SELECT 
----convert(varchar(20),[SalesOrderID]),convert(varchar(20),[CarrierTrackingNumber]),CONVERT(nvarchar(30), 
--[ModifiedDate], 120),CONVERT(nvarchar(30), [UpdateTime], 120) FROM [testdb].[dbo].[SalesOrderDetailIn]" 
--queryout D:\People.txt -t, -c -T  


----sqlcmd -s, -W -Q "set nocount on; select * from [DATABASE].[dbo].[TABLENAME]" | findstr /v /c:"-" /b > "c:\dirname\file.csv"


exec master..xp_cmdshell @sql
exec master..xp_cmdshell @sql1
 


DECLARE @filenames varchar(max)
DECLARE @file1 VARCHAR(MAX) = '\\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Datafilesizedetails.csv'
DECLARE @file2 VARCHAR(MAX) = ';\\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Size_nonprod.csv'
--DECLARE @file3 VARCHAR(MAX) = ';C:\Testfiles\Test3.csv'

 

-- Create list from optional files
SELECT @filenames = @file1 + @file2



 

-- Send the email
EXEC msdb.dbo.sp_send_dbmail
  @profile_name = 'adtaudit',

  @recipients= 'sukanya.subbiah@cognizant.com',
  @subject = 'Nonprod_dbsize',
  @body= 'Hi Team,
Weekly MI DB size report has been attached',
  @file_attachments = @filenames

END


GO
/****** Object:  StoredProcedure [dbo].[USP_CPU_Utilization_Status]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



      
    
CREATE  PROCEDURE [dbo].[USP_CPU_Utilization_Status]      
       
AS      
BEGIN      

	DECLARE @tableHTML NVARCHAR(MAX) ;
SET @tableHTML =

N'<H3 align = "Left"><font face="verdana" color="green" size = "2">CRSMAS MI Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
 FROM Prod_Replication_Status where publisher_db in  ('CentralRepository','ent_data_store_sub')
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' +


N'<H3 align = "Left"><font face="verdana" color="green" size = "2">EDS MI Replication Status Report:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM Prod_Replication_Status where publisher_db like 'ent_data_store'
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' +



N'<H3 align = "Left"><font face="verdana" color="green" size = "2">Clearance-EDS Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM Prod_Replication_Status where subscriber_db like '%OneC_Clearance%'
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' +


N'<H3 align = "Left"><font face="verdana" color="green" size = "2">RHMS-EDS Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM Prod_Replication_Status where subscriber_db like '%OneC_2090%'
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' ;

Print @tableHTML
-------------------[CPU_Utilization_Status]  -----------------
     
      
CREATE TABLE #temp(      
 [Server_Type] [varchar](200) NULL,[Server_Name] [varchar](200) NULL,[Status] [varchar](200) NULL,CPU_Utilization_Percent  [varchar](200)
);     

INSERT INTO #temp select * from [CPU_Utilization_Status]       
      
       
      
Select * From #temp with(nolock)  
       
Declare @date Nvarchar(MAX) = convert(nvarchar,getdate(),101);     
--SET @date = GETDATE();      
DECLARE @html varchar(MAX) = '     
<p>     
Hi Team,     
<br>Please find the below Production CPU Utilization Status.<br>     
<br> <br>    
</p>    
<style>  
  
table, td, th {  
border:1px solid black;  
border-collapse: collapse;  
font-family:Serif;}  
th {  
padding:10px;  
text-align: center;  
vertical-align: middle;}  
</style>  
<table id="tablaPrincipal"      
<tr style="background:#87ceeb;; font-style:initial;style="height:80">                         
<th> Server_Type </th>   
<th> Server_Name </th>   
<th> Status </th>         
<th> CPU_Utilization_Percent </th>                       
</tr>  
'SELECT @html =  @html +   
'<td style="text-align: Center;">'+ Server_Type +'</td>  
<td style="text-align: Center;">'+ Server_Name + '</td>  
<td style="text-align: Center;">'+ Status  + '</td>   
<td style="text-align: Center;">'+ CPU_Utilization_Percent  + '</td>    
</tr>'    
FROM #temp with(nolock)  ORDER BY CPU_Utilization_Percent DESC
      
 
DROP TABLE #temp  

Select @html
--------------------DESQLJOBS------------------
--To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  




declare @sql varchar(8000)


select @sql = 'bcp "select  ''servername'',''jobname'',''outcome'',''Lastrundate'' union all select convert(nvarchar(128),[Servername]),convert(nvarchar(128),isnull([jobname],'''')),convert(nvarchar(128),isnull([outcome],'''')),Convert(nvarchar(128),isnull([LastRunDatetime],'' ''))  FROM ADT_Audit..DE_SQL_jobs" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\DE_SQLjobs\DE_SQLjobs.csv -c -t, -T -S'+ @@Servername;

exec master..xp_cmdshell @sql

DECLARE @filenames varchar(max)
DECLARE @file1 VARCHAR(MAX) = '\\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\DE_SQLjobs\DE_SQLjobs.csv'

SELECT @filenames = @file1 


      
  

declare @email2 varchar(100)

SELECT @email2 = [email_address] FROM [msdb].[dbo].[sysoperators] where name = 'CISADP'
DECLARE @BODY NVARCHAR(MAX)
      SET @BODY =  @tableHTML+@html
EXEC msdb.dbo.sp_send_dbmail      
 @profile_name = 'adtaudit',      
@recipients='sukanya.subbiah@cognizant.com',      
@body = @BODY,      
@body_format ='HTML', 
  @file_attachments = @filenames,
@subject = 'Daily Replication ,CPU utilization status and DE SQL jobs' ;      
      
END      


-------------[dbo].[USP_CPU_Utilization_Status] 
       
GO
/****** Object:  StoredProcedure [dbo].[USP_Ispace_app_Jobs_Status]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
           
CREATE PROCEDURE [dbo].[USP_Ispace_app_Jobs_Status]        
         
AS        
BEGIN        
  
CREATE TABLE #temp(        
   [Job_name] [nvarchar](200),[Run_status] [nvarchar](200),[DurationHHMMSS] [nvarchar](200),[Start_date] [nvarchar](200),  
);        
    
INSERT INTO #temp select * from [Ispace_app_Jobs_Status]         
        
         
        
Select * From #temp with(nolock)    
         
Declare @date Nvarchar(MAX) = convert(nvarchar,getdate(),101);       
SET @date = GETDATE();        
DECLARE @html varchar(MAX) = '       
<p>       
Hi Team,       
<br>Please find the below Production Ispace app Jobs Status.<br>       
<br> <br>      
</p>      
<style>    
    
table, td, th {    
border:1px solid black;    
border-collapse: collapse;    
font-family:Serif;}    
th {    
padding:10px;    
text-align: center;    
vertical-align: middle;}    
</style>    
<table id="tablaPrincipal"        
<tr style="background:#87ceeb;; font-style:initial;style="height:80">                           
<th> Job_name </th>     
<th> Run_status </th>     
<th> DurationHHMMSS </th>           
<th> Start_date </th>                      
</tr>    
'SELECT @html =  @html +     
  
'<td style="text-align: Center;">'+ Job_name +'</td>    
<td style="text-align: Center;">'+ Run_status + '</td>    
<td style="text-align: Center;">'+ DurationHHMMSS  + '</td>     
<td style="text-align: Center;">'+ Start_date  + '</td>    
</tr>'      
FROM #temp with(nolock)         
        
       
DROP TABLE #temp        
        
Select @html        
        
EXEC msdb.dbo.sp_send_dbmail        
@profile_name='ADTAUDIT',         
@recipients = 'CISADPInfraSupportTeam@cognizant.com;malarmannan.ksp@cognizant.com;chayan.bag2@cognizant.com',  
@body = @html,        
@body_format ='HTML',        
@subject = 'Prod_Ispace_app_Jobs_Status' ;        
        
END        
         
GO
/****** Object:  StoredProcedure [dbo].[Weekly_DB_Space_new]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Weekly_DB_Space_new]
	
AS
BEGIN
	
--To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  

update [dbo].[CRS_MI_WeeklySpace_Helpdb_Weeklydata] set Size_GBs=cast(size_mbs as decimal(10,2))/1024



declare @sql varchar(8000)
declare @sql1 varchar(8000)
select @sql = 'bcp "select ''servername'',''DBName'',''FileName'',''Type_desc'',''CurrentSizeMB'',''FreeSpaceMB''union all select convert(nvarchar(128),[Servername]),convert(nvarchar(128),[DBName]),convert(nvarchar(128),[FileName]),Convert(nvarchar(128),[Type_Desc]),Convert(nvarchar(128),[CurrentSizeMB]),Convert(nvarchar(128),[FreeSpaceMB]) FROM ADT_Audit..CRS_MI_WeeklySpace" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Datafilesizedetails.csv -c -t, -T -S' + @@servername
select @sql1 = 'bcp "select ''Datetime'',''servername'',''Name'',''Size_MBs'',''Size_GBs''union all select convert(nvarchar(128),[Datetime]),convert(nvarchar(128),[Servername]),convert(nvarchar(128),[Name]),Convert(nvarchar(128),[Size_MBs]),Convert(nvarchar(128),[Size_GBs]) FROM ADT_Audit..CRS_MI_WeeklySpace_Helpdb_Weeklydata" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Size.csv -c -t, -T -S'+ @@servername
----bcp "select 'SalesOrderID', 'CarrierTrackingNumber','ModifiedDate','UpdateTime' union all SELECT 
----convert(varchar(20),[SalesOrderID]),convert(varchar(20),[CarrierTrackingNumber]),CONVERT(nvarchar(30), 
--[ModifiedDate], 120),CONVERT(nvarchar(30), [UpdateTime], 120) FROM [testdb].[dbo].[SalesOrderDetailIn]" 
--queryout D:\People.txt -t, -c -T  


----sqlcmd -s, -W -Q "set nocount on; select * from [DATABASE].[dbo].[TABLENAME]" | findstr /v /c:"-" /b > "c:\dirname\file.csv"


exec master..xp_cmdshell @sql
exec master..xp_cmdshell @sql1
 


DECLARE @filenames varchar(max)
DECLARE @file1 VARCHAR(MAX) = '\\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Datafilesizedetails.csv'
DECLARE @file2 VARCHAR(MAX) = ';\\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Size.csv'
--DECLARE @file3 VARCHAR(MAX) = ';C:\Testfiles\Test3.csv'

 

-- Create list from optional files
SELECT @filenames = @file1 + @file2



 

-- Send the email
EXEC msdb.dbo.sp_send_dbmail
  @profile_name = 'adtaudit',

  @recipients= 'CISADPInfraSupportTeam@cognizant.com',
  @subject = 'CRS_MI_DBSize_Report_Weekly',
  @body= 'Hi Team,
Weekly MI DB size report has been attached',
  @file_attachments = @filenames

END


GO
/****** Object:  StoredProcedure [dbo].[Weekly_DB_Space_notworking]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Weekly_DB_Space_notworking]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.



BEGIN
	DECLARE @xml NVARCHAR(MAX)
	DECLARE @body NVARCHAR(MAX)


SET @xml = CAST(( SELECT [servername] AS 'td','',[dbname] AS 'td'
,'', [FileName] AS 'td'
,'', [type_desc] AS 'td'
,'',[CurrentSizeMB] AS 'td'
,'', [FreeSpaceMB] AS 'td'
from
CRS_MI_WeeklySpace


FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))
---SET @date = DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(YEAR, -3, GETDATE())) + 1, 0);


SET @body ='<html><body><H3>CRS_MI_DBSize_Report_Weekly<time> </H3> 

<table border = 1> 
<tr>
<th> Servername </th> <th> DBName </th> <th> FileName </th>'
----<th> type_desc </th><th> CurrentSizeMB </th>
----<th> CurrentSizeMB </th>FreeSpaceMB</tr>'  

 
SET @body = @body + @xml +'</table></body></html>'


EXEC msdb.dbo.sp_send_dbmail

@recipients='sukanya.Subbiah@cognizant.com',

@body= 'Weekly_databasegrowth MI Instance',

@subject = 'CRS_MI_DBSize_Report_Weekly',

@profile_name ='ADTAudit' ,

@query = '@table',


@execute_query_database = 'ADT_Audit',

@attach_query_result_as_file = 2 ,

@query_result_separator = '	',

@query_result_no_padding = 1,

@query_result_header =1,

@query_attachment_filename = 'CRS_MI_DBSize_Report_Weekly.csv';



--EXEC msdb.dbo.sp_send_dbmail
--@profile_name='ADTAudit',
--@recipients='sukanya.subbiah@cognizant.com',
--@body = 'Weekly_databasegrowth MI Instance',
----@body_format ='HTML',
--    @query = 'SELECT * FROM CRS_MI_WeeklySpace;',
--    @execute_query_database = 'ADT_Audit',
--    @attach_query_result_as_file = 1,
--    @query_attachment_filename = 'Weekly_Databasesize.csv',
--	@query_result_separator =' char(9)',
--	@query_result_width =32767,
--@query_result_no_padding=1,
--@subject = 'CRS_MI_DBSize_Report_Weekly' ;


END
END


exec Weekly_DB_Space

GO
/****** Object:  StoredProcedure [dbo].[Weekly_DB_Space_notworking1]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Weekly_DB_Space_notworking1]
	
AS
BEGIN
	
--To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  




declare @sql varchar(8000)
declare @sql1 varchar(8000)
select @sql = 'bcp "SelECT * FROM ADT_Audit..CRS_MI_WeeklySpace" queryout \\10.142.174.231\testpath\sukanya\weekly.csv -c -t, -T -S' + @@servername
select @sql1 = 'bcp "select ''servername'',''Datetime'',''Name'',''Size_MBs'',''Size_GBs''union all select convert(nvarchar(128),[servername]),convert(nvarchar(128),[Datetime]),convert(nvarchar(128),[Name]),Convert(nvarchar(128),[Size_MBs]),Convert(nvarchar(128),[Size_GBs]) FROM ADT_Audit..CRS_MI_WeeklySpace_Helpdb" queryout \\10.142.174.231\testpath\sukanya\helpdb.csv -c -t, -T -S'+ @@servername
----bcp "select 'SalesOrderID', 'CarrierTrackingNumber','ModifiedDate','UpdateTime' union all SELECT 
----convert(varchar(20),[SalesOrderID]),convert(varchar(20),[CarrierTrackingNumber]),CONVERT(nvarchar(30), 
--[ModifiedDate], 120),CONVERT(nvarchar(30), [UpdateTime], 120) FROM [testdb].[dbo].[SalesOrderDetailIn]" 
--queryout D:\People.txt -t, -c -T  


----sqlcmd -s, -W -Q "set nocount on; select * from [DATABASE].[dbo].[TABLENAME]" | findstr /v /c:"-" /b > "c:\dirname\file.csv"


exec master..xp_cmdshell @sql
exec master..xp_cmdshell @sql1
 


DECLARE @filenames varchar(max)
DECLARE @file1 VARCHAR(MAX) = '\\10.142.174.231\testpath\sukanya\weekly.csv'
DECLARE @file2 VARCHAR(MAX) = ';\\10.142.174.231\testpath\sukanya\helpdb.csv'
--DECLARE @file3 VARCHAR(MAX) = ';C:\Testfiles\Test3.csv'

 

-- Create list from optional files
SELECT @filenames = @file1 + @file2

 

-- Send the email
EXEC msdb.dbo.sp_send_dbmail
  @profile_name = 'adtaudit',

  @recipients= 'sukanya.Subbiah@cognizant.com;Tharani.Ravindran@cognizant.com',
  @subject = 'CRS_MI_DBSize_Report_Weekly',
  @body= 'Weekly_databasegrowth MI Instance',
  @file_attachments = @filenames

END


GO
/****** Object:  StoredProcedure [dbo].[weekly_space_Nonprod]    Script Date: 3/20/2025 5:59:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[weekly_space_Nonprod]
	
AS
BEGIN


	
--To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  

update [dbo].[Required_nonprod_dbspace] set Size_GBs=cast(size_mbs as decimal(10,4))/1024


--declare @sql varchar(8000)
declare @sql varchar(8000)
--select @sql = 'bcp "select ''servername'',''DBName'',''FileName'',''Type_desc'',''CurrentSizeMB'',''FreeSpaceMB''union all select convert(nvarchar(128),[Servername]),convert(nvarchar(128),[DBName]),convert(nvarchar(128),[FileName]),Convert(nvarchar(128),[Type_Desc]),Convert(nvarchar(128),[CurrentSizeMB]),Convert(nvarchar(128),[FreeSpaceMB]) FROM ADT_Audit..CRS_MI_WeeklySpace" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Datafilesizedetails.csv -c -t, -T -S' + @@servername
select @sql = 'bcp "select ''Datetime'',''servername'',''Name'',''Size_MBs'',''Size_GBs''union all select convert(nvarchar(128),[Datetime]),convert(nvarchar(128),[Servername]),convert(nvarchar(128),[Name]),Convert(nvarchar(128),[Size_MBs]),Convert(nvarchar(128),[Size_GBs]) FROM ADT_Audit..Required_nonprod_dbspace" queryout \\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Size_nonprod.csv -c -t, -T -S'+ @@servername
----bcp "select 'SalesOrderID', 'CarrierTrackingNumber','ModifiedDate','UpdateTime' union all SELECT 
----convert(varchar(20),[SalesOrderID]),convert(varchar(20),[CarrierTrackingNumber]),CONVERT(nvarchar(30), 
--[ModifiedDate], 120),CONVERT(nvarchar(30), [UpdateTime], 120) FROM [testdb].[dbo].[SalesOrderDetailIn]" 
--queryout D:\People.txt -t, -c -T  


----sqlcmd -s, -W -Q "set nocount on; select * from [DATABASE].[dbo].[TABLENAME]" | findstr /v /c:"-" /b > "c:\dirname\file.csv"


exec master..xp_cmdshell @sql
--exec master..xp_cmdshell @sql1
 


DECLARE @filenames varchar(max)
--DECLARE @file1 VARCHAR(MAX) = '\\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Datafilesizedetails.csv'
DECLARE @file1 VARCHAR(MAX) = '\\CTSC00969373301\backup\Daily_Server_Storagereport_Dontdelet\Weekly_MI_DBsizereport\DB_Size_nonprod.csv'
--DECLARE @file3 VARCHAR(MAX) = ';C:\Testfiles\Test3.csv'

 

-- Create list from optional files
SELECT @filenames = @file1



 

-- Send the email
EXEC msdb.dbo.sp_send_dbmail
  @profile_name = 'adtaudit',

  @recipients= 'CISADPInfraSupportTeam@cognizant.com',
  @subject = 'Nonprod_dbsize',
  @body= 'Hi Team,
Weekly NON prod MI DB size report has been attached',
  @file_attachments = @file1



END




GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Prod_CRSDB"
            Begin Extent = 
               Top = 9
               Left = 57
               Bottom = 206
               Right = 279
            End
            DisplayFlags = 280
            TopColumn = 2
         End
         Begin Table = "CRS_Activelogin"
            Begin Extent = 
               Top = 9
               Left = 336
               Bottom = 206
               Right = 597
            End
            DisplayFlags = 280
            TopColumn = 6
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Test'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'Test'
GO
