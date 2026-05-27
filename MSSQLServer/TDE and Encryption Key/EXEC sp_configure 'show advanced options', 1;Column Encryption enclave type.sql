EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'column encryption enclave type', 1; -- 1 for VBS enclave
RECONFIGURE;what does it do and will it change Server config settings?
Copilot said:
Copilot
The commands you provided are used to configure SQL Server settings related to column encryption and enclaves. Here's a breakdown of what each part does:

EXEC sp_configure 'show advanced options', 1;: This command enables the display of advanced configuration options in SQL Server. By default, some advanced options are hidden, and this command makes them visible.

RECONFIGURE;: This command applies the changes made by the previous sp_configure command.

EXEC sp_configure 'column encryption enclave type', 1;: This command sets the type of enclave to be used for column encryption. In this case, 1 specifies the use of a Virtualization-Based Security (VBS) enclave.

RECONFIGURE;: Again, this command applies the changes made by the previous sp_configure command.

Will it change Server config settings?
Yes, these commands will change the server configuration settings. Specifically, they will:

Enable the display of advanced configuration options.
Set the column encryption enclave type to use a VBS enclave.
These changes can affect how SQL Server handles column encryption and may require a restart of the SQL Server instance to take full effect.