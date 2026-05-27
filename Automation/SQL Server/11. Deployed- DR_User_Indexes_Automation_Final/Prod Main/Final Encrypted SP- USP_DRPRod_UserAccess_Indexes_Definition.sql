USE [1CDBAMonitoring]
GO

/****** Object:  StoredProcedure [dbo].[USP_DRPRod_UserAccess_Indexes_Definition]    Script Date: 7/4/2025 12:17:00 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:<Vishnu P,,2275509>
-- Create date: <27-01-2026,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[USP_DRPRod_UserAccess_Indexes_Definition] with Encryption
	
AS

BEGIN
	
--To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  

-- To update the currently configured value for advanced options.  
RECONFIGURE;  

-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  

-- To update the currently configured value for this feature.  
RECONFIGURE;  

DECLARE @sql1 VARCHAR(8000);
DECLARE @sql2 VARCHAR(8000);
DECLARE @sql3 VARCHAR(8000);
DECLARE @sql4 VARCHAR(8000);
DECLARE @sql5 VARCHAR(8000);
DECLARE @sql6 VARCHAR(8000);
DECLARE @sql7 VARCHAR(8000);
DECLARE @sql8 VARCHAR(8000);
DECLARE @sql9 VARCHAR(8000);
DECLARE @sql10 VARCHAR(8000);
DECLARE @sql11 VARCHAR(8000);
DECLARE @sql12 VARCHAR(8000);
DECLARE @sql13 VARCHAR(8000);
DECLARE @sql14 VARCHAR(8000);
DECLARE @sql15 VARCHAR(8000);
DECLARE @sql16 VARCHAR(8000);
DECLARE @sql17 VARCHAR(8000);
DECLARE @sql18 VARCHAR(8000);


DECLARE @sql19 VARCHAR(8000);
DECLARE @sql20 VARCHAR(8000);
DECLARE @sql21 VARCHAR(8000);
DECLARE @sql22 VARCHAR(8000);
DECLARE @sql23 VARCHAR(8000);
DECLARE @sql24 VARCHAR(8000);
DECLARE @sql25 VARCHAR(8000);
DECLARE @sql26 VARCHAR(8000);
DECLARE @sql27 VARCHAR(8000);
DECLARE @sql28 VARCHAR(8000);
DECLARE @sql29 VARCHAR(8000);
DECLARE @sql30 VARCHAR(8000);
DECLARE @sql31 VARCHAR(8000);
DECLARE @sql32 VARCHAR(8000);
DECLARE @sql33 VARCHAR(8000);
DECLARE @sql34 VARCHAR(8000);
DECLARE @sql35 VARCHAR(8000);
DECLARE @sql36 VARCHAR(8000);


DECLARE @sql37 VARCHAR(8000);
DECLARE @sql38 VARCHAR(8000);
DECLARE @sql39 VARCHAR(8000);
DECLARE @sql40 VARCHAR(8000);
DECLARE @sql41 VARCHAR(8000);
DECLARE @sql42 VARCHAR(8000);
DECLARE @sql43 VARCHAR(8000);
DECLARE @sql44 VARCHAR(8000);
DECLARE @sql45 VARCHAR(8000);
DECLARE @sql46 VARCHAR(8000);
DECLARE @sql47 VARCHAR(8000);
DECLARE @sql48 VARCHAR(8000);
DECLARE @sql49 VARCHAR(8000);
DECLARE @sql50 VARCHAR(8000);
DECLARE @sql51 VARCHAR(8000);
DECLARE @sql52 VARCHAR(8000);
DECLARE @sql53 VARCHAR(8000);
DECLARE @sql54 VARCHAR(8000);


SELECT @sql1 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_43076]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_43076.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql2 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_4533]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_4533.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql3 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_BCApps1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_BCApps1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql4 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_BCApps2]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_BCApps2.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql5 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_BCApps3]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_BCApps3.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql6 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_DE1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_DE1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql7 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_MC1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_MC1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql8 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_NC1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_NC1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql9 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_NC2]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_NC2.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql10 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_PFD]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_PFD.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql11 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_PGN]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_PGN.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql12 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_PPLT]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_PPLT.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql13 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_PRDML01]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_PRDML01.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql14 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_PST]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_PST.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql15 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_PTM]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_PTM.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql16 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_PTM1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_PTM1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql17 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_R1Cloud]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_R1Cloud.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql18 = 'bcp "SELECT createrolescript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Servers_Roles_Tbl_4582]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Server_Roles\MI_Servers_Roles_DDLs_4582.txt" -w -t, -T -S CTSINAZSIPDDB06'




SELECT @sql19 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_43076]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_43076.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql20 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_4533]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_4533.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql21 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_BCApps1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_BCApps1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql22 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_BCApps2]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_BCApps2.txt" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql23 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_BCApps3]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_BCApps3.txt" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql24 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_DE1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_DE1.txt" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql25 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_MC1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_MC1.txt" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql26 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_NC1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_NC1.txt" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql27 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_NC2]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_NC2.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql28 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_PFD]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_PFD.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql29 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_PGN]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_PGN.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql30 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_PPLT]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_PPLT.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql31 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_PRDML01]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_PRDML01.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql32 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_PST]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_PST.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql33 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_PTM]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_PTM.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql34 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_PTM1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_PTM1.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql35 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_R1Cloud]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_R1Cloud.txt" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql36 = 'bcp "SELECT createscript FROM [1CDBAMonitoring].[dbo].[DRscripts_MI_Users_Roles_Tbl_4582]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\User_Access\User_Access_DDLs_4582.txt" -w -t, -T -S CTSINAZSIPDDB06'


SELECT @sql37 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_43076]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_43076.csv" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql38 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_4533]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_4533.csv" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql39 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_BCApps1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_BCApps1.csv" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql40 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_BCApps2]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_BCApps2.csv" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql41 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_BCApps3]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_BCApps3.csv" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql42 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_DE1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_DE1.csv" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql43 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_MC1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_MC1.csv" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql44 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_NC1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_NC1.csv" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql45 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_NC2]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_NC2.csv" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql46 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_PFD]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_PFD.csv" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql47 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_PGN]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_PGN.csv" -w -t, -T -S CTSINAZSIPDDB06'
		   
SELECT @sql48 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_PPLT]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_PPLT.csv" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql49 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_PRDML01]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_PRDML01.csv" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql50 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_PST]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_PST.csv" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql51 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_PTM]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_PTM.csv" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql52 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_PTM1]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_PTM1.csv" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql53 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_R1Cloud]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_R1Cloud.csv" -w -t, -T -S CTSINAZSIPDDB06'

SELECT @sql54 = 'bcp "SELECT Table_Name,Index_Details FROM [1CDBAMonitoring].[dbo].[vw_DRMI_Index_Tbl_4582]" queryout "E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup\Indexes\Indexes_DDLs_4582.csv" -w -t, -T -S CTSINAZSIPDDB06'



exec master..xp_cmdshell @sql1 
exec master..xp_cmdshell @sql2 
exec master..xp_cmdshell @sql3 
exec master..xp_cmdshell @sql4 
exec master..xp_cmdshell @sql5 
exec master..xp_cmdshell @sql6 
exec master..xp_cmdshell @sql7 
exec master..xp_cmdshell @sql8 
exec master..xp_cmdshell @sql9 
exec master..xp_cmdshell @sql10
exec master..xp_cmdshell @sql11
exec master..xp_cmdshell @sql12
exec master..xp_cmdshell @sql13
exec master..xp_cmdshell @sql14
exec master..xp_cmdshell @sql15
exec master..xp_cmdshell @sql16
exec master..xp_cmdshell @sql17
exec master..xp_cmdshell @sql18


exec master..xp_cmdshell @sql19 
exec master..xp_cmdshell @sql20 
exec master..xp_cmdshell @sql21 
exec master..xp_cmdshell @sql22 
exec master..xp_cmdshell @sql23 
exec master..xp_cmdshell @sql24 
exec master..xp_cmdshell @sql25 
exec master..xp_cmdshell @sql26 
exec master..xp_cmdshell @sql27 
exec master..xp_cmdshell @sql28
exec master..xp_cmdshell @sql29
exec master..xp_cmdshell @sql30
exec master..xp_cmdshell @sql31
exec master..xp_cmdshell @sql32
exec master..xp_cmdshell @sql33
exec master..xp_cmdshell @sql34
exec master..xp_cmdshell @sql35
exec master..xp_cmdshell @sql36



exec master..xp_cmdshell @sql37
exec master..xp_cmdshell @sql38 
exec master..xp_cmdshell @sql39 
exec master..xp_cmdshell @sql40 
exec master..xp_cmdshell @sql41 
exec master..xp_cmdshell @sql42 
exec master..xp_cmdshell @sql43 
exec master..xp_cmdshell @sql44 
exec master..xp_cmdshell @sql45 
exec master..xp_cmdshell @sql46
exec master..xp_cmdshell @sql47
exec master..xp_cmdshell @sql48
exec master..xp_cmdshell @sql49
exec master..xp_cmdshell @sql50
exec master..xp_cmdshell @sql51
exec master..xp_cmdshell @sql52
exec master..xp_cmdshell @sql53
exec master..xp_cmdshell @sql54



DECLARE @filenames varchar(max)

Set @filenames='E:\1CDBA_Data_Donot_Delete\1C_Prod_DR_User_Access_Indexes_Backup.zip'
EXEC xp_cmdshell 'powershell.exe -ExecutionPolicy Bypass -File "E:\1CDBA_Data_Donot_Delete\Extract_1C_Prod_DR_User_Access_Indexes_Backup.ps1"'
 


-- Send the email
EXEC msdb.dbo.sp_send_dbmail
  @profile_name = 'ITOps1CDBA',
  --@recipients='EDSDev@cognizant.com;EDSRequirementTeam@cognizant.com',
  @recipients= 'CRSDBASUPPORT@cognizant.com;EDMDBA@cognizant.com',
  --@copy_recipients='VijaiAnand.PV@cognizant.com;KiranKumar.Gannavaram@cognizant.com;
  --Ashwathi.K@cognizant.com;BalaKrishna.Mannepalli@cognizant.com;2275509@cognizant.com',
  --@copy_recipients='2275509@cognizant.com',

  @subject = 'Automated Mailer: DR User Access,User Roles, Indexes DDL Scripts || Prod Portfolio Servers',
  @body = '
<html>
  <body style="font-family:serif;">
    Hi Team,<br><br>
    Please find the latest <b>User Access,Users and Index DDLs</b> extracted from the <b>1C Prod MI Portfolio Servers</b>. Please find the below list of Prod Portfolio Servers.<br><br> 
<table border="1"  style="border-collapse: collapse; font-family: serif; width: 100%;border:1px solid black;text-align: center;padding: 3px;font-size: 10.5pt;">
  <thead>
    <tr style="background: #87ceeb;">
      <th><strong>Server Name</strong></th>
      <th><strong>Database Name</strong></th>
    </tr>
  </thead>
  <tbody>
    <tr><td>ctsazsimibcapps1.inso1a101c37461fa.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazsimibcapps2.inso1a101c37461fa.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazmibcapps3.293366d454bb.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazsimipst.inso1a101c37461fa.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazsimipplt.inso1a101c37461fa.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazsimiptm.inso1a101c37461fa.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazsimipfd.inso1a101c37461fa.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazsimipgn.inso1a101c37461fa.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazpdmincapps1.b96303a221dc.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazpdmincapps2.b96303a221dc.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazsimipddeapps1.293366d454bb.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>CTSAZSIMIPRDML01.293366D454BB.DATABASE.WINDOWS.NET</td><td>CentralRepository</td></tr>
    <tr><td>ctsazsimiptm1.293366d454bb.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazsimimcapps1.293366d454bb.database.windows.net</td><td>CentralRepository</td></tr>
    <tr><td>ctsazmipdpcrsr1.inso1a101c37461fa.database.windows.net</td><td>CentralRepository_Report</td></tr>
    <tr><td>CPCINCHPV004582</td><td>CentralRepository</td></tr>
    <tr><td>CPCINCHPV004533</td><td>CentralRepository</td></tr>
    <tr><td>CAZINSIPV143076</td><td>CentralRepository</td></tr>
  </tbody>
</table>
    <br>Note: If you require the most up-to-date DDLs for analysis or reference, please utilize the attached file.<br><br><br><br>
    Regards,<br><b>ITOps 1CDBA Team</b>
  </body>
</html>',

    @body_format = 'HTML',

  @file_attachments = @filenames;



END
GO


