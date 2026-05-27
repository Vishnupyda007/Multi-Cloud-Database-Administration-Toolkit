CREATE TABLE [dbo].[#Managed_Instance_Failover_Group_Lag](
	[Repli_endpoint_url] [nvarchar](1000) NULL,
	[Last_Hardened_Lsn] [nvarchar](1000) NULL,
	[Last_Redone_Lsn] [nvarchar](1000) NULL,
	[Redo_Queue_Size] [nvarchar](1000) NULL,
	[Catchup_Progress] nvarchar(200),
	[End_of_log_lsn]  [nvarchar](1000) NULL,
	[internal_state_desc] nvarchar(100),
	[database_state_desc] nvarchar(100),
	[partner_database] nvarchar(200),
	[ReplicationLag] int,
	[displaySeverity] varchar(25))
	
DECLARE @name VARCHAR(50) -- database name 

DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM MASTER.dbo.sysdatabases 
WHERE name NOT IN ('master','model','msdb','tempdb') 

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
      -- Start
	  
-- input
DECLARE @db_name VARCHAR(128) = @name
--

DECLARE @groupid UNIQUEIDENTIFIER

SELECT TOP 1 @groupid = group_id 
FROM sys.dm_hadr_database_replica_states
WHERE DB_NAME(database_id) = @db_name
 
 
DECLARE @minlsn NUMERIC(38,0)
DECLARE @maxlsn NUMERIC(38,0)
DECLARE @logprogresssize_p NUMERIC(38,0)
 
-- Compute min and max lsns
SELECT @minlsn = CONVERT(NUMERIC(38,0), truncation_lsn), @maxlsn = CONVERT(NUMERIC(38,0), last_hardened_lsn) 
       FROM sys.dm_hadr_database_replica_states 
       WHERE is_primary_replica = 'true' AND (group_id=@groupid OR group_database_id=@groupid);
 
-- Handle NULL
SELECT @minlsn = 
                     CASE WHEN @minlsn IS NULL THEN 0 
                           ELSE @minlsn END,
              @maxlsn = 
                     CASE WHEN @maxlsn IS NULL THEN 0 
                           ELSE @maxlsn END
 
-- Compute log progress of the primary
SELECT @logprogresssize_p = 
                     CASE WHEN @maxlsn - @minlsn !=0 THEN @maxlsn - @minlsn 
                           ELSE 0 END;
 
-- HADRON DMV
WITH HadronDMV AS
(
       SELECT *, 
        CASE WHEN last_hardened_lsn > @minlsn AND @logprogresssize_p > 0 THEN (CONVERT(NUMERIC(38,0), last_hardened_lsn) - @minlsn)*100.0/@logprogresssize_p 
            ELSE 0 END AS logprogresssize 
    FROM sys.dm_hadr_database_replica_states 
    WHERE group_id=@groupid OR group_database_id=@groupid
)
 
 
insert into [#Managed_Instance_Failover_Group_Lag] 
SELECT        CASE WHEN replication_endpoint_url IS NULL AND (synchronization_state = 1  OR fccs.partner_server IS NOT NULL) THEN fccs.partner_server + ' - ' + fccs.partner_database -- Geo replicas will be in Synchronizing state
                     ELSE replication_endpoint_url END AS replication_endpoint_url,
              last_hardened_lsn,
              last_redone_lsn,
              redo_queue_size,
              CASE WHEN seedStats.internal_state_desc IS NOT NULL -- Check for active seeding
                           THEN 'Seeding'
                     WHEN @logprogresssize_p > 0
                           THEN CASE WHEN logprogresssize <= 100 THEN '[' + REPLICATE('|', CONVERT(INT, logprogresssize)/4) + REPLICATE('.', CONVERT(INT, 100 - logprogresssize)/4) + '] ' ELSE '' END + CONVERT(VARCHAR(100), CONVERT(NUMERIC(20,2),logprogresssize)) + '%' 
                     ELSE 'Select the Primary Node' END AS catchup_progress,
              end_of_log_lsn, frs.internal_state_desc, database_state_desc, fccs.partner_database--, *
			  , secondary_lag_seconds AS ReplicationLag,
              CASE WHEN seedStats.internal_state_desc NOT IN ('Success', 'Failed') OR synchronization_health = 1 THEN 'Warning' ELSE
                     (CASE WHEN synchronization_state = 0 OR synchronization_health != 2 THEN 'ERROR' ELSE 'OK' END) END AS displaySeverity
       FROM HadronDMV
              LEFT JOIN sys.dm_hadr_fabric_replica_states frs 
                     ON HadronDMV.replica_id = frs.replica_id
              LEFT OUTER JOIN sys.dm_hadr_physical_seeding_stats seedStats
                     ON seedStats.remote_machine_name = replication_endpoint_url
                     AND (seedStats.local_database_name = @groupid OR seedStats.local_database_name = 'tpcc5000A')
                     AND seedStats.internal_state_desc NOT IN ('Success', 'Failed')
              LEFT OUTER JOIN sys.dm_hadr_fabric_continuous_copy_status fccs
                     ON HadronDMV.group_database_id = fccs.copy_guid
					 
       ORDER BY 
              CASE WHEN fabric_replica_role = 2 THEN 0 
                     ELSE 1 END ASC,
              CASE WHEN replication_endpoint_url IS NULL THEN 1 
                     ELSE 0 END ASC;




	  --End

      FETCH NEXT FROM db_cursor INTO @name 
END 
CLOSE db_cursor  
DEALLOCATE db_cursor 

create table #Logspace(
sno int identity (1,1) primary key,
DBName varchar(300),
LogSize decimal(9,2),
LogUsedPercent decimal(9,2),
status int)

insert into #Logspace
exec ('dbcc sqlperf(logspace)')


----select * from [#Managed_Instance_Failover_Group_Lag] where  (ReplicationLag>-1 and catchup_progress NOT LIKE '%100.00%') OR (ReplicationLag IS NULL and displaySeverity = 'ERROR')
--select * from [#Managed_Instance_Failover_Group_Lag] 
--where  (ReplicationLag>-1) OR (ReplicationLag IS NULL and displaySeverity = 'ERROR')


select a.*,b.LogSize,b.LogUsedPercent from [#Managed_Instance_Failover_Group_Lag] a INNER JOIN #Logspace b ON (a.partner_database = b.DBName)
---where  (a.ReplicationLag>180 and a.catchup_progress NOT LIKE '%100.00%' and b.LogUsedPercent>70) OR (a.ReplicationLag IS NULL and a.displaySeverity = 'ERROR')

drop table [#Managed_Instance_Failover_Group_Lag]
drop table #Logspace