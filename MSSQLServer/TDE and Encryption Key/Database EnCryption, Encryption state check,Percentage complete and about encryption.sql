 --============================ ENABLE DATABASE ENCRYPTION ============================

ALTER DATABASE <DB>
SET ENCRYPTION ON;
GO


--===============Disbale Encryption=======================

alter database [DB_name] set encryption off --run this, once 100% completed, then drop the database Encryption key using below query, if we dont do the below step, then database wont be restore in destination server with different TDE Key.
use [DB_name];
DROP DATABASE ENCRYPTION KEY



--============================ CHECK FOR DATABASE ENCRYPTION ============================

SELECT
    DB_NAME(database_id) AS DatabaseName,
    encryption_state AS EncryptionState
FROM
    sys.dm_database_encryption_keys;




---------------------To check how much percentage Encryption completed-------------------
Select db_name(database_id),encryption_state,percent_complete from sys.dm_database_encryption_keys




-------------------------------------------------------
SELECT DB_NAME(database_id) AS DatabaseName, encryption_state,
encryption_state_desc =
CASE encryption_state
         WHEN '0'  THEN  'No database encryption key present, no encryption'
         WHEN '1'  THEN  'Unencrypted'
         WHEN '2'  THEN  'Encryption in progress'
         WHEN '3'  THEN  'Encrypted'
         WHEN '4'  THEN  'Key change in progress'
         WHEN '5'  THEN  'Decryption in progress'
         WHEN '6'  THEN  'Protection change in progress (The certificate or asymmetric key that is encrypting the database encryption key is being changed.)'
         ELSE 'No Status'
         END,
percent_complete,encryptor_thumbprint, encryptor_type ,key_algorithm,key_length,* FROM sys.dm_database_encryption_keys





---------------------------------------------------------------
--How to monitor and manage Transparent Data Encryption (TDE) in SQL Server
--July 13, 2018 by Sreekanth Bandarla
--SQL server Quest banner
--Transparent Data Encryption (TDE) was originally introduced in SQL Server 2008 (Enterprise Edition) with a goal to protect SQL Server data at rest. In other words, the physical data and log files along with the database backup sitting on file system are protected (encrypted).

--Few things to be aware of when implementing TDE:
--With TDE, The data transmitted over the network is not encrypted and the data at the object level remains unencrypted. In other words, if a user has select access to a table(s) within the TDE enabled database, he/she will be able to read data with simple select statements, as the name suggests, it’s transparent. TDE does not protect FILESTREAM data and any files related to Buffer Pool Extension (BPE) are not encrypted as well, you should use file system encryption tools like windows BitLocker or any other third party tools for this purpose. Another caveat is TDE doesn’t support Instant File Initialization for database files. Also, when TDE is enabled on a user database your tempdb database gets encrypted behind the scenes.

--Okay, let’s move on to our topic. In this article, we will see how to monitor and manage TDE progress, not essentially how to setup TDE on a user database. Before moving on to our main topic, here is a quick refresher on how Transparent Data Encryption works.


*********
TDE isn't available for system databases. It can't be used to encrypt master, model, or msdb. tempdb is automatically encrypted when a user database enabled TDE, but can't be encrypted directly. TDE doesn't provide encryption across communication channels.



--Image Source: Transparent Data Encryption (TDE)
--Enabling TDE on a given database is a very straightforward process. 20,000-foot view of the process is basically creating a DMK (Master DB) which is protected by Service Master Key, Cert (Master DB), DEK (User DB) and enable TDE(User DB) and you are done. But things get little tricky when you are dealing with VLDBs. What if you have a ginormous database (Let’s say a 30 TeraBytes monster) on which you have to enable TDE? Enabling TDE is not instantaneous, the SQL Server Encryption Scanner has to read all the underlying database pages and encrypt them, For a 30 TB database it might take multiple days for SQL Server to encrypt the entire database and we as DBAs should monitor the encryption progress making sure there are no side effects. In this context I am not talking about server resources, I am talking about the impact on the transaction log file when encryption scanner is in progress. So, why should we worry about LDF file when TDE scanner is in progress? Well, SQL Server doesn’t truncate the transaction log file of your database when TDE Encryption Scanner is doing its job. Things get more complicated if you are not allowed to run TDE during business hours and let’s say you have nightly ETL loads or some other scheduled job(s) which generates a considerable amount of log records. In this article, let’s see how to monitor TDE progress and how to manage transaction log when TDE scanner is in progress.

--Things to monitor when TDE is in progress:
--Disk IO and CPU usage.
--Keep an eye on blocking – Encryption_Scan resource can cause blocking.
--Last but not the least, keep an eye on your T-Log. As mentioned earlier, when TDE scanner is running the T-Log can’t be truncated. In other words, the log file might grow larger than normal, something to watch out if your server is storage constrained.
--How to monitor TDE Progress:
--SQL Server keeps track of the encryption progress and we can pull that information by querying sys.dm_database_encryption_keys. Particularly ‘Percent_Complete’ and ‘encryption_state’ are the two columns which are required to understand the progress of TDE. ‘Encryption_state’ column returns an integer value (0-6) which indicates the encryption status of the database and ‘percent_complete’ column tells us percent complete of the DB encryption state change.

--Encryption_state(int)	Description
--0	No database encryption key present, no encryption
--1	Unencrypted
--2	Encryption in progress
--3	Encrypted
--4	Key change in progress
--5	Decryption in progress
--6	Protection change in progress (The certificate or asymmetric key that is encrypting the database encryption key is being changed)
