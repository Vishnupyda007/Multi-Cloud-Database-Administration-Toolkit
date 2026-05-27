Final Query-------

USE [DBAdmin]
IF OBJECT_ID('dbo.Non_Prod_Replication_Status_Report','U') IS NOT NULL
truncate table DBAdmin.dbo.Non_Prod_Replication_Status_Report
go
EXEC [CTSC01048403401\CRSSIT].distribution.sys.sp_replmonitorhelpsubscription @publication_type=0
INSERT into DBAdmin.dbo.Non_Prod_Replication_Status_Report
EXEC [CTSC01048403401\CRSSIT].distribution.sys.sp_replmonitorhelpsubscription @publication_type = 0
go
EXEC distribution.sys.sp_replmonitorhelpsubscription @publication_type=0
INSERT DBAdmin.dbo.Non_Prod_Replication_Status_Report
EXEC distribution.sys.sp_replmonitorhelpsubscription @publication_type = 0
go
--select * from DBAdmin.dbo.Non_Prod_Replication_Status_Report




---------------------final query--------------

USE [DBAdmin]
IF OBJECT_ID('dbo.Non_Prod_Replication_Status_Report','U') IS NOT NULL
truncate table DBAdmin.dbo.Non_Prod_Replication_Status_Report
go
EXEC [CTSC01048403401\CRSSIT].distribution.sys.sp_replmonitorhelpsubscription @publication_type=0
INSERT into DBAdmin.dbo.Non_Prod_Replication_Status_Report
EXEC [CTSC01048403401\CRSSIT].distribution.sys.sp_replmonitorhelpsubscription @publication_type = 0
go
EXEC distribution.sys.sp_replmonitorhelpsubscription @publication_type=0
INSERT DBAdmin.dbo.Non_Prod_Replication_Status_Report
EXEC distribution.sys.sp_replmonitorhelpsubscription @publication_type = 0
go
--select * from DBAdmin.dbo.Non_Prod_Replication_Status_Report

--select * from DBAdmin.dbo.Non_Prod_Replication_Status_Report
