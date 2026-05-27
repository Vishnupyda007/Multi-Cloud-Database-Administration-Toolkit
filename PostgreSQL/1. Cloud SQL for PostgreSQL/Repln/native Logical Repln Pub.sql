grant all on tables in schema pu to replication_user;


CREATE PUBLICATION "Pub_UAT_Test"
  
    WITH (
        publish = 'insert, update, delete, truncate'
    );

--add table

Alter publication "Pub_UAT_Test" add table "esa_ps_item_activity_stg_curr";

select count(*) from "esa_ps_item_activity_stg_curr"; 


-----add multiple tables
--added at 2.36pm to 2.52pm = 16mins
ALTER PUBLICATION "Pub_UAT_Test"
    ADD TABLE public."CentralRepository_RMG_ResourceRequest_MIG_Temp",
              public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP",
              public."HCM_PS_JOBCODE_TBL_STG_CURR",
              public."SFDC_Account_STG_CURR",
              public."esa_ps_item_activity_stg_curr",
              public."esa_ps_project_status_stg_curr";

--drop multiple tables from pub
ALTER PUBLICATION "Pub_UAT_Test"
    drop TABLE public."CentralRepository_RMG_ResourceRequest_MIG_Temp",
              public."ESA_PS_ITEM_ACTIVITY_STG_CURR_TMP",
              public."HCM_PS_JOBCODE_TBL_STG_CURR",
              public."SFDC_Account_STG_CURR",
              public."esa_ps_item_activity_stg_curr",
              public."esa_ps_project_status_stg_curr";



--add 73gb tables to sub1,added at 1.13pm

ALTER PUBLICATION "Pub_UAT_Test"
    drop TABLE "IICS_CDC_TEST"."CentralRepository_Associate_Details_History_MIG_New",
               "IICS_CDC_TEST"."CentralRepository_RMG_ResourceRequest_MIG",
               "IICS_CDC_TEST"."HCM_PS_CT_GBL_HCM_SFBD_STG_CURR";


--drop publication "Pub_UAT_Test"
SELECT pubname, puballtables, pubinsert, pubupdate, pubdelete, pubtruncate
FROM pg_publication;

-- Verify tables in each publication
SELECT p.pubname, pt.schemaname, pt.tablename
FROM pg_publication p
JOIN pg_publication_tables pt ON pt.pubname = p.pubname
ORDER BY p.pubname, pt.tablename;


SELECT
    COUNT(*)                                        AS used_slots,
    current_setting('max_replication_slots')::INT   AS max_slots,
    current_setting('max_replication_slots')::INT
        - COUNT(*)                                  AS available_slots
FROM pg_replication_slots;

select * from pg_replication_slots

SELECT
    c.table_name,
    c.column_name AS pk_column
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage c
    ON tc.constraint_name = c.constraint_name
WHERE tc.constraint_type = 'PRIMARY KEY'
    AND tc.table_name = 'SFDC_Account_STG_CURR';

SHOW max_sync_workers_per_subscription;



SELECT slot_name, active, temporary
FROM pg_replication_slots
WHERE temporary = TRUE
   OR slot_name LIKE 'pg_%sync%';


  SELECT pg_drop_replication_slot(slot_name)
FROM pg_replication_slots
WHERE active    = FALSE
  AND temporary = false; 


 SELECT slot_name, active, temporary
FROM pg_replication_slots; 


SELECT pg_create_logical_replication_slot(
    'sub_uat_test_slot',   -- same name
    'pgoutput'          -- plugin for native replication
)



