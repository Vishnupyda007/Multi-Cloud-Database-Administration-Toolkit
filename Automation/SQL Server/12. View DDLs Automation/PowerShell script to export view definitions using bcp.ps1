
# PowerShell script to export view definitions using bcp

# Define variables
$serverName = "CTSINAZSIPDDB06"
$databaseName = "1CDBAMonitoring"
$tableName = "ViewsDefinition"
$outputFile = "E:\Test.txt"

# Construct the bcp command
$bcpCommand = "bcp \"SELECT FormattedView FROM [$databaseName].dbo.$tableName\" queryout \"$outputFile\" -w -T -S $serverName"

# Execute the command
Invoke-Expression $bcpCommand
