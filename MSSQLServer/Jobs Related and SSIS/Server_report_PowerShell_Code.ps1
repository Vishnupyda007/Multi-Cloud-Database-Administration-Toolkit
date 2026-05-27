# Define variables
$serverNames = @("CTSC01048405301\CRSUAT", "CTSC01048387001\CRSDEV", "CTSC01048403401\CRSSIT")
$databaseName = "master"

$query1 = @"
SELECT 
    DB_NAME(database_id) AS [Database Name], 
    SUM(size * 8 / 1024) AS [Size (MB)]
FROM 
    sys.master_files
GROUP BY 
    DB_NAME(database_id);
"@

$query2 = "EXEC xp_fixeddrives;"

$query3 = @"
SET NOCOUNT ON
DECLARE @DBName NVARCHAR(100) = NULL, --Provide DBName if looking for a specific database or leave to get all databases details
@Drive NVARCHAR(2) = NULL --Mention drive letter if you are concerned of only a single drive where you are running out of space
DECLARE @cmd NVARCHAR(4000)
IF (SELECT OBJECT_ID('tempdb.dbo.#DBName')) IS NOT NULL
DROP TABLE #DBName
CREATE TABLE #DBName (Name NVARCHAR(100))
IF @DBName IS NOT NULL
INSERT INTO #DBName SELECT @DBName
ELSE
INSERT INTO #DBName SELECT Name FROM sys.databases WHERE state_desc = 'ONLINE'
IF (SELECT OBJECT_ID('tempdb.dbo.##FileStats')) IS NOT NULL
DROP TABLE ##FileStats
CREATE TABLE ##FileStats (ServerName NVARCHAR(100), DBName NVARCHAR(100), FileType NVARCHAR(100),
FileName NVARCHAR(100), CurrentSizeMB FLOAT, FreeSpaceMB FLOAT, PercentMBFree FLOAT, FileLocation NVARCHAR(1000))
WHILE (SELECT TOP 1 * FROM #DBName) IS NOT NULL
BEGIN
SELECT @DBName = MIN(Name) FROM #DBName
SET @cmd = 'USE [' + @DBName + ']
INSERT INTO ##FileStats
SELECT @@ServerName AS ServerName, DB_NAME() AS DbName,
CASE WHEN type = 0 THEN ''DATA'' ELSE ''LOG'' END AS FileType,
name AS FileName,
size/128.0 AS CurrentSizeMB,
size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 AS FreeSpaceMB,
100*(1 - ((CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0)/(size/128.0))) AS PercentMBFree,
physical_name AS FileLocation
FROM sys.database_files'
IF @Drive IS NOT NULL
SET @cmd = @cmd + ' WHERE physical_name LIKE ''' + @Drive + ':\%'''
EXEC sp_executesql @cmd
DELETE FROM #DBName WHERE Name = @DBName
END
SELECT DBName,FileType,FileName,CurrentSizeMB,CurrentSizeMB-FreeSpaceMB as Occupied,FreeSpaceMB,PercentMBFree,FileLocation FROM ##FileStats
ORDER BY Filetype, FreeSpaceMB DESC
DROP TABLE #DBName
DROP TABLE ##FileStats
"@

# Define the output directory and zip file path
$outputDir = "F:\report\Output files"
$outputDir1 = "F:\report\Combined files"
$zipFile = "F:\report\Output files\ServerReports.zip"

# Initialize the output directory
Remove-Item "$outputDir\*" -Force -Recurse -ErrorAction Ignore
New-Item -Path $outputDir -ItemType Directory -Force

Remove-Item "$outputDir1\*" -Force -Recurse -ErrorAction Ignore
New-Item -Path $outputDir1 -ItemType Directory -Force

# Loop through each server and execute the queries
foreach ($serverName in $serverNames) {
    # Replace backslash in server name with underscore
    $safeServerName = $serverName -replace '\\', '_'

    # Define the output file paths for each server
    $outputFile1 = "$outputDir\$($safeServerName)_DatabaseFiles.csv"
    $outputFile2 = "$outputDir\$($safeServerName)_DriveReport.csv"
    $outputFile3 = "$outputDir\$($safeServerName)_DatabaseSize.csv"
    $combinedFile = "$outputDir1\$($safeServerName).csv"

    # Execute the queries and export to CSV
    Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $query1 | Export-Csv -Path $outputFile1 -NoTypeInformation
    Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $query2 | Export-Csv -Path $outputFile2 -NoTypeInformation
    Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $query3 | Export-Csv -Path $outputFile3 -NoTypeInformation

    # Combine the CSV files into one
    Get-Content $outputFile1 | Add-Content $combinedFile
    "`n" | Add-Content $combinedFile
    Get-Content $outputFile2 | Add-Content $combinedFile
    "`n" | Add-Content $combinedFile
    Get-Content $outputFile3 | Add-Content $combinedFile
}

# Ensure the zip file is not in use
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}

# Create a zip file containing all combined CSV files
Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($outputDir1, $zipFile)

# Send the email
$smtpServer = "cognizant-com.mail.protection.outlook.com"
$smtpFrom = "janani.m2dcbb3@cognizant.com"
$smtpTo = "CRSDBASUPPORT@cognizant.com"
$messageSubject = "**Automated Mail**"
$messageBody = "This report is sent for testing purpose. Please find the attached Onprem server report for SIT, UAT, DEV."
$attachment = $zipFile

$mailMessage = New-Object system.net.mail.mailmessage
$mailMessage.from = $smtpFrom
$mailMessage.To.Add($smtpTo)
$mailMessage.Subject = $messageSubject
$mailMessage.Body = $messageBody
$mailMessage.Attachments.Add($attachment)

$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($mailMessage)
