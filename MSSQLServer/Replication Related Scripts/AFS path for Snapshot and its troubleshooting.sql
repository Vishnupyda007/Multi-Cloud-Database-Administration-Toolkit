USE master
GO

DECLARE @connstr NVARCHAR(1000)
SET @connstr = 'DefaultEndpointsProtocol=https;AccountName=azstoragedrsqlmireplfs;AccountKey=Y7gK1UmzvIimEEeYmgPCfMQ5ElJnTL9P5thd+YAGY+YREMv3Lc2SYCF5yHh/N7ZgmELeISJnKpHB+ASt9vEHDw==;EndpointSuffix=core.windows.net'

-- Verify length - should be around 220 characters
PRINT LEN(@connstr)

EXEC sp_adddistpublisher
    @publisher = N'ctsinazdredssqlmi.inso1a101c37461fa.database.windows.net',
    @distribution_db = N'distribution',
    @security_mode = 0,
    @login = N'edsadmin',
    @password = N'Admin@Eds12',
    @working_directory = N'\\azstoragedrsqlmireplfs.file.core.windows.net\ctsinazdredssqlmireplfs',
    @storage_connection_string = @connstr
GO


-------------------------------keep connection string in single line------------------------------


USE master
GO

EXEC sp_adddistpublisher
    @publisher = N'ctsinazdredssqlmi.inso1a101c37461fa.database.windows.net',
    @distribution_db = N'distribution',
    @security_mode = 0,
    @login = N'edsadmin',
    @password = N'Admin@Eds12',
    @working_directory = N'\\azstoragedrsqlmireplfs.file.core.windows.net\ctsinazdredssqlmireplfs',
    @storage_connection_string = 
	N'DefaultEndpointsProtocol=https;AccountName=azstoragedrsqlmireplfs;AccountKey=Y7gK1UmzvIimEEeYmgPCfMQ5ElJnTL9P5thd+YAGY+YREMv3Lc2SYCF5yHh/N7ZgmELeISJnKpHB+ASt9vEHDw==;EndpointSuffix=core.windows.net'
GO


--3)
 
use [ent_data_store]
exec sp_replicationdboption 
@dbname = N'ent_data_store'
, @optname = N'publish'
, @value = N'true'
GO

-- Immediately verify
EXEC sp_helpdistpublisher
EXEC sp_helpdistributiondb @database = N'distribution'


SELECT  name,
                upper(data_source collate database_default ),
                server_id,
                name
    FROM sys.servers
    WHERE is_distributor = 1


SELECT  * FROM sys.servers
 