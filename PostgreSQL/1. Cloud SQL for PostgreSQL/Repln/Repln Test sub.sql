CREATE USER replication_user WITH REPLICATION
IN ROLE cloudsqlsuperuser LOGIN PASSWORD 'postgresRepln@2026';

CREATE EXTENSION pglogical;

CREATE SUBSCRIPTION "LogicalRepln_Demo_Sub"
CONNECTION 'host=10.75.154.10 port=5432 dbname=Repln_Sub_PoC user=replication_user password=postgresRepln@2026 sslmode=require'
PUBLICATION "LogicalRepln_Demo_Pub"
WITH (create_slot = true, copy_data = true, enabled = true);



-- Register the subscriber node
SELECT pglogical.create_node(
  node_name := 'sub1_node',
  dsn := 'host=10.75.154.9 port=5432 dbname=Repln_Sub_PoC user=replication_user password=postgresRepln@2026 sslmode=require'
);

select * from pglogical.node;

SELECT pglogical.drop_node(
  node_name := 'sub_node',
  ifexists := true
);

-- Create subscription from subscriber -> publisher
-- On subscriber
SELECT pglogical.drop_subscription('sub_to_pub2', true);  -- true = drop the slot as well
SELECT pglogical.create_subscription(
  subscription_name := 'sub_to_pub2',
  provider_dsn      := 'host=10.75.154.10 port=5432 dbname=Repln_Test user=replication_user password=postgresRepln@2026 sslmode=require',
  replication_sets  := ARRAY['sub2_PoC'],
  synchronize_structure := false,   -- you manage schema on subscriber
  synchronize_data  := true         -- initial copy
);
-- Then check:
SELECT * FROM pglogical.show_subscription_status('sub_to_pub');
SELECT * FROM pglogical.show_subscription_status();


SELECT * FROM pglogical.subscription;


--TRUNCATE table pglogical.local_sync_status;



-- Publications
SELECT * FROM pg_publication;

-- Publication tables
SELECT * FROM pg_publication_tables WHERE pubname = 'LogicalRepln_Demo_Pub';

-- Active subscriber sessions (will appear only after a subscription connects)
SELECT * FROM pg_stat_replication;

-- Slots created by subscribers
SELECT * FROM pg_replication_slots;


SELECT * FROM pglogical.show_subscription_status('sub_to_pub3');

SELECT * FROM pglogical.show_subscription_status();

SELECT * FROM pglogical.show_subscription_table('sub_to_pub1');


select pglogical.alter_subscription_resynchronize_table('sub_to_pub2', 'public."SFDC_ACCOUNT_STG_CURR_TMP"')

SELECT * FROM pglogical.local_sync_status;

select pglogical.wait_for_subscription_sync_complete('sub_to_pub2')


delete from pglogical.local_sync_status where sync_subid=97848907

SELECT pid, application_name, state, sent_lsn, write_lsn, flush_lsn
FROM pg_stat_replication
ORDER BY application_name;

SELECT * FROM pg_locks
WHERE relation = 'public."SFDC_ACCOUNT_STG_CURR_TMP"'::regclass;

SELECT *
FROM pglogical.subscription;
-- On subscriber
SELECT pglogical.alter_subscription_disable('sub_to_pub1', true);
SELECT pglogical.alter_subscription_enable('sub_to_pub1', true);

SELECT pglogical.alter_subscription_restart('sub_to_pub1');

-- Show status again
SELECT * FROM pglogical.show_subscription_status('sub_to_pub2');
SELECT * FROM pglogical.show_subscription_status();

alter subscription sub_to_pub enable;
--SELECT pglogical.alter_subscription_resync_table('sub_to_pub', 'public."CentralRepository_AssociateAddress_MIG"');

select * from public."CentralRepository_EAM_LeaveMaster_MIG"

truncate table public."CentralRepository_AssociateAddress_MIG"


select * from public."CentralRepository_AssociateAddress_MIG"

select * from public."CentralRepository_Action_Reason_MIG"

SELECT COUNT(*) AS new_rows
FROM public."CentralRepository_AssociateAddress_MIG"


select count(*) from "CENTRALREPOSITORY_ASSOCIATE_DETAILS_MIG_TMP"
select count(*) from "SFDC_ACCOUNT_STG_CURR"



select count(*) from "SFDC_ACCOUNT_STG_CURR_TMP"