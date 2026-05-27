# Load SMO
Import-Module SqlServer

# Paths
$oldDDLRoot = "E:\1CDBA_Data_Donot_Delete\SQL_DDL_Backup_Automation\UPLT01"
$newDDLRoot = "E:\1CDBA_Data_Donot_Delete\SQL_DDL_Backup_Automation\New_UPLT01"
$diffOutputRoot = "E:\1CDBA_Data_Donot_Delete\SQL_DDL_Backup_Automation\UPLT01_DDL_Diff_Results"
$logFile = Join-Path $newDDLRoot ("ModifiedDDL_Log_" + (Get-Date -Format 'yyyyMMdd') + ".log")

# Ensure required paths exist
foreach ($path in @($newDDLRoot, $diffOutputRoot)) {
    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force
    }
}

# Logging function
function Write-Log {
    param (
        [string]$message,
        [string]$level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$level] - $message"
    try {
        Add-Content -Path $logFile -Value $logEntry
    } catch {
        try {
            $logEntry | Out-File -FilePath $logFile -Encoding UTF8 -Append
        } catch {
            Write-Host "Failed to write to log file: $logFile"
            Write-Host "Error: $_"
        }
    }
}

Write-Log "Starting modified DDL extraction and comparison"

# SQL Auth connection
$connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
$connection.ServerInstance = "ctsazsimiuplt01.inso13dfbbbfa2150.database.windows.net"
$connection.LoginSecure = $false
$connection.Login = "crsdba"
$connection.Password = "crs@dmin2018"

$server = New-Object Microsoft.SqlServer.Management.Smo.Server($connection)

# Time filter
$cutoffTime = (Get-Date).AddHours(-3)

# System databases to exclude
$systemDatabases = @("master", "model", "msdb", "tempdb", "distribution")

foreach ($db in $server.Databases) {
    if ($db.IsSystemObject -eq $false -and 
        -not ($systemDatabases -contains $db.Name) -and 
        -not ($db.Name.StartsWith("CentralRepository"))) {

        Write-Log "Checking database: $($db.Name)"
        $newDbPath = Join-Path $newDDLRoot $db.Name
        $oldDbPath = Join-Path $oldDDLRoot $db.Name

        if (!(Test-Path $newDbPath)) { New-Item -ItemType Directory -Path $newDbPath -Force }
        if (!(Test-Path $oldDbPath)) { Write-Log "Old DDL path missing for $($db.Name)" -level "WARNING" }

        $objectTypes = @(
            @{Name="Tables"; Collection=$db.Tables},
            @{Name="Views"; Collection=$db.Views},
            @{Name="StoredProcedures"; Collection=$db.StoredProcedures},
            @{Name="UserDefinedFunctions"; Collection=$db.UserDefinedFunctions},
            @{Name="UserDefinedTableTypes"; Collection=($db.UserDefinedTypes | Where-Object { $_.UserType -eq 'TableType' })}
        )

        $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter($server)
        $scripter.Options.ScriptDrops = $false
        $scripter.Options.WithDependencies = $false
        $scripter.Options.IncludeHeaders = $true
        $scripter.Options.SchemaQualify = $true
        $scripter.Options.SchemaQualifyForeignKeysReferences = $true
        $scripter.Options.DriAll = $true
        $scripter.Options.Indexes = $true
        $scripter.Options.Triggers = $false

        foreach ($type in $objectTypes) {
            foreach ($obj in $type.Collection) {
                if ($obj.IsSystemObject -eq $false -and $obj.Properties["IsMSShipped"].Value -ne $true) {
                    $lastModified = $obj.Properties["DateLastModified"].Value
                    if ($lastModified -and $lastModified -gt $cutoffTime) {
                        try {
                            $ddl = $scripter.Script($obj) -join "`r`n"
                            $fileName = $type.Name + "_" + $obj.Schema + "_" + $obj.Name + ".sql"
                            $newFilePath = Join-Path $newDbPath $fileName
                            $oldFilePath = Join-Path $oldDbPath $fileName

                            $ddl | Out-File -FilePath $newFilePath -Encoding UTF8
                            Write-Log "Extracted modified $($type.Name): $($obj.Schema).$($obj.Name)"

                            if (Test-Path $oldFilePath) {
                                $diffOutput = & fc.exe $oldFilePath $newFilePath
                                if ($diffOutput) {
                                    Write-Log "Changes detected in $($obj.Schema).$($obj.Name):"
                                    Add-Content -Path $logFile -Value $diffOutput

                                    # Export diff to separate file
                                    $diffFileName = "DIFF_" + $type.Name + "_" + $obj.Schema + "_" + $obj.Name + ".txt"
                                    $diffFilePath = Join-Path $diffOutputRoot $diffFileName
                                    $diffOutput | Out-File -FilePath $diffFilePath -Encoding UTF8
                                } else {
                                    Write-Log "No visible changes in $($obj.Schema).$($obj.Name)"
                                }
                            } else {
                                Write-Log "No previous version found for $($obj.Schema).$($obj.Name)"
                            }
                        } catch {
                            Write-Log "Error scripting $($obj.Name) in $($db.Name): $_" -level "ERROR"
                        }
                    }
                }
            }
        }
    }
}

Write-Log "Modified DDL extraction and comparison completed"
