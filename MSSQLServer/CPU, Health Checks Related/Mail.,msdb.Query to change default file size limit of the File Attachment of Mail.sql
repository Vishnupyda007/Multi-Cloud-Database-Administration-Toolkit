

? Error: File attachment or query results size exceeds allowable value of 1000000 bytes
This error occurs because the attachment you're trying to send via sp_send_dbmail exceeds 1 MB, which is the default limit for SQL Server Database Mail.

? Solutions
Option 1: Increase the Attachment Size Limit
You can increase the limit using the following SQL command:

EXEC msdb.dbo.sysmail_configure_sp 'MaxFileSize', '5242880'; -- Sets limit to 5 MB


