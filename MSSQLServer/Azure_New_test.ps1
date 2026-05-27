param(
    [string]$ServerName,
    [string]$SqlUsername = "test",
    [string]$SqlPassword = "test"
)

# Ensure ImportExcel module is available
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser -Force
}

# Initialize results array
$results = @()

# Get list of user databases
$databasesQuery = "SELECT name FROM sys.databases WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')"
$databases = Invoke-Sqlcmd -ServerInstance $ServerName -Username $SqlUsername -Password $SqlPassword -Query $databasesQuery -TrustServerCertificate

foreach ($db in $databases) {
    $databaseName = $db.name
    Write-Host "Processing database: $databaseName"

    ####################### Revoke PUBLIC Permissions #######################
    $publicaccessQuery = @"
SELECT 
    ObjectName = o.name, 
    ObjectType = o.type_desc, 
    PermissionType = dp.state_desc, 
    UserType = p.type_desc, 
    PermissionName = dp.permission_name, 
    UserName = p.name 
FROM sys.database_permissions dp 
JOIN sys.database_principals p ON dp.grantee_principal_id = p.principal_id 
JOIN sys.objects o ON dp.major_id = o.object_id 
WHERE p.name = 'public';
"@

    $publicaccess = Invoke-Sqlcmd -ServerInstance $ServerName -Database $databaseName -Username $SqlUsername -Password $SqlPassword -Query $publicaccessQuery -TrustServerCertificate
    foreach ($s in $publicaccess) {
        $revokepublicquery = "REVOKE $($s.PermissionName) ON [$($s.ObjectName)] TO public"
        Invoke-Sqlcmd -ServerInstance $ServerName -Database $databaseName -Username $SqlUsername -Password $SqlPassword -Query $revokepublicquery -TrustServerCertificate
        Write-Host "Revoked $($s.PermissionName) on $($s.ObjectName) from public in $databaseName"

        $results += [PSCustomObject]@{
            Database   = $databaseName
            Principal  = "public"
            Object     = $s.ObjectName
            Permission = $s.PermissionName
            Action     = "Revoked"
            Timestamp  = (Get-Date)
        }
    }

    ####################### Revoke GUEST Permissions #######################
    $guestaccessQuery = @"
SELECT 
    dp.name AS principal_name,
    perm.permission_name,
    perm.state_desc
FROM sys.database_permissions perm
JOIN sys.database_principals dp ON perm.grantee_principal_id = dp.principal_id
WHERE dp.name = 'guest' AND perm.class_desc = 'DATABASE';
"@

    $guestaccess = Invoke-Sqlcmd -ServerInstance $ServerName -Database $databaseName -Username $SqlUsername -Password $SqlPassword -Query $guestaccessQuery -TrustServerCertificate

    foreach ($s in $guestaccess) {
        $disableguestaccountquery = "REVOKE $($s.permission_name) TO guest"
        Invoke-Sqlcmd -ServerInstance $ServerName -Database $databaseName -Username $SqlUsername -Password $SqlPassword -Query $disableguestaccountquery -TrustServerCertificate
        Write-Host "Revoked $($s.permission_name) from guest in $databaseName"

        $results += [PSCustomObject]@{
            Database   = $databaseName
            Principal  = "guest"
            Object     = "DATABASE"
            Permission = $s.permission_name
            Action     = "Revoked"
            Timestamp  = (Get-Date)
        }
    }

    ####################### Revoke IMPERSONATE Permissions #######################
    $impersonateQuery = @"
SELECT
    DB_NAME() AS database_name,
    grantee.name AS grantee,
    impersonated.name AS impersonated
FROM
    sys.database_permissions perm
    JOIN sys.database_principals grantee 
        ON perm.grantee_principal_id = grantee.principal_id
    JOIN sys.database_principals impersonated 
        ON perm.major_id = impersonated.principal_id
WHERE perm.type = 'IM'
"@

    $impersonateaccess = Invoke-Sqlcmd -ServerInstance $ServerName -Database $databaseName -Username $SqlUsername -Password $SqlPassword -Query $impersonateQuery -TrustServerCertificate

    foreach ($s in $impersonateaccess) {
        $revokeimpersonatequery = "REVOKE IMPERSONATE ON USER::[$($s.impersonated)] FROM [$($s.grantee)]"
        Invoke-Sqlcmd -ServerInstance $ServerName -Database $databaseName -Username $SqlUsername -Password $SqlPassword -Query $revokeimpersonatequery -TrustServerCertificate
        Write-Host "Revoked IMPERSONATE on $($s.impersonated) from $($s.grantee) in $databaseName"

        $results += [PSCustomObject]@{
            Database   = $databaseName
            Principal  = $s.grantee
            Object     = $s.impersonated
            Permission = "IMPERSONATE"
            Action     = "Revoked"
            Timestamp  = (Get-Date)
        }
    }
}

# Export results to Excel
$excelPath = "C:\Azure_scripts\PermissionRevocationReport.xlsx"
$results | Export-Excel -Path $excelPath -AutoSize -WorksheetName "Revocations"
Write-Host "Report saved to $excelPath"
