--select * from "SFDC_Account_STG_CURR"
-- select count(*) from "HCM_PS_JOBCODE_TBL_STG_CURR" --3secs

--select count(*) from "esa_ps_project_status_stg_curr" --2mins
 --truncate table "esa_ps_project_status_stg_curr"

--select count(*) from "CentralRepository_RMG_ResourceRequest_MIG_Temp"  --8:06pm, completed -8.10pm
-- truncate table "CentralRepository_RMG_ResourceRequest_MIG_Temp"

--select count(*) from "ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP"; --54mins

--select count(*) from esa_ps_item_activity_stg_curr; --5:18pm to 5.25pm


--truncate table public."CentralRepository_RMG_ResourceRequest_MIG_Temp";
--truncate table public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP";
--truncate table public."HCM_PS_JOBCODE_TBL_STG_CURR";
--truncate table public."SFDC_Account_STG_CURR";
--truncate table public."esa_ps_item_activity_stg_curr";
--truncate table public."esa_ps_project_status_stg_curr";
--50gb tables started at 6.47pm


select count(*) from "IICS_CDC_TEST"."CentralRepository_Associate_Details_History_MIG_New";
               "IICS_CDC_TEST"."CentralRepository_RMG_ResourceRequest_MIG";
               "IICS_CDC_TEST"."HCM_PS_CT_GBL_HCM_SFBD_STG_CURR";

SELECT
    c.table_name,
    c.column_name AS pk_column
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage c
    ON tc.constraint_name = c.constraint_name
WHERE tc.constraint_type = 'PRIMARY KEY'
    AND tc.table_name = 'SFDC_Account_STG_CURR';

-- ════════════════════════════════════════════════════════════
-- Run on SUBSCRIBER 1
-- ════════════════════════════════════════════════════════════
CREATE SUBSCRIPTION sub_uat_test
    CONNECTION 'host=10.75.154.10
                port=5432
                dbname=Repln_Test
                user=replication_user
                password=postgresRepln@2026
                sslmode=require'
    PUBLICATION "Pub_UAT_Test"
    WITH (
        connect                   = true,
        enabled                   = true,
        copy_data                 = false,
        create_slot               = true,
        slot_name                 = 'sub_uat_test_slot',
        synchronous_commit        = 'off',
        streaming                 = 'parallel',  -- PG16+ parallel apply
        two_phase                 = false,
        disable_on_error          = true,        -- PG16+ stop on conflict
        origin                    = 'any'
    );


ALTER SUBSCRIPTION sub_uat_test
    SET (
        wal_receiver_timeout = 0    -- 0 = never timeout during copy
    );
-- Rese

-- Step 5: On SUBSCRIBER — reattach to new slot
ALTER SUBSCRIPTION sub_uat_test
    SET (slot_name = 'sub_uat_test_slot');

--once a table added in repln, run this in Sub 
	ALTER SUBSCRIPTION sub_uat_test
    REFRESH PUBLICATION
    WITH (copy_data = true);

---once a table is dropped from Publication, run the below one
ALTER SUBSCRIPTION sub_uat_test
    REFRESH PUBLICATION;
	
ALTER SUBSCRIPTION sub_uat_test enable;

ALTER SUBSCRIPTION sub_uat_test disable;


ALTER SUBSCRIPTION sub_uat_test
    SET (slot_name = NONE);
	
--drop subscription sub_uat_test cascade
	
-- ════════════════════════════════════════════════════════════
-- Run on SUBSCRIBER 2
-- ════════════════════════════════════════════════════════════
CREATE SUBSCRIPTION sub_reporting
    CONNECTION 'host=PUBLISHER_IP
                port=5432
                dbname=pub_db
                user=replicator
                password=StrongPassword123!
                sslmode=require'
    PUBLICATION pub_reporting
    WITH (
        connect                   = true,
        enabled                   = true,
        copy_data                 = true,
        create_slot               = true,
        slot_name                 = 'sub_reporting_slot',
        synchronous_commit        = 'off',
        streaming                 = 'parallel',
        two_phase                 = false,
        disable_on_error          = true,
        origin                    = 'any'
    );

-- ════════════════════════════════════════════════════════════
-- Run on SUBSCRIBER 3
-- ════════════════════════════════════════════════════════════
CREATE SUBSCRIPTION sub_audit
    CONNECTION 'host=PUBLISHER_IP
                port=5432
                dbname=pub_db
                user=replicator
                password=StrongPassword123!
                sslmode=require'
    PUBLICATION pub_audit
    WITH (
        connect                   = true,
        enabled                   = true,
        copy_data                 = true,
        create_slot               = true,
        slot_name                 = 'sub_audit_slot',
        synchronous_commit        = 'off',
        streaming                 = 'parallel',
        two_phase                 = false,
        disable_on_error          = true,
        origin                    = 'any'
    );




SELECT
    pid,
    usename,
    application_name,
    state,
    backend_type,
    LEFT(query, 100) AS current_query,
    NOW() - backend_start AS running_for
FROM pg_stat_activity
WHERE backend_type IN (
    'logical replication worker',
    'logical replication launcher',
    'TablesyncWorker'            -- PG17 specific
) or backend_type like '%logical_%'
ORDER BY backend_type;

SELECT subname, subenabled, subdisableonerr
FROM pg_subscription

SHOW max_sync_workers_per_subscription;



SELECT
    name,
    setting,
    unit,
    short_desc
FROM pg_settings
WHERE name IN (
    'max_replication_slots',
    'max_wal_senders',
    'max_logical_replication_workers',
    'max_sync_workers_per_subscription',
    'max_worker_processes',
    'wal_level',
    'wal_sender_timeout',
    'wal_receiver_timeout',
    'max_slot_wal_keep_size',
    'track_commit_timestamp',
	'wal_receiver_status_interval'
)