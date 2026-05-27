[dbo].[sp_syspolicy_purge_history]-- use of this sp in msdb
Copilot said:
Copilot
The stored procedure [dbo].[sp_syspolicy_purge_history] in the msdb database is used to remove policy evaluation history according to the history retention interval setting. This is part of SQL Server's Policy-Based Management feature.

Key Points:
Purpose: It purges the policy evaluation history to help manage the size of the msdb database and ensure that old, unnecessary data is removed.

Usage: This stored procedure does not take any parameters and must be run in the context of the msdb database.

Example:

USE msdb;
GO
EXEC sp_syspolicy_purge_history;
GO
History Retention Interval: The retention interval determines how long the policy evaluation history is kept. You can view the current retention interval with the following query:

SELECT current_value 
FROM msdb.dbo.syspolicy_configuration 
WHERE name = N'HistoryRetentionInDays';
GO
Permissions: Requires membership in the PolicyAdministratorRole fixed database role1.

This procedure helps maintain the msdb database by removing old policy evaluation records, which can improve performance and manage database size. If you have any specific questions or need further assistance, feel free to ask!

1: Microsoft Learn - sp_syspolicy_purge_history (Transact-SQL)


1
Favicon type
sp_syspolicy_purge_history (Transact-SQL) - SQL Server

Edit in Pages





AI-generated content may be incorrect
You said:

How often should I run this SP?
Copilot said:
Copilot
The frequency of running the [dbo].[sp_syspolicy_purge_history] stored procedure depends on your specific environment and the volume of policy evaluations. Here are some general guidelines:

Default Schedule: By default, SQL Server sets up a SQL Server Agent job to run this stored procedure daily at 2 AM1. This is usually sufficient for most environments.

High Activity Environments: If you have a high volume of policy evaluations, you might consider running it more frequently, such as multiple times a day.

Low Activity Environments: For environments with low policy evaluation activity, running it weekly or monthly might be adequate.

Monitoring and Adjusting: Regularly monitor the size of your policy evaluation history and adjust the frequency as needed. If you notice the history growing too large, you might need to increase the frequency of purging1.

Example Schedule:
Daily: Default and recommended for most environments.
Multiple Times a Day: For high activity environments.
Weekly/Monthly: For low activity environments.
Always ensure that the history retention interval is set appropriately to retain the necessary history data for auditing and compliance purposes. You can check the current retention interval with the following query:

SELECT current_value 
FROM msdb.dbo.syspolicy_configuration 
WHERE name = N'HistoryRetentionInDays';
GO
If you have any specific requirements or need further assistance, feel free to ask!

1: Microsoft Learn - sp_syspolicy_purge_history (Transact-SQL)


1
Favicon type
syspolicy_purge_history _ how to tell if it's working
