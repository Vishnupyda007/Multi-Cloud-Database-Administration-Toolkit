--USE [master]
--RESTORE DATABASE [CentralRepository_Report] FROM  DISK = N'E:\BAckup_DSP_SITR1\BAckup_DSP_SITR1\CentralREpository_DSP.bak' WITH  FILE = 1,  MOVE N'CentralRepository_DSP' TO N'D:\MSSQL11.MSSQLSERVER\MSSQL\Data\CentralRepository_Report.mdf',  MOVE N'CentralRepository_DSP_log' TO N'D:\MSSQL11.MSSQLSERVER\MSSQL\Data\CentralRepository_Report_log.ldf',  NOUNLOAD,  STATS = 5

GO
