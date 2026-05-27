-- Recommended indexes for performance
CREATE NONCLUSTERED INDEX IX_MI_Prod_DB_Capacity_Report_Server_DB_Name_Date
ON MI_Prod_DB_Capacity_Report (ServerName, DBName, Name, Datetime);

CREATE NONCLUSTERED INDEX IX_MI_Prod_DB_Capacity_Daily_STG_Server_DB_Name_Date
ON MI_Prod_DB_Capacity_Daily_STG (ServerName, DBName, Name, Datetime);

CREATE NONCLUSTERED INDEX IX_ApplicationInventory_Server_DB
ON ApplicationInventory (ServerName, DatabaseName, AppPoC, ApplicationName);