use [CentralRepository]
exec [CentralRepository].sys.sp_addlogreader_agent 
@job_login = N'crsdba'
, @job_password = 'crs@dmin2018'
, @publisher_security_mode = 0
, @publisher_login = N'crsdba'
, @publisher_password = N'crs@dmin2018'
, @job_name = null
GO


----------------------

use [CentralRepository]

exec sp_addpublication 

@publication = N'EDS_Gen_GP_Test'

, @sync_method = N'concurrent'

, @retention = 0

, @allow_push = N'true'

, @allow_pull = N'true'

, @allow_anonymous = N'true'

, @enabled_for_internet = N'false'

, @snapshot_in_defaultfolder = N'true'

, @compress_snapshot = N'false'

, @ftp_port = 21

, @allow_subscription_copy = N'false'

, @add_to_active_directory = N'false'

, @repl_freq = N'continuous'

, @status = N'active'

, @independent_agent = N'true'

, @immediate_sync = N'true'

, @allow_sync_tran = N'false'

, @allow_queued_tran = N'false'

, @allow_dts = N'false'

, @replicate_ddl = 1

, @allow_initialize_from_backup = N'false'

, @enabled_for_p2p = N'false'

, @enabled_for_het_sub = N'false'

GO
 
 
exec sp_addpublication_snapshot 

@publication = N'EDS_Gen_GP_Test'

, @frequency_type = 1

, @frequency_interval = 1

, @frequency_relative_interval = 1

, @frequency_recurrence_factor = 0

, @frequency_subday = 8

, @frequency_subday_interval = 1

, @active_start_time_of_day = 0

, @active_end_time_of_day = 235959

, @active_start_date = 0

, @active_end_date = 0

, @job_login = N'crsdba'

, @job_password = 'crs@dmin2018'

, @publisher_security_mode = 0

, @publisher_login = N'crsdba'

, @publisher_password = 'crs@dmin2018'
 