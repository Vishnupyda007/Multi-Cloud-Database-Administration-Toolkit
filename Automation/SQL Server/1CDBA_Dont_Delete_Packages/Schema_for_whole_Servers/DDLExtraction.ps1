# Load SMO (ensure SqlServer module is installed)
Import-Module SqlServer

# Define log file and ensure directory exists
$logDir = "E:\1CDBA_Data_Donot_Delete\SQL_DDL_Backup_Automation"
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force
}

$logFile = Join-Path $logDir ("ExportDDL_Log_" + (Get-Date -Format 'yyyyMMdd') + ".log")

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

Write-Log "Starting DDL export process"

# SQL Auth connection for Azure SQL
$connection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
$connection.ServerInstance = "ctsazsimiuplt01.inso13dfbbbfa2150.database.windows.net"
$connection.LoginSecure = $false
$connection.Login = "crsdba"
$connection.Password = "crs@dmin2018"

$server = New-Object Microsoft.SqlServer.Management.Smo.Server($connection)

# Output folder
$outputRoot = "E:\1CDBA_Data_Donot_Delete\SQL_DDL_Backup_Automation\UPLT01"
if (!(Test-Path $outputRoot)) {
    New-Item -ItemType Directory -Path $outputRoot
    Write-Log "Created output directory: $outputRoot"
}

# Load excluded databases from file
$exclusionFile = "E:\1CDBA_Data_Donot_Delete\SQL_DDL_Backup_Automation\excluded_databases.txt"
$excludedDatabases = @("master", "model", "msdb", "tempdb", "distribution", "testDB")  # default exclusions

if (Test-Path $exclusionFile) {
    $fileExclusions = Get-Content $exclusionFile | Where-Object { $_ -ne "" }
    $excludedDatabases += $fileExclusions
    Write-Log "Loaded additional exclusions from file: $exclusionFile"
}

# Global counters
$totalCreated = 0
$totalUpdated = 0
$totalSkipped = 0

foreach ($db in $server.Databases) {
    if ($db.IsSystemObject -eq $false -and 
        -not ($excludedDatabases -contains $db.Name) -and 
        -not ($db.Name.StartsWith("CentralRepository"))) {

        Write-Log "Processing database: $($db.Name)"

        $dbFolder = Join-Path $outputRoot $db.Name
        if (!(Test-Path $dbFolder)) {
            New-Item -ItemType Directory -Path $dbFolder
            Write-Log "Created folder for database: $dbFolder"
        }

        # Database-level counters
        $dbCreated = 0
        $dbUpdated = 0
        $dbSkipped = 0

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
                if ($obj.IsSystemObject -eq $false) {
                    try {
                        $ddl = $scripter.Script($obj) -join "`r`n"
                        $fileName = Join-Path $dbFolder ($type.Name + "_" + $obj.Schema + "_" + $obj.Name + ".sql")

                        if (Test-Path $fileName) {
                            $existingContent = Get-Content $fileName -Raw
                            if ($existingContent -ne $ddl) {
                                $ddl | Out-File -FilePath $fileName -Encoding UTF8
                                Write-Log "Updated $($type.Name): $($obj.Schema).$($obj.Name)"
                                $dbUpdated++
                            } else {
                                Write-Log "Skipped unchanged $($type.Name): $($obj.Schema).$($obj.Name)"
                                $dbSkipped++
                            }
                        } else {
                            $ddl | Out-File -FilePath $fileName -Encoding UTF8
                            Write-Log "Created new $($type.Name): $($obj.Schema).$($obj.Name)"
                            $dbCreated++
                        }
                    } catch {
                        Write-Log "Failed to script $($obj.Name) in $($db.Name): $_" -level "ERROR"
                    }
                }
            }
        }

        # Update global counters
        $totalCreated += $dbCreated
        $totalUpdated += $dbUpdated
        $totalSkipped += $dbSkipped

        # Log database-level summary
        Write-Log "Summary for $($db.Name): Created = $dbCreated, Updated = $dbUpdated, Skipped = $dbSkipped"
    } else {
        Write-Log "Skipped database: $($db.Name)"
    }
}

# Log global summary
Write-Log "Global Summary: Created = $totalCreated, Updated = $totalUpdated, Skipped = $totalSkipped"
Write-Log "DDL export process completed"
