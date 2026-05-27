CREATE USER replication_user WITH REPLICATION
IN ROLE cloudsqlsuperuser LOGIN PASSWORD 'postgresRepln@2026';

create EXTENSION pglogical;

CREATE SUBSCRIPTION "LogicalRepln_Demo_Sub"
CONNECTION 'host=10.75.154.10 port=5432 dbname=Repln_Sub_PoC user=replication_user password=postgresRepln@2026 sslmode=require'
PUBLICATION "LogicalRepln_Demo_Pub"
WITH (create_slot = true, copy_data = true, enabled = true);



-- Register the subscriber node
SELECT pglogical.create_node(
  node_name := 'sub3_node',
  dsn := 'host=10.75.156.3 port=5432 dbname=Repln_Sub2_PoC user=replication_user password=postgresRepln@2026 sslmode=require'
);

select * from pglogical.node;
SELECT pglogical.drop_node(
  node_name := 'sub_node',
  ifexists := true
);

-- Create subscription from subscriber -> publisher
-- On subscriber
SELECT pglogical.drop_subscription('sub_to_pub3', true);  -- true = drop the slot as well
SELECT pglogical.create_subscription(
  subscription_name := 'sub_to_pub3',
  provider_dsn      := 'host=10.75.154.10 port=5432 dbname=Repln_Test user=replication_user password=postgresRepln@2026 sslmode=require',
  replication_sets  := ARRAY['sub3_UAT'],
  synchronize_structure := false,   -- you manage schema on subscriber
  synchronize_data  := true         -- initial copy
);

SELECT pglogical.create_subscription(
  subscription_name := 'sub_to_pub',
  provider_dsn      := 'host=10.75.154.10 port=5432 dbname=Repln_Test user=replication_user password=postgresRepln@2026 sslmode=require',
  replication_sets  := ARRAY['subSchema_set'],
  synchronize_structure := true,   -- you manage schema on subscriber--false as repln will fail
  synchronize_data  := true         -- initial copy
);
-- Then check:
SELECT * FROM pglogical.show_subscription_status('sub_to_pub');
SELECT * FROM pglogical.show_subscription_status();


select count(*) from public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP" --6.24pm

select count(*) from public."SFDC_ACCOUNT_STG_CURR_TMP" --3.20

select count(*) from public."CentralRepository_RMG_ResourceRequest_MIG_Temp"
truncate table public."CentralRepository_RMG_ResourceRequest_MIG_Temp"



--TRUNCATE pglogical.local_sync_status;

SELECT pglogical.alter_subscription_disable('sub_to_pub3', true);  -- immediate
-- fix issues, then:
SELECT pglogical.alter_subscription_enable('sub_to_pub3', true);


SELECT * FROM pglogical.subscription;





-- Publications
SELECT * FROM pg_publication;

-- Publication tables
SELECT * FROM pg_publication_tables WHERE pubname = 'LogicalRepln_Demo_Pub';

-- Active subscriber sessions (will appear only after a subscription connects)
SELECT * FROM pg_stat_replication;

-- Slots created by subscribers
SELECT * FROM pg_replication_slots;

SELECT pg_drop_replication_slot('pgl__epln__ub2__o___ogical_b557282_sub_to_pub');

select pglogical.wait_for_subscription_sync_complete('sub_to_pub3')

SELECT * FROM pglogical.show_subscription_status('sub_to_pub3');

SELECT * FROM pglogical.show_subscription_table('sub_to_pub');


SELECT * FROM pglogical.show_subscription_status();
-- Look at progress columns (depends on version); also check pg_stat_activity:

SELECT pid, backend_type, state, query,*
FROM pg_stat_activity
WHERE backend_type LIKE '%logical%';


set time zone 'Asia/Kolkata';
SELECT pid, application_name, state, query, backend_start, wait_event_type, wait_event,now() - backend_start AS running_for
FROM pg_stat_activity
WHERE application_name ILIKE '%pglogical%'
   OR application_name ILIKE '%pgl%'
   OR backend_type ILIKE '%pglogical%';

SELECT pid, state, query
FROM pg_stat_activity
WHERE backend_type IN ('logical replication worker', 'logical replication launcher');


SELECT pid, application_name, state, wait_event_type, wait_event,
       now() - backend_start AS running_for
FROM pg_stat_activity
WHERE application_name ILIKE '%pglogical sync%';


select pglogical.alter_subscription_resynchronize_table('sub_to_pub3', 'public."CentralRepository_RMG_ResourceRequest_MIG_Temp"') --8.20pm from d came to u in 2mins
--again 2.59pm 8th April
SELECT * FROM pglogical.local_sync_status; --3.12 --came to u in 2mins, took 4mins

select pglogical.wait_for_subscription_sync_complete('sub_to_pub3')

SELECT * FROM pglogical.show_subscription_table(
    'sub_to_pub3', 
    'public."CentralRepository_RMG_ResourceRequest_MIG_Temp"'
);

-- Run this every 30 seconds during a large sync
SELECT relname, n_live_tup,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||quote_ident(relname))) AS size
FROM pg_stat_user_tables
WHERE relname = 'CentralRepository_RMG_ResourceRequest_MIG_Temp';

select count(*) from public."CentralRepository_RMG_ResourceRequest_MIG_Temp"

select * from public."CentralRepository_RMG_ResourceRequest_MIG_Temp" where rmg_rr='00033929901'



SELECT
  pg_size_pretty(pg_relation_size(oid)) AS table_size,
  pg_size_pretty(pg_indexes_size(oid)) AS indexes_size,
  pg_size_pretty(pg_total_relation_size(oid)) AS total_size
FROM pg_class
WHERE relname = 'CentralRepository_RMG_ResourceRequest_MIG_Temp';


vacuum ANALYZE public."CentralRepository_RMG_ResourceRequest_MIG_Temp";


select count(*) from esa_ps_item_stg_curr

select * from pg_settings WHERE name like '%wal_%'


SELECT 
    application_name AS subscription_name,
    client_addr AS subscriber_ip,
    state,
    sync_state,
    pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) AS pending_bytes,
    pg_wal_lsn_diff(sent_lsn, write_lsn) AS write_lag_bytes,
    pg_wal_lsn_diff(write_lsn, flush_lsn) AS flush_lag_bytes,
    pg_wal_lsn_diff(flush_lsn, replay_lsn) AS replay_lag_bytes,
    write_lag,
    flush_lag,
    replay_lag
FROM pg_stat_replication
WHERE application_name IN (
    SELECT sub_name FROM pglogical.subscription
)
ORDER BY subscription_name;

--select count(*) from public."CentralRepository_RMG_ResourceRequest_MIG_Temp" --1.09

-- On source
SELECT 
  pg_size_pretty(pg_total_relation_size('public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP"')) AS total_size,
  pg_size_pretty(pg_relation_size('public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP"')) AS data_size,
  (SELECT count(*) FROM public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP") AS row_count;


  SELECT current_setting('max_connections') AS max_conn,
       current_setting('shared_buffers') AS shared_buffers,
       current_setting('work_mem') AS work_mem;

	   SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP'
  AND schemaname = 'public';

--delete from pglogical.local_sync_status where sync_relname='esa_ps_item_activity_stg_curr_tmp'
-- On subscriber
SELECT pglogical.alter_subscription_disable('sub_to_pub3', true);
SELECT pglogical.alter_subscription_enable('sub_to_pub3', true);

SELECT pglogical.alter_subscription_restart('sub_to_pub3',true);
-- Show status again
SELECT * FROM pglogical.show_subscription_status('sub_to_pub3');
SELECT * FROM pglogical.show_subscription_status();

--SELECT pglogical.alter_subscription_resync_table('sub_to_pub', 'public."CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP"');

select * from public."CentralRepository_EAM_LeaveMaster_MIG"

truncate table public."CentralRepository_AssociateAddress_MIG"


select * from public."CentralRepository_AssociateAddress_MIG"

select * from public."CentralRepository_Action_Reason_MIG"

SELECT COUNT(*) AS new_rows
FROM public."CentralRepository_AssociateAddress_MIG"


select count(*) from "CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP" limit 20
