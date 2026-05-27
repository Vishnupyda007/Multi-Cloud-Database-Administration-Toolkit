Examples:
 -----Azure Folder----
exec sp_changedistpublisher @publisher = 'ctsazsimidplt01.inso13dfbbbfa2150.database.windows.net',
@property = N'working_directory', @value = '\\10.153.56.151\EDS_Replication'
exec sp_changedistpublisher @publisher = @@ServerName, @property = N'storage_connection_string',
@value = 'AccountName=cts\Sqaoggusr;AccountKey=Ed$1nfadevelopmentusr2';
 


-----Non Prod Coud Path------
exec sp_changedistpublisher @publisher = 'ctsazsimiustfd1.inso13dfbbbfa2150.database.windows.net', --- Mention the Pub server name
@property = N'working_directory', @value = '\\ctssqlminonprod.file.core.windows.net\ctssqlminpfs'  --Cloud Snapshot folder
exec sp_changedistpublisher @publisher = @@ServerName, @property = N'storage_connection_string',
@value = 'DefaultEndpointsProtocol=https;AccountName=ctssqlminonprod;AccountKey=0JxcDGfId/Ek9LQzSvMf2pwF2ICBCG52F6zPYRduYOh7HeLGH1uq3HxYWw6e+0zzieIwv3MhoUko+AStUZIaXA==;EndpointSuffix=core.windows.net';



----prod cloud path--------

exec sp_changedistpublisher @publisher = 'ctsazsimiptm2.inso1a101c37461fa.database.windows.net', --- Mention the Pub server name
@property = N'working_directory', @value = '\\ctssqlmiprodreplfs.file.core.windows.net\ctssqlmiptmazurefs'--—fileshare details
 
exec sp_changedistpublisher @publisher = @@ServerName, @property = N'storage_connection_string',
@value = 'DefaultEndpointsProtocol=https;AccountName=ctssqlmiprodreplfs;AccountKey=JJ0rjIEFxhLA+k15QxK8zjFodVuTKw7MQifhloC2QVyYJzvd3x6ckyIFiPSgHKUZ5Kltu96BE80Q+AStLi8WzA==;EndpointSuffix=core.windows.net';
 