--Step 1
--Execute below script in distribution database to validate the current working directory.
 
--select * from msdb..MSdistpublishers with (nolock)
 
--Execute below 2 queries simultaneously under distribution database to update the working directory with AFS
 
exec sp_changedistpublisher @publisher = 'CTSAZPDMINCAPPS1.B96303A221DC.DATABASE.WINDOWS.NET', --- Mention the Pub server name
@property = N'working_directory', @value = '\\azstoragesqlmiprodreplfs.file.core.windows.net\ctssqlmicrsmasazurefs'--fileshare details
 
exec sp_changedistpublisher @publisher = @@ServerName, @property = N'storage_connection_string',
@value = 'DefaultEndpointsProtocol=https;AccountName=azstoragesqlmiprodreplfs;AccountKey=gmdK7eoMt5bm0jTDy9nsJx3kFmbuShJb81vphCKRvKBvewcVfE9jRtlF9MCXiG+tMns5G8aTf1DG+AStzSjEVg==;EndpointSuffix=core.windows.net';