use [EDSMonitoring]
go
CREATE TABLE [dbo].[Managed_Instance_Failover_Group_Lag](
								[Repli_endpoint_url] [nvarchar](1000) NULL,
								[Last_Hardened_Lsn] [nvarchar](1000) NULL,
								[Last_Redone_Lsn] [nvarchar](1000) NULL,
								[Redo_Queue_Size] [nvarchar](1000) NULL,
								[Catchup_Progress] nvarchar(200),
								[End_of_log_lsn]  [nvarchar](1000) NULL,
								[internal_state_desc] nvarchar(100),
								[database_state_desc] nvarchar(100),
								[partner_database] nvarchar(200),
								[ReplicationLag] int,
								[displaySeverity] varchar(25),
								[Table_Status] [int] NULL,
								Date_Collection datetime)