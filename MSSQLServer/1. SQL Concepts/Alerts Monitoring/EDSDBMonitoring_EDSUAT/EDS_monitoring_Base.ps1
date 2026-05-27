<#Script to pull Managed Instance failover group replication lag seconds from multiple Managed Instances#>
Set-ExecutionPolicy unrestricted
  <# Ver 1.0 #>
  Import-Module SqlServer
  <#Variables - details of the connection, tsqlcommand and parameters #>
  $RepositorySQLInstance = "CTSC01290748301"
  $RepositoryDB = "EDSUATMonitoring"

  $MISQLInstance = "ctsinazuatedssqlmi01.inso13dfbbbfa2150.database.windows.net"
  $MIDB = "Master"
  $MI_Username = "edsadmin"
  $MI_Password = "eds@dmin2018"


  <#Provide the name of the Local Instance to store the data#>
  $LocalInstance = $RepositorySQLInstance 
  <#Provide the name of the database to store the data#>
  $Repositorydb=$RepositoryDB
  
  $update_table_status = "update [EDS_Log_Usage] set Table_Status=0"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $update_table_status
  
  $update_table_status_FG = "update [Managed_Instance_Failover_Group_Lag] set Table_Status=0"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $update_table_status_FG

  $update_table_space_status = "update [MI_SPACE] set Table_Status=0"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $update_table_space_status
  
  $update_table_db_status = "update [MI_DB_SPACE] set Table_Status=0"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $update_table_db_status
  
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\1.Log_Used.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName EDS_Log_Usage -Force 
  Write-Host "Log usage details collected from" $MISQLInstance

  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\2.Failover_Group_Lag.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName Managed_Instance_Failover_Group_Lag -Force 
  Write-Host "Failover Group details collected from" $MISQLInstance
  
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\3.MI_Space.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName MI_SPACE -Force 
  Write-Host "MI overall space details collected from" $MISQLInstance
  
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\3.MI_DB_Space.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName MI_DB_SPACE -Force 
  Write-Host "MI DB Space details collected from" $MISQLInstance
  
  $Purge_Log_usage_table = "delete from [dbo].[EDS_Log_Usage] where Date_Collection < (getdate()-10)"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_Log_usage_table

  $Purge_Log_usage_table_FG = "delete from [dbo].[Managed_Instance_Failover_Group_Lag] where Date_Collection < (getdate()-10)"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_Log_usage_table_FG

  $Purge_Log_usagespace_table = "delete from [dbo].[MI_SPACE] where Date_Collection < (getdate()-10)"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_Log_usagespace_table

  $Purge_Log_usage_db_space_table = "delete from [dbo].[MI_DB_SPACE] where Date_Collection < (getdate()-10)"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_Log_usage_db_space_table

 
#CPU Queries
  $Purge_CPU_Percent_table = "truncate table [dbo].[CPU_Percent]"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_CPU_Percent_table
  $Purge_CPU_Percent_table = "truncate table [dbo].[whoisactive_cpu]"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_CPU_Percent_table
  $Purge_CPU_Percent_table = "truncate table [dbo].[What_is_Running]"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_CPU_Percent_table
  
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\6.Resource_Query_CPU_1.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "CPU_Percent" -Force 
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\6.Resource_Query_CPU_2.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "whoisactive_cpu" -Force 
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\6.Resource_Query_CPU_3.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "What_is_Running" -Force 
  
  Write-Host "CPU usage details collected from" $MISQLInstance

#Memory Queries
  $Purge_MEMORY_Percent_table = "truncate table [dbo].[Memory_PERCENT]"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_MEMORY_Percent_table
  $Purge_MEMORY_Percent_table = "truncate table [dbo].[whoisactive_Memory]"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_MEMORY_Percent_table
  $Purge_MEMORY_Percent_table = "truncate table [dbo].[What_is_Running_Memory]"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_MEMORY_Percent_table
  
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\7.Resource_Query_MEMORY_1.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "Memory_PERCENT" -Force 
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\7.Resource_Query_MEMORY_2.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "whoisactive_Memory" -Force 
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\7.Resource_Query_MEMORY_3.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "What_is_Running_Memory" -Force 
  
  Write-Host "Memory usage details collected from" $MISQLInstance

#IO Queries
  $Purge_IO_Percent_table = "truncate table [dbo].[IO_Percent]"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_IO_Percent_table
  $Purge_IO_Percent_table = "truncate table [dbo].whoisactive_IO"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_IO_Percent_table
  $Purge_IO_Percent_table = "truncate table [dbo].[What_is_Running_IO]"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_IO_Percent_table
  
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\8.Resource_Query_IO_1.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "IO_PERCENT" -Force 
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\8.Resource_Query_IO_2.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "whoisactive_IO" -Force 
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\8.Resource_Query_IO_3.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "What_is_Running_IO" -Force 
  
  Write-Host "IO usage details collected from" $MISQLInstance

#Tempdb Queries
  $Purge_Tempdb_Percent_table = "truncate table [dbo].[DB_Size_Tempdb]"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_Tempdb_Percent_table
  $Purge_Tempdb_Percent_table = "truncate table [dbo].whoisactive_tempdb"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_Tempdb_Percent_table
  $Purge_Tempdb_Percent_table = "truncate table [dbo].[What_is_Running_tempdb]"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_Tempdb_Percent_table
  
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\9.Resource_Query_Tempdb_1.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "DB_Size_Tempdb" -Force 
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\9.Resource_Query_Tempdb_2.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "whoisactive_tempdb" -Force 
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring_EDSUAT\9.Resource_Query_Tempdb_3.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName "What_is_Running_tempdb" -Force 
  
  Write-Host "Tempdb usage details collected from" $MISQLInstance

  

  