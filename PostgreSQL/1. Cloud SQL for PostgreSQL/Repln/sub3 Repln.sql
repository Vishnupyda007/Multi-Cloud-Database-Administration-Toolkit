CREATE USER replication_user WITH REPLICATION
IN ROLE cloudsqlsuperuser LOGIN PASSWORD 'postgresRepln@2026';

grant all on database "Repln_Sub3_PoC" to replication_user; --replication user should have create and usage in schema and insert,update,delete.truncate and select on all the tables

CREATE EXTENSION pglogical;

CREATE SUBSCRIPTION "LogicalRepln_Demo_Sub"
CONNECTION 'host=10.75.154.10 port=5432 dbname=Repln_Sub_PoC user=replication_user password=postgresRepln@2026 sslmode=require'
PUBLICATION "LogicalRepln_Demo_Pub"
WITH (create_slot = true, copy_data = true, enabled = true);



-- Register the subscriber node
SELECT pglogical.create_node(
  node_name := 'sub2_node',
  dsn := 'host=10.75.151.3 port=5432 dbname=Repln_Sub3_PoC user=replication_user password=postgresRepln@2026 sslmode=require'
);

select * from pglogical.node;

SELECT pglogical.drop_node(
  node_name := 'sub_node',
  ifexists := true
);

-- Create subscription from subscriber -> publisher
-- On subscriber
SELECT pglogical.drop_subscription('sub_to_pub4', true);  -- true = drop the slot as well
SELECT pglogical.create_subscription(
  subscription_name := 'sub_to_pub4',
  provider_dsn      := 'host=10.75.154.10 port=5432 dbname=Repln_Test user=replication_user password=postgresRepln@2026 sslmode=prefer',
  replication_sets  := ARRAY['sub4_DEV'],
  synchronize_structure := false,   -- you manage schema on subscriber
  synchronize_data  := true         -- initial copy
);

-- Then check: -- to check sub status
SELECT * FROM pglogical.show_subscription_status('sub_to_pub3');
SELECT * FROM pglogical.show_subscription_status();

SELECT * FROM pglogical.subscription;


-- Publications
SELECT * FROM pg_publication;


--TRUNCATE pglogical.local_sync_status;

-- Publication tables
SELECT * FROM pg_publication_tables WHERE pubname = 'LogicalRepln_Demo_Pub';

-- Active subscriber sessions (will appear only after a subscription connects)
SELECT * FROM pg_stat_replication;

-- Slots created by subscribers
SELECT * FROM pg_replication_slots;


-----to check sync status of tables,  i = init, d = copying, s = synchronized, r = replicating, u- unsynchronizing

SELECT * FROM pglogical.local_sync_status; --1.35

--delete from pglogical.local_sync_status where  sync_relname='esa_ps_item_activity_stg_curr_tmp'

--select count(*) from "esa_ps_item_activity_stg_curr_tmp" --added at 9.01pm
--truncate table esa_ps_item_activity_stg_curr_tmp
--truncate table public."CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP"
select count(*) from public."CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP"

SELECT
  n.nspname AS schema_name,
  c.relname AS table_name,
  sr.sync_status
FROM pglogical.local_sync_status sr
JOIN pg_class c ON c.oid = sr.sync_subid
JOIN pg_namespace n ON n.oid = c.relnamespace
ORDER BY schema_name, table_name;


SELECT
  CASE sync_kind
    WHEN 'i' THEN 'Init'
    WHEN 'f' THEN 'Full'
    WHEN 's' THEN 'Structure'
    WHEN 'd' THEN 'Data'
    ELSE 'Unknown'
  END AS sync_kind,
  sync_nspname || '.' || sync_relname AS relation,
  CASE sync_status
    WHEN '\0' THEN 'No sync'
    WHEN 'i'  THEN 'Ask for sync'
    WHEN 's'  THEN 'Sync structure'
    WHEN 'd'  THEN 'Data sync in progress'
    WHEN 'c'  THEN 'Constraint sync (post-data)'
    WHEN 'w'  THEN 'Waiting for OK from main thread'
    WHEN 'u'  THEN 'Catching up'
    WHEN 'y'  THEN 'Sync finished (at LSN)'
    WHEN 'r'  THEN 'Done'
    ELSE 'Unknown'
  END AS sync_status,
  sync_statuslsn
FROM pglogical.local_sync_status;

---
SELECT * FROM pglogical.depend;


--check repln lag

SELECT
  application_name,
  pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)    AS sending_lag_bytes,
  pg_wal_lsn_diff(sent_lsn, flush_lsn)               AS receiving_lag_bytes,
  pg_wal_lsn_diff(flush_lsn, replay_lsn)             AS replaying_lag_bytes,
  pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)  AS total_lag_bytes
FROM pg_stat_replication;


---
SELECt
  subname,
  pid,
  leader_pid,
  worker_type,
 -- status,                  -- (PG16+) else omit
  received_lsn,
  latest_end_lsn,
  latest_end_time,
  now() - latest_end_time AS apply_delay,
  pg_wal_lsn_diff(received_lsn, latest_end_lsn) AS in_txn_bytes,
  pg_wal_lsn_diff(pg_current_wal_lsn(), latest_end_lsn) AS bytes_behind_head
FROM pg_stat_subscription;


SELECT
  subname,
  pid,
  relid,
  received_lsn,
  last_msg_send_time,
  last_msg_receipt_time,
  latest_end_lsn,
  latest_end_time
FROM pg_stat_subscription;


-- Check pg_stat_activity instead
SELECT pid, application_name, state, query, backend_start, wait_event_type, wait_event,now() - backend_start AS running_for
FROM pg_stat_activity
WHERE application_name ILIKE '%pglogical%'
   OR application_name ILIKE '%pgl%'
   OR backend_type ILIKE '%pglogical%';

  -- Is the sync worker waiting on something?
SELECT pid, application_name, state, wait_event_type, wait_event,
       now() - backend_start AS running_for
FROM pg_stat_activity
WHERE application_name ILIKE '%pglogical sync%'; 

   
set time zone 'Asia/Kolkata';
select * from pg_stat_activity where datname='iics_cdc_test' and state='active'

  -- Check if apply worker is actually processing anything
SELECT pid, application_name, state, wait_event_type, wait_event, query
FROM pg_stat_activity
WHERE application_name ILIKE '%pglogical%';

SELECT pid, application_name, state, wait_event_type, wait_event,
       now() - backend_start AS running_for
FROM pg_stat_activity
WHERE application_name ILIKE '%pglogical sync%';


--select pg_terminate_backend(4037908)


  -- Also check background workers
SELECT * FROM pg_stat_activity
WHERE backend_type = 'background worker'; 

---

-- Run several times during the test
SELECT now() AS ts, subname, 
       pg_wal_lsn_diff(pg_current_wal_lsn(), latest_end_lsn) AS bytes_behind_head,
       now() - latest_end_time AS time_lag
FROM pg_stat_subscription;

select * from pg_stat_subscription;


-----to check sessions of replication workers

SELECT * FROM pglogical.show_subscription_status();
-- Look at progress columns (depends on version); also check pg_stat_activity:
SELECT pid, backend_type, state, query
FROM pg_stat_activity
WHERE backend_type LIKE '%logical%';

set time zone 'Asia/Kolkata';
SELECT pid, application_name, state, wait_event_type, wait_event, 
       query, backend_start, now() - backend_start AS running_for
FROM pg_stat_activity
WHERE pid = 4025808;

-- Cancel the query (softer than terminate)
SELECT pg_cancel_backend(4025808);


--SELECT pg_terminate_backend(3727483);

SELECT pid, state, query
FROM pg_stat_activity
WHERE backend_type IN ('logical replication worker', 'logical replication launcher');


----------------to disable sub and enable it for resnc

SELECT pglogical.alter_subscription_disable('sub_to_pub4');  -- immediate
-- fix issues, then:
SELECT pglogical.alter_subscription_enable('sub_to_pub4', true);

-----
SELECT pglogical.alter_subscription_restart('sub_to_pub4');


-- First make sure subscription is re-enabled
SELECT pglogical.alter_subscription_enable('sub_to_pub4');

-- Then force resync
SELECT pglogical.alter_subscription_resynchronize_table(
  subscription_name := 'sub_to_pub4',
  relation := 'public.esa_ps_item_activity_stg_curr_tmp',
  truncate := true
);





SELECT * FROM pglogical.show_subscription_status('sub_to_pub4');

SELECT * FROM pglogical.show_subscription_table('sub_to_pub4');



---to resync table
select pglogical.alter_subscription_resynchronize_table('sub_to_pub4', 'public."esa_ps_item_activity_stg_curr_tmp"')

---to remove table

select pglogical.replication_set_remove_table('subC_set','public."CentralRepository_Action_Reason_MIG"')

-- On subscriber
SELECT pglogical.alter_subscription_disable('sub_to_pub', true);
SELECT pglogical.alter_subscription_enable('sub_to_pub', true);
-- Show status again
SELECT * FROM pglogical.show_subscription_status('sub_to_pub3');

select pglogical.wait_for_table_sync_complete()

select pglogical.wait_for_subscription_sync_complete('sub_to_pub4')

select * from public."CentralRepository_EAM_LeaveMaster_MIG"

truncate table public."CentralRepository_Action_Reason_MIG"


select * from public."CentralRepository_AssociateAddress_MIG"

select * from public."CentralRepository_Action_Reason_MIG"

SELECT COUNT(*) AS new_rows
FROM public."CentralRepository_AssociateAddress_MIG"


select count(*) from "CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG"
select count(*) from "SFDC_ACCOUNT_STG_CURR_TMP"

