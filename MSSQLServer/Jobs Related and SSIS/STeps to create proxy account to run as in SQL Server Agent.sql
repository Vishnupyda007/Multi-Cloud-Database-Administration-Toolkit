USE master;
GO
CREATE CREDENTIAL MyCredential WITH IDENTITY = 'CTS\2275509-admin'
GO


USE msdb;
GO
EXEC dbo.sp_add_proxy
    @proxy_name = 'myproxy',
    @credential_name = 'MyCredential';
GO


EXEC dbo.sp_grant_proxy_to_subsystem
    @proxy_name = 'myproxy',
    @subsystem_name = 'SSIS';
GO



