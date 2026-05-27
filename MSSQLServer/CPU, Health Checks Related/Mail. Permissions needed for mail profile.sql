What are the permissions needed for mail profile?
To send email using Database Mail in SQL Server, a user must have specific permissions and roles assigned. Here are the key permissions needed:

DatabaseMailUserRole: The user must be a member of the DatabaseMailUserRole in the msdb database. This role allows the user to send emails using Database Mail12.

Access to Mail Profile: The user must have access to at least one Database Mail profile. This can be granted using the sysmail_add_principalprofile_sp stored procedure3. For example:

EXEC msdb.dbo.sysmail_add_principalprofile_sp
    @principal_name = 'YourUserName',
    @profile_name = 'YourProfileName',
    @is_default = 1;
Permissions for Creating Profiles: The user creating the profiles and accounts should ideally be a member of the sysadmin fixed server role1.

Execute Permissions: Ensure the user has EXECUTE permissions on the necessary stored procedures related to Database Mail, such as sp_send_dbmail.

Would you like more detailed steps on how to configure these permissions?



1
Favicon type
Create a Database Mail Profile - SQL Server | Microsoft Learn

2
Favicon type
How to grant sendmail permission to sql server user?

3
Favicon type
Grant an msdb User Access to a D