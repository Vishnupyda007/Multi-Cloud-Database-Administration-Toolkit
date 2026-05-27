USE master;
GO

EXEC sp_adddistributor
    @distributor = @@SERVERNAME,
@password = 'Distribution@123';
GO

USE master;
GO

EXEC sp_adddistributiondb
    @database = N'distribution',
    @data_folder = N'F:\distribution\data',
    @log_folder = N'F:\distribution\log';
GO

USE master;
GO

EXEC sp_adddistpublisher
    @publisher = @@SERVERNAME,
    @distribution_db = N'distribution',
	@security_mode = 0,
    @login = N'crsdba',
    @password = N'',
    @working_directory = N'\\CTSC00755523301\Snapshot_folder_Repln';
	GO

USE master;
GO

EXEC sp_replicationdboption
    @dbname = N'CentralRepository',
    @optname = N'publish',
    @value = N'true';
GO