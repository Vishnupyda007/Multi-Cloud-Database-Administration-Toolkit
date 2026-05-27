---We need to proceed for Publication Activity Post creation of Distribution Database and user profile parameters.
--Step-1: Create the Publication with Transaction Replication using snapshot named with EDS_DR_PPLT_SNAP_PUB and add the below mentioned table via GUI during the creation of Publication by changing the schema name with dbo.
 --table name--ESA_PS_PROJ_TYPE_TBL_STG_CURR.

--Step-2:
--Add the required Subscriber(s) for the Publication using GUI 
--Subscribers list : 
--ctsazdrmibcpplt.inso1a101c37461fa.database.windows.net


--Step-3: Post creation of Publication, run the below script to false the immediate sync and allow anonymous

EXEC sp_changepublication
@publication = N'EDS_DR_PPLT_SNAP_PUB',--
@property = N'allow_anonymous',
@value = 'FALSE'
GO
 
EXEC sp_changepublication
@publication = N'EDS_DR_PPLT_SNAP_PUB',--
@property = N'immediate_sync',
@value = 'FALSE'
GO



----Step-4: Add the articles using the below script for Gowsalya Phase-1
-- Adding the transactional articles --total of 14 articles for PPLT DR.

use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'CentralRepository_JOB_Reference_MIG', @source_owner = N'CRS_BASE_TBL', @source_object = N'CentralRepository_JOB_Reference_MIG', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'CentralRepository_JOB_Reference_MIG', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_CRS_BASE_TBLCentralRepository_JOB_Reference_MIG]', @del_cmd = N'CALL [sp_MSdel_CRS_BASE_TBLCentralRepository_JOB_Reference_MIG]', @upd_cmd = N'SCALL [sp_MSupd_CRS_BASE_TBLCentralRepository_JOB_Reference_MIG]'
GO



use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'Centralrepository_PRISM_Actuals_mig', @source_owner = N'CRS_BASE_TBL', @source_object = N'Centralrepository_PRISM_Actuals_mig', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'manual', @destination_table = N'Centralrepository_PRISM_Actuals_mig', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_CRS_BASE_TBLCentralrepository_PRISM_Actuals_mig]', @del_cmd = N'CALL [sp_MSdel_CRS_BASE_TBLCentralrepository_PRISM_Actuals_mig]', @upd_cmd = N'SCALL [sp_MSupd_CRS_BASE_TBLCentralrepository_PRISM_Actuals_mig]'
GO



use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'CentralRepository_Department_TreeMaster_MIG', @source_owner = N'CRS_BASE_TBL', @source_object = N'CentralRepository_Department_TreeMaster_MIG', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'CentralRepository_Department_TreeMaster_MIG', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_CRS_BASE_TBLCentralRepository_Department_TreeMaster_MIG]', @del_cmd = N'CALL [sp_MSdel_CRS_BASE_TBLCentralRepository_Department_TreeMaster_MIG]', @upd_cmd = N'SCALL [sp_MSupd_CRS_BASE_TBLCentralRepository_Department_TreeMaster_MIG]'
GO



use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'HCM_PS_CT_TM_TBL_GBL_STG_CURR', @source_owner = N'EDS_CURR_STG', @source_object = N'HCM_PS_CT_TM_TBL_GBL_STG_CURR', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'HCM_PS_CT_TM_TBL_GBL_STG_CURR', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_EDS_CURR_STGHCM_PS_CT_TM_TBL_GBL_STG_CURR]', @del_cmd = N'CALL [sp_MSdel_EDS_CURR_STGHCM_PS_CT_TM_TBL_GBL_STG_CURR]', @upd_cmd = N'SCALL [sp_MSupd_EDS_CURR_STGHCM_PS_CT_TM_TBL_GBL_STG_CURR]'
GO



use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'CentralRepository_PassportDetails_MIG', @source_owner = N'CRS_BASE_TBL', @source_object = N'CentralRepository_PassportDetails_MIG', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'CentralRepository_PassportDetails_MIG', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_CRS_BASE_TBLCentralRepository_PassportDetails_MIG]', @del_cmd = N'CALL [sp_MSdel_CRS_BASE_TBLCentralRepository_PassportDetails_MIG]', @upd_cmd = N'SCALL [sp_MSupd_CRS_BASE_TBLCentralRepository_PassportDetails_MIG]'
GO


use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'CentralRepository_Contracts', @source_owner = N'CRS_BASE_TBL', @source_object = N'CentralRepository_Contracts', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'CentralRepository_Contracts_EDS', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_CRS_BASE_TBLCentralRepository_Contracts]', @del_cmd = N'CALL [sp_MSdel_CRS_BASE_TBLCentralRepository_Contracts]', @upd_cmd = N'SCALL [sp_MSupd_CRS_BASE_TBLCentralRepository_Contracts]'
GO



use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'CENTRALREPOSITORY_CANDIDATEDETAILS_MIG', @source_owner = N'CRS_BASE_TBL', @source_object = N'CENTRALREPOSITORY_CANDIDATEDETAILS_MIG', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'CENTRALREPOSITORY_CANDIDATEDETAILS_MIG', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_CRS_BASE_TBLCENTRALREPOSITORY_CANDIDATEDETAILS_MIG]', @del_cmd = N'CALL [sp_MSdel_CRS_BASE_TBLCENTRALREPOSITORY_CANDIDATEDETAILS_MIG]', @upd_cmd = N'SCALL [sp_MSupd_CRS_BASE_TBLCENTRALREPOSITORY_CANDIDATEDETAILS_MIG]'
GO



use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'CentralRepository_ESA_ProjectSupervisor_MIG', @source_owner = N'CRS_BASE_TBL', @source_object = N'CentralRepository_ESA_ProjectSupervisor_MIG', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'CentralRepository_ESA_ProjectSupervisor_MIG', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_CRS_BASE_TBLCentralRepository_ESA_ProjectSupervisor_MIG]', @del_cmd = N'CALL [sp_MSdel_CRS_BASE_TBLCentralRepository_ESA_ProjectSupervisor_MIG]', @upd_cmd = N'SCALL [sp_MSupd_CRS_BASE_TBLCentralRepository_ESA_ProjectSupervisor_MIG]'
GO



use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'CentralRepository_Grade_Master_MIG', @source_owner = N'CRS_BASE_TBL', @source_object = N'CentralRepository_Grade_Master_MIG', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'CentralRepository_Grade_Master_MIG', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_CRS_BASE_TBLCentralRepository_Grade_Master_MIG]', @del_cmd = N'CALL [sp_MSdel_CRS_BASE_TBLCentralRepository_Grade_Master_MIG]', @upd_cmd = N'SCALL [sp_MSupd_CRS_BASE_TBLCentralRepository_Grade_Master_MIG]'
GO



use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'FMS_PS_DEPT_TBL_STG_CURR', @source_owner = N'EDS_CURR_STG', @source_object = N'FMS_PS_DEPT_TBL_STG_CURR', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'FMS_PS_DEPT_TBL_STG_CURR', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_EDS_CURR_STGFMS_PS_DEPT_TBL_STG_CURR]', @del_cmd = N'CALL [sp_MSdel_EDS_CURR_STGFMS_PS_DEPT_TBL_STG_CURR]', @upd_cmd = N'SCALL [sp_MSupd_EDS_CURR_STGFMS_PS_DEPT_TBL_STG_CURR]'
GO




use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'ESA_PS_CTSRM_LE_CRS_VW_STG_CURR', @source_owner = N'EDS_CURR_STG', @source_object = N'ESA_PS_CTSRM_LE_CRS_VW_STG_CURR', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'ESA_PS_CTSRM_LE_CRS_VW_STG_CURR', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_EDS_CURR_STGESA_PS_CTSRM_LE_CRS_VW_STG_CURR]', @del_cmd = N'CALL [sp_MSdel_EDS_CURR_STGESA_PS_CTSRM_LE_CRS_VW_STG_CURR]', @upd_cmd = N'SCALL [sp_MSupd_EDS_CURR_STGESA_PS_CTSRM_LE_CRS_VW_STG_CURR]'
GO



use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'HCM_PS_BUS_UNIT_TBL_HR_STG_CURR', @source_owner = N'EDS_CURR_STG', @source_object = N'HCM_PS_BUS_UNIT_TBL_HR_STG_CURR', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'HCM_PS_BUS_UNIT_TBL_HR_STG_CURR', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_EDS_CURR_STGHCM_PS_BUS_UNIT_TBL_HR_STG_CURR]', @del_cmd = N'CALL [sp_MSdel_EDS_CURR_STGHCM_PS_BUS_UNIT_TBL_HR_STG_CURR]', @upd_cmd = N'SCALL [sp_MSupd_EDS_CURR_STGHCM_PS_BUS_UNIT_TBL_HR_STG_CURR]'
GO



use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'ESA_PS_PGM_APPLICATION_STG_CURR', @source_owner = N'EDS_CURR_STG', @source_object = N'ESA_PS_PGM_APPLICATION_STG_CURR', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'ESA_PS_PGM_APPLICATION_STG_CURR', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_EDS_CURR_STGESA_PS_PGM_APPLICATION_STG_CURR]', @del_cmd = N'CALL [sp_MSdel_EDS_CURR_STGESA_PS_PGM_APPLICATION_STG_CURR]', @upd_cmd = N'SCALL [sp_MSupd_EDS_CURR_STGESA_PS_PGM_APPLICATION_STG_CURR]'
GO



use [ent_data_store]
exec sp_addarticle @publication = N'EDS_DR_PPLT_SNAP_PUB', @article = N'ESA_PS_CTS_GRADE_ROLE_STG_CURR', @source_owner = N'EDS_CURR_STG', @source_object = N'ESA_PS_CTS_GRADE_ROLE_STG_CURR', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x000000000803509F, @identityrangemanagementoption = N'none', @destination_table = N'ESA_PS_CTS_GRADE_ROLE_STG_CURR', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [sp_MSins_EDS_CURR_STGESA_PS_CTS_GRADE_ROLE_STG_CURR]', @del_cmd = N'CALL [sp_MSdel_EDS_CURR_STGESA_PS_CTS_GRADE_ROLE_STG_CURR]', @upd_cmd = N'SCALL [sp_MSupd_EDS_CURR_STGESA_PS_CTS_GRADE_ROLE_STG_CURR]'
GO



--Step-5:
EXEC sp_refreshsubscriptions @publication = N'EDS_DR_PPLT_SNAP_PUB'



--Step-6:
--Right click on the publication 'EDS_DR_PPLT_SNAP_PUB' and start the snapshot agent. Monitor the Distribution from Replication Monitor.