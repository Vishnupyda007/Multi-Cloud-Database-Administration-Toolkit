--we cannot use native logical replication, we have to create pglogical Replication
CREATE EXTENSION pglogical;

show wal_level; --should be logical


CREATE USER replication_user WITH REPLICATION
IN ROLE cloudsqlsuperuser LOGIN PASSWORD 'postgresRepln@2026';



-- All tables in the database
--CREATE PUBLICATION app_pub FOR ALL TABLES;
-- or a subset
---to create a node for publication server which acts as publication
SELECT pglogical.create_node(
  node_name := 'LogicalRepln_Demo_Pub',
  dsn := 'host=10.75.154.10 port=5432 dbname=Repln_Test user=replication_user password=postgresRepln@2026 sslmode=require'
);


--to drop a node

select * from pglogical.node;

select pglogical.drop_node('LogicalRepln_Demo_Pub1')



--- to create set for each Sub and we can add tables according to set
-- For subscriber B
SELECT pglogical.create_replication_set(
  set_name := 'sub1_PoC',
  replicate_insert := true,
  replicate_update := true,
  replicate_delete := true,
  replicate_truncate := true
);

--for sub3 --schema test
SELECT pglogical.create_replication_set(
  set_name := 'sub2_PoC',
  replicate_insert := true,
  replicate_update := true,
  replicate_delete := true,
  replicate_truncate := true
);


--uat 
SELECT pglogical.create_replication_set(
  set_name := 'sub3_UAT',
  replicate_insert := true,
  replicate_update := true,
  replicate_delete := true,
  replicate_truncate := true
);

--dev

SELECT pglogical.create_replication_set(
  set_name := 'sub4_DEV',
  replicate_insert := true,
  replicate_update := true,
  replicate_delete := true,
  replicate_truncate := true
);

---which set to which sub
-- default and setb to poc sub
-- setc to dev
--SubUAT_set to uat

--select * from pg_stat_all_tables order by n_live_tup desc;


-- Add one table to the default set
--SELECT pglogical.replication_set_add_table('default', 'public."CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG"', true);
SELECT pglogical.replication_set_add_table('sub1_PoC', 'public."CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP"', true);
SELECT pglogical.replication_set_add_table('sub1_PoC', 'public."SFDC_ACCOUNT_STG_CURR"', true);
--SELECT pglogical.replication_set_add_table('subB_set', 'public."SFDC_ACCOUNT_STG_CURR_TMP"', true);
SELECT pglogical.replication_set_add_table('sub2_PoC', 'public."CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG"', true);
--SELECT pglogical.replication_set_add_table('subC_set', 'public."CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP"', true);
--SELECT pglogical.replication_set_add_table('subC_set', 'public."SFDC_ACCOUNT_STG_CURR"', true);
SELECT pglogical.replication_set_add_table('sub3_UAT', 'public."SFDC_ACCOUNT_STG_CURR_TMP"', true);
SELECT pglogical.replication_set_add_table('sub4_DEV', 'public."CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP"', true);
--2nd set test---
SELECT pglogical.replication_set_add_table('subC_set', 'public."SFDC_ACCOUNT_STG_CURR"', true);
SELECT pglogical.replication_set_add_table('subUAT_set', 'public."SFDC_ACCOUNT_STG_CURR"', true);
--SELECT pglogical.replication_set_add_table('subUAT_set', 'public."CentralRepository_AssociateAddress_MIG"', true);
--SELECT pglogical.replication_set_add_table('subUAT_set', 'public."CentralRepository_AssociateAddress_MIG"', true);

---3rd set test--
SELECT pglogical.replication_set_add_table('subB_set', 'public."SFDC_ACCOUNT_STG_CURR_TMP"', true);
SELECT pglogical.replication_set_add_table('subUAT_set', 'public."SFDC_ACCOUNT_STG_CURR_TMP"', true);


-------20gb test----
select count(*) from public."SFDC_ACCOUNT_STG_CURR_TMP"


SELECT pglogical.replication_set_add_table('sub3_UAT', 'public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP"', true);


select pglogical.replication_set_add_table('sub3_UAT', 'public."CentralRepository_RMG_ResourceRequest_MIG_Temp"');



select pglogical.replication_set_remove_table('sub4_DEV', 'public."CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP"');

----7gb----
select count(*) from "CentralRepository_RMG_ResourceRequest_MIG_Temp"

select pglogical.replication_set_add_table('sub3_UAT', 'public.esa_ps_item_stg_curr');

"CentralRepository_RMG_ResourceRequest_MIG_Temp"
"ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP"
"SFDC_ACCOUNT_STG_CURR_TMP"
esa_ps_item_stg_curr--added


SELECT relname, n_live_tup,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||quote_ident(relname))) AS size
FROM pg_stat_user_tables
WHERE relname = 'CentralRepository_RMG_ResourceRequest_MIG_Temp';

select count(*) from public."CentralRepository_RMG_ResourceRequest_MIG_Temp"

SELECT
  pg_size_pretty(pg_relation_size(oid)) AS table_size,
  pg_size_pretty(pg_indexes_size(oid)) AS indexes_size,
  pg_size_pretty(pg_total_relation_size(oid)) AS total_size
FROM pg_class
WHERE relname = 'CentralRepository_RMG_ResourceRequest_MIG_Temp';

vacuum ANALYZE public."CentralRepository_RMG_ResourceRequest_MIG_Temp";

select * from pg_settings WHERE name like '%wal_%'


---4th test--
default- 2
subB_set-2
subC_set-1 (associate tmp)
subuat_set-associate details


public."Beeline_WorkerDownloadData_STG_CURR"
-- Or add multiple as needed
--SELECT pglogical.replication_set_add_table('default', 'public."Beeline_WorkerDownloadData_STG_CURR"', true);



--(Optional) Set replica identity for tables without PKs:
ALTER TABLE public.some_table REPLICA IDENTITY FULL;

SELECT * FROM pglogical.node;
---to check total subs and repln slots

SELECT * FROM pg_stat_replication; 
set time zone 'Asia/Kolkata';

SELECT * FROM pg_replication_slots;

-- On the publisher DB
SELECT
  s.sub_name                                   AS subscription,
  s.sub_enabled                                AS enabled,
  n_target.node_name                           AS subscriber_node,
  n_targetif.if_name                      AS subscriber_conninfo,
  unnest(s.sub_replication_sets)               AS set_name  -- one row per set
FROM pglogical.subscription s
JOIN pglogical.node n_provider
  ON n_provider.node_id = s.sub_origin             -- provider side node
JOIN pglogical.node n_target
  ON n_target.node_id = s.sub_target               -- subscriber node
LEFT JOIN pglogical.node_interface n_targetif
  ON n_targetif.if_nodeid = n_target.node_id
ORDER BY subscription, set_name;


--total wal dir size:
select * from pg_ls_waldir();

--total wal dir szie:
select pg_size_pretty(sum(size)) as "Total WAL disk usage" from pg_ls_waldir();



-- List publications in the current DB
SELECT pubname, puballtables, pubinsert, pubupdate, pubdelete, pubtruncate
FROM pg_publication;

-- List tables included in your publication
SELECT * FROM pglogical.replication_set
WHERE pubname = 'LogicalRepln_Demo_Pub';

--to check subs
SELECT * FROM pglogical.subscription;

truncate table pg_publication_tables

select * from pglogical.replication_set_table

--slots clean
SELECT slot_name
FROM pg_replication_slots
WHERE slot_name LIKE 'pgl%';

SELECT pg_drop_replication_slot('pgl__epln__ub2__o___ogical_250989f_sub_to_pub3_d9d2f545');


SELECT pg_drop_replication_slot('pgl__epln__ub2__o___ogical_250989f_sub_to_pub3_d9d2f545');


----
SELECT now() AS ts, wal_records, wal_fpi, wal_bytes
FROM pg_stat_wal;
-- Reset stats before test to get a clean delta:
-- SELECT pg_stat_reset_shared('wal');


----

SELECT
  slot_name,
  pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn) AS bytes_behind
FROM pg_replication_slots
WHERE plugin LIKE 'pglogical%';


-- Is the main replication slot still alive on source?
set time zone 'Asia/Kolkata';
SELECT slot_name, active, plugin,
  pg_size_pretty(
    pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)
  ) AS lag,*
FROM pg_replication_slots;

select count(*) from esa_ps_item_stg_curr



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


select * from pg_settings where name='track_commit_timestamp'


select count(*) from public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP" --6.24pm

select count(*) from public."CentralRepository_RMG_ResourceRequest_MIG_Temp" --3452376

--2mins

-- On source
SELECT 
  pg_size_pretty(pg_total_relation_size('public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP"')) AS total_size,
  pg_size_pretty(pg_relation_size('public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP"')) AS data_size,
  (SELECT count(*) FROM public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP") AS row_count;


  -- On both source and target
SELECT current_setting('max_connections') AS max_conn,
       current_setting('shared_buffers') AS shared_buffers,
       current_setting('work_mem') AS work_mem;


--select count(*) from public."CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP"


-- Is the sync worker waiting on something?
SELECT pid, application_name, state, wait_event_type, wait_event,
       now() - backend_start AS running_for
FROM pg_stat_activity
WHERE application_name ILIKE '%pglogical sync%';


-- On source
SHOW wal_compression;

-- pglogical workers don't always show in pg_stat_subscription
-- Check pg_stat_activity instead
SELECT pid, application_name, state, query, backend_start, wait_event_type, wait_event
FROM pg_stat_activity
WHERE application_name ILIKE '%pglogical%'
   OR application_name ILIKE '%pgl%'
   OR backend_type ILIKE '%pglogical%';


  -- Also check background workers
SELECT * FROM pg_stat_activity
WHERE backend_type = 'background worker'; 


-- On target Cloud SQL instance
SHOW max_worker_processes;

---
SELECT *
FROM pg_stat_replication
ORDER BY state;

-------------to check with table is part of which set----------
SELECT
    rs.set_name,
    n.nspname AS schema_name,
    c.relname AS table_name
FROM pglogical.replication_set_table rst
JOIN pglogical.replication_set rs
    ON rst.set_id = rs.set_id
JOIN pg_class c
    ON rst.set_reloid = c.oid
JOIN pg_namespace n
    ON c.relnamespace = n.oid
ORDER BY rs.set_name, schema_name, table_name;


-- Tables in each replication set on the publisher
SELECT
  rs.set_name,
  rst.set_reloid::regclass AS relation,
  rst.set_att_list,
  rs.set_name      -- some builds expose per-set flags as a JSON-ish text
FROM pglogical.replication_set rs
JOIN pglogical.replication_set_table rst
  ON rst.set_id = rs.set_id
ORDER BY rs.set_name, relation::text;

-- Complete mapping from subscription to tables via replication sets
WITH sub_sets AS (
  SELECT
    s.sub_name,
    unnest(s.sub_replication_sets) AS set_name
  FROM pglogical.subscription s
)
SELECT
  ss.sub_name        AS subscription,
  rs.set_name        AS replication_set,
  rst.set_reloid::regclass AS table_in_set
FROM sub_sets ss
JOIN pglogical.replication_set rs
  ON rs.set_name = ss.set_name
JOIN pglogical.replication_set_table rst
  ON rst.set_id = rs.set_id
ORDER BY subscription, replication_set, table_in_set::text;



--------------to check repln slots and their plugin and active status

SELECT slot_name, plugin, active
FROM pg_replication_slots
WHERE plugin = 'pgoutput';  -- native logical replication uses pgoutput

-------to check which table is part of which sub
SELECT rs.set_name, n.nspname, c.relname
FROM pglogical.replication_set_table rst
JOIN pglogical.replication_set rs ON rs.set_id = rst.set_id
JOIN pg_class c ON c.oid = rst.set_reloid
JOIN pg_namespace n ON n.oid = c.relnamespace
ORDER BY rs.set_name, n.nspname, c.relname;

--sub workers sessions

select * from pg_stat_subscription


---
--check repln lag

SELECT
  application_name,
  pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)    AS sending_lag_bytes,
  pg_wal_lsn_diff(sent_lsn, flush_lsn)               AS receiving_lag_bytes,
  pg_wal_lsn_diff(flush_lsn, replay_lsn)             AS replaying_lag_bytes,
  pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)  AS total_lag_bytes
FROM pg_stat_replication;

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


--

SELECT
  slot_name,
  active,
  pg_size_pretty(
    pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)
  ) AS lag_size,
  pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn) AS lag_bytes
FROM pg_replication_slots
ORDER BY lag_bytes DESC;


----
SELECT
  slot_name,
  plugin,
  active,
  pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn) AS lag_bytes
FROM pg_replication_slots
WHERE plugin = 'pglogical_output';

--to check repln slots and wal senders----------

SELECT name, setting FROM pg_settings 
WHERE name IN ('max_replication_slots','max_wal_senders');

--SELECT pglogical.alter_subscription_resync_table('sub_to_pub', 'public."CentralRepository_Action_Reason_MIG"');


select pglogical.alter_subscription_resynchronize_table('sub_to_pub2', 'public."CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP"');


--to add table in replication set

SELECT pglogical.replication_set_add_table('subC_set' , 'public."CentralRepository_EAM_LeaveMaster_MIG"', true);

SELECT pglogical.replication_set_add_table('subC_set', 'public."CentralRepository_AssociateAddress_MIG"', true);


----to remove a table from repln set

select pglogical.replication_set_remove_table('default', 'public."Beeline_WorkerDownloadData_STG_CURR"');

--select * from pglogical.wait_for_table_sync_complete()

select pglogical.wait_for_subscription_sync_complete('sub_to_pub2')

select * from public."CentralRepository_Action_Reason_MIG" where "ACTION_DESCR"='Employment Status Change'



SELECT pg_get_viewdef(oid)
FROM pg_class
WHERE relname = 'public."CentralRepository_AssociateAddress_MIG"';
SELECT pg_get_viewdef('public."CentralRepository_AssociateAddress_MIG"');

SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'CentralRepository_AssociateAddress_MIG';




-- Allow your role to use the schema and execute pglogical functions
GRANT USAGE ON SCHEMA pglogical TO postgres;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pglogical TO postgres;

grant select on all tables in schema pglogical to postgres;
-- Optional: ensure future functions are executable too
ALTER DEFAULT PRIVILEGES IN SCHEMA pglogical
GRANT EXECUTE ON FUNCTIONS TO postgres;


select * from "CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP"


select * from public."CentralRepository_RMG_ResourceRequest_MIG_Temp" where rmg_rr='00033929901'

update  public."CentralRepository_RMG_ResourceRequest_MIG_Temp" set status='Opened' where rmg_rr='00033929901'