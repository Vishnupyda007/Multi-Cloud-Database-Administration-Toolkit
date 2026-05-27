--CONNECT TO CTSC01048403401\CRSSIT
--stop distribution cleanup & log reader agent jobs
--Right click on Replication folder in source-publisher properties-publication databases-enable the checkbox against the DB which we wish to enbale replication.


--1.create publication in CTSC01048403401\CRSSIT

use [CentralRepository]
	GO

	EXEC sp_addpublication
        @publication = N'CRS_MI_Backup_LSN_PUB', 
        @status = N'active',
        @allow_push = N'true',
        @allow_pull = N'true',
        @independent_agent = N'true',
		@immediate_sync = N'true',
		@allow_initialize_from_backup = N'true'

		EXEC sp_addpublication
        @publication = N'CRS_SITR1_Backup_LSN_PUB', 
        @status = N'active',
        @allow_push = N'true',
        @allow_pull = N'true',
        @independent_agent = N'true',
		@immediate_sync = N'true',
		@allow_initialize_from_backup = N'true'

--2. From GUI, add the articles for the newly create publication.
--3. disconnect all the sessions to the DB and take backup


BACKUP DATABASE [CentralRepository] TO URL = N'https://ctssqlmiprod.blob.core.windows.net/sqlmidbbkp/CentralRepository_CRSSIT_080620241400.bak' WITH COPY_ONLY,compression,BLOCKSIZE = 65536,  MAXTRANSFERSIZE = 4194304 , CHECKSUM, Stats =1

BACKUP DATABASE [CentralRepository] TO  DISK = N'F:\Backup\CentralRepository_CRSSIT_080620241400.bak' WITH NOFORMAT, NOINIT, SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 1
--BACKUP DATABASE [tests] TO  DISK = N'F:\Backup\Tests_CRSSIT_080620241400.bak' WITH NOFORMAT, NOINIT, SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 1

--4. Restore CentralRepository database on  destination Instances with same backup copy
--5. Execute below queries on CRS UAT for each Portfolio instances one at a time with order mentioned below

-- Take LastLsn column as LastLsnFromRestoreHeadersOnly

restore headeronly from url =  N'https://ctssqlmiprod.blob.core.windows.net/sqlmidbbkp/CentralRepository_CRSSIT_080620241400.bak' --9118000003065000001
restore headeronly from disk =  N'F:\Backup\CentralRepository_CRSSIT_080620241400.bak' --9118000003085000001

-- Convert LastLsn from numeric to binary (Check in master DB whether below function is available if not create 
use master
SELECT [dbo].[test_fn_convertnumericlsntobinary10](9118000003065000001) 'LastLsnAsBinary10' --Last LSN 0x0000239E000077BA0001

SELECT [dbo].[test_fn_convertnumericlsntobinary10](9118000003085000001) 'LastLsnAsBinary10'--0x0000239E000078820001
---------------For MI servers use below script -------------
			USE [CentralRepository]
			GO
			EXEC sp_addsubscription
			@publication = N'CRS_MI_Backup_LSN_PUB',--replace the publisher name
			@subscriber = N'CTSAZSIMISPLT01.INSO13DFBBBFA2150.DATABASE.WINDOWS.NET',-- replace the subscriber name
			@destination_db = N'CentralRepository',--Replace destination DB name
			@sync_type= N'initialize from lsn',
			@backupdevicetype='URL', 
			@backupdevicename=N'https://ctssqlmiprod.blob.core.windows.net/sqlmidbbkp/CentralRepository_CRSSIT_080620241400.bak',--use the backup url taken above
			@subscription_type = N'push',
			@subscriptionlsn = 0x0000239E000077BA0001, -- Remember to change this as per data/value from above step
			@update_mode = N'read only';

			Exec sp_addpushsubscription_agent
			@publication = N'CRS_MI_Backup_LSN_PUB',
			@subscriber = N'CTSAZSIMISPLT01.INSO13DFBBBFA2150.DATABASE.WINDOWS.NET', 
			@subscriber_db =N'CentralRepository',
			@job_login = N'crsdba',
			@job_password = 'crs@dmin2018',-- Remember to put the correct Password here.
			@subscriber_security_mode = 0,
			@subscriber_login = N'crsdba',
			@subscriber_password = 'crs@dmin2018', -- Remember to put the correct Password here.
			@dts_package_location = N'Distributor';

----------------------------------------------------------------------for OnPremise



            USE [CentralRepository]
			GO
			EXEC sp_addsubscription
			@publication = N'CRS_SITR1_Backup_LSN_PUB',
			@subscriber = N'10.127.124.137\SITR1,56380',
			@destination_db = N'CentralRepository_Report',
			@sync_type= N'initialize from lsn',
			@backupdevicetype='URL', 
			@backupdevicename=N'F:\Backup\CentralRepository_CRSSIT_080620241400.bak',
			@subscription_type = N'push',
			@subscriptionlsn = 0x0000239E000078820001, -- Remember to change this as per data/value from above step
			@update_mode = N'read only';

			Exec sp_addpushsubscription_agent
			@publication = N'CRS_SITR1_Backup_LSN_PUB',
			@subscriber = N'10.127.124.137\SITR1,56380', 
			@subscriber_db = N'CentralRepository_Report',
			--@job_login = N'Null',			***********-- For on premise comment @job_login & @job_password and  @subscriber_security_mode = 1
			--@job_password = 'Null',		***********-- Remember to put the correct Password here.
			@subscriber_security_mode = 1,
			@subscriber_login = N'Null',
			@subscriber_password = 'Null', -- Remember to put the correct Password here.
			@dts_package_location = N'Distributor';
---------------------------------------------------------------

--Step 8 : 

--Manually create Loadtest profile for all agents.
--Enable Distribution Cleanup Job.
--Start Log reader and Distribution agent on On-premise CRSSIT
--Enable trustworthy on all instances.
-- check auto fix for all the users&logins.
