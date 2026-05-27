use [EDSMonitoring]
go
CREATE TABLE [dbo].[MI_SPACE](
								[volume_mount_point] varchar(255),
								[used_gb] decimal (8,2),
								[available_gb] decimal (8,2),
								[total_gb] decimal (8,2),
								[Used_Space_GB_%] decimal (8,2),
								[Available_Space_GB_%] decimal (8,2),
								[Table_Status] [int] NULL,
								Date_Collection datetime)

CREATE TABLE [dbo].[MI_DB_SPACE](
								[DatabaseName] varchar(255),
								[FileName] varchar(255),
								[FileType] varchar(255),
								[FileSizeGB] decimal (8,2),
								[FreeSpaceGB] decimal (8,2),
								[FileMaxSizeGB] int,
								[PercentGrowth] int,
								[FileGrowthGB] decimal (8,2),
								[SpaceAvailableGB] int,
								[Table_Status] [int] NULL,
								Date_Collection datetime)