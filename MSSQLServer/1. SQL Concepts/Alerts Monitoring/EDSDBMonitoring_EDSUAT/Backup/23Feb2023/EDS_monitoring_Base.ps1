<#Script to pull Managed Instance failover group replication lag seconds from multiple Managed Instances#>
Set-ExecutionPolicy unrestricted
  <# Ver 1.0 #>
  Import-Module SqlServer
  <#Variables - details of the connection, tsqlcommand and parameters #>
  $RepositorySQLInstance = "CTSC01290748301"
  $RepositoryDB = "EDSMonitoring"

  $MISQLInstance = "ctsinazprdedssqlmi.inso1a101c37461fa.database.windows.net"
  $MIDB = "Master"
  $MI_Username = "edsadmin"
  $MI_Password = "Admin@Eds12"


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
  
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring\1.Log_Used.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName EDS_Log_Usage -Force 
  Write-Host "Log usage details collected from" $MISQLInstance

  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring\2.Failover_Group_Lag.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName Managed_Instance_Failover_Group_Lag -Force 
  Write-Host "Failover Group details collected from" $MISQLInstance
  
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring\3.MI_Space.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName MI_SPACE -Force 
  Write-Host "MI overall space details collected from" $MISQLInstance
  
  Invoke-Sqlcmd -inputfile "D:\EDSDBMonitoring\3.MI_DB_Space.sql" -ServerInstance $MISQLInstance -Database master -Username $MI_Username -Password $MI_Password| Write-SqlTableData -ServerInstance $LocalInstance -DatabaseName $Repositorydb -SchemaName dbo -TableName MI_DB_SPACE -Force 
  Write-Host "MI DB Space details collected from" $MISQLInstance
  
  $Purge_Log_usage_table = "delete from [dbo].[EDS_Log_Usage] where Date_Collection < (getdate()-10)"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_Log_usage_table

  $Purge_Log_usage_table_FG = "delete from [dbo].[Managed_Instance_Failover_Group_Lag] where Date_Collection < (getdate()-10)"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_Log_usage_table_FG

  $Purge_Log_usagespace_table = "delete from [dbo].[MI_SPACE] where Date_Collection < (getdate()-10)"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_Log_usagespace_table

  $Purge_Log_usage_db_space_table = "delete from [dbo].[MI_DB_SPACE] where Date_Collection < (getdate()-10)"
  Invoke-Sqlcmd -ServerInstance $RepositorySQLInstance -Database $RepositoryDB -Query $Purge_Log_usage_db_space_table

  