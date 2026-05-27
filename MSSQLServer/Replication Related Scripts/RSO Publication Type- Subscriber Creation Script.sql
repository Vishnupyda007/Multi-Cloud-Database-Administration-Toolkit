-----------------BEGIN: Script to be run at Publisher 'CTSINAZPRDEDSSQLMI.INSO1A101C37461FA.DATABASE.WINDOWS.NET'-----------------
use [ent_data_store]
exec sp_addsubscription @publication = N'EDS_REPL_SUPPORT_ONLY_PUB', 
@subscriber = N'ctsazpdmincapps2.b96303a221dc.database.windows.net', 
@destination_db = N'CentralRepository', 
@subscription_type = N'Push', 
@sync_type = N'replication support only', 
@article = N'all', 
@update_mode = N'read only', 
@subscriber_type = 0
exec sp_addpushsubscription_agent 
@publication = N'EDS_REPL_SUPPORT_ONLY_PUB', 
@subscriber = N'ctsazpdmincapps2.b96303a221dc.database.windows.net', 
@subscriber_db = N'CentralRepository', 
@job_login = N'edsadmin', @job_password = 'XXXXXXX', 
@subscriber_security_mode = 0, 
@subscriber_login = N'crsdba', 
@subscriber_password = 'XXXXXXX', 
@frequency_type = 64, 
@frequency_interval = 0, 
@frequency_relative_interval = 0, 
@frequency_recurrence_factor = 0, 
@frequency_subday = 0, 
@frequency_subday_interval = 0, 
@active_start_time_of_day = 0, 
@active_end_time_of_day = 235959, 
@active_start_date = 20250418, 
@active_end_date = 99991231, 
@enabled_for_syncmgr = N'False', 
@dts_package_location = N'Distributor'
GO