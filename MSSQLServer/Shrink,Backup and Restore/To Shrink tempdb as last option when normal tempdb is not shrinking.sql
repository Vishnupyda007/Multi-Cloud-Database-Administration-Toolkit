use tempdb
go
checkpoint
go
dbcc freeproccache
go
DBCC SHRINKFILE (tempdev, 1024); -- Adjust the size as needed
