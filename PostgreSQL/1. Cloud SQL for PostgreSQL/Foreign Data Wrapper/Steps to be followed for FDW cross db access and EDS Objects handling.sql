---below functions are available only in EDS Dbs of all the Postgres Instances as of now

-- example — the view with schema

SELECT "DBAdmin".alter_view_safedba_func('public.vw_esa_ps_item_stg_curr',
    $query$SELECT business_unit,
    cust_id,
    item,
    item_line,
    item_status,
    entry_type,
    bal_amt,
    accounting_dt,
    asof_dt,
    post_dt,
    due_dt,
    po_ref,
    pymnt_terms_cd,
    item_seq_num,
    bal_currency,
    currency_cd,
    consol_invoice,
    payment_method,
    orig_item_amt,
    invoice_dt,
    entered_dttm,
    last_update_dttm,
    rec_created_by,
    source_upd_dttm AS lastupdateddatetime,
    rec_created_dttm,
    record_status,
    src_seq_num
   FROM esa_ps_item_stg_curr
  WHERE record_status <> 'D'::bpchar;$query$,
  dry_run_in    => TRUE   --only dry run. false or not mentioned the parameter- then real run
);

-- example — the view with schema
SELECT alter_view_safedba_func(
    'hr.emp_view',
    'SELECT id, name, salary, department, new_col FROM hr.employees'
);

-- Plain view name (uses current schema)
SELECT alter_view_safedba_func(
    'emp_view',
    'SELECT id, name FROM employees WHERE active = true'
);
--


--use the below function when you are adding or dropping a column of a table, pls do dry run and also you can test for 2 to 3 times before proceeding and always give 
--enable_log_in => FALSE, always mention schema name as well
-- Logging ON (default) — writes to safe_alter_audit_log
SELECT safedba_alter_table_func(
    'hr.employees',
    'ALTER TABLE hr.employees ADD COLUMN middle_name TEXT'
);

-- Logging OFF — no audit table writes at all, zero overhead
SELECT safedba_alter_table_func(
    'hr.employees',
    'ALTER TABLE hr.employees ADD COLUMN middle_name TEXT',
    enable_log_in => FALSE
);

-- Dry run with logging OFF — just see the NOTICEs, nothing written anywhere
SELECT safedba_alter_table_func(
    'hr.employees',
    'ALTER TABLE hr.employees ADD COLUMN middle_name TEXT',
    dry_run_in    => TRUE,
    enable_log_in => FALSE
);


--you can give multiple columns as well
SELECT "DBAdmin".safedba_alter_table_func(
    'hr.employees',
    'ALTER TABLE hr.employees ADD COLUMN middle_name TEXT;
     ALTER TABLE hr.employees ALTER COLUMN salary TYPE NUMERIC(15,2)',
    dry_run_in    => TRUE,
    enable_log_in => FALSE
);



------------------------------------------------------------------------------



SELECT "DBAdmin".safedba_alter_table_func(
    'public.RHMS_ROLEMASTER_STG_CURR',
    'ALTER TABLE public."RHMS_ROLEMASTER_STG_CURR"
    ALTER COLUMN roleid TYPE character varying(40),
    ALTER COLUMN rolename TYPE character varying(100),
    ALTER COLUMN primaryportfoliotype TYPE character varying(200),
    ALTER COLUMN portfolioqualifier1type TYPE character varying(200),
    ALTER COLUMN portfolioqualifier2type TYPE character varying(200),
    ALTER COLUMN rolecategorymastername TYPE character varying(100),
    ALTER COLUMN rolecategoryname TYPE character varying(100);',
    dry_run_in    => false,
    enable_log_in => FALSE
);






---------------Foreign Data Wrapper for cross DB Access mainly for eds views and Apps with FDW usage can be checked from guidelines excel

--when an App db with FDW has been restore from one evnt to another envt run the below:
ALTER SERVER AppDBForeignServername
    OPTIONS (SET host 'ServerIP', dbname 'ent_data_store', port '5432');



-- STEP 1: Run on ENT_DATA_STORE (source)
provide connect on db to applogin and App GSA
provide usage on public Schema  to applogin and App GSA
GRANT SELECT ON public.viewname TO "AppLogin",AppGSA;	

-- STEP 2: Run on the APP DB (e.g. app1_db)
SELECT "DBAdmin".grant_edsview_access_func('edsviewname', '1CDBA_empID');


--To revoke Access for eds view for Data minimization

--Step-1: revoke access to the view in EDS DB

--Step-2: Run on the APP DB (e.g. app1_db)

select "DBAdmin".revoke_edsview_access_func('edsviewname', '1CDBA_empID');


	

-----please run the below refresh job for App DBs with FDW in Postgres DB whenever there is any DDLs schema changes(Addition/drop column) in EDS views
--use select * cron.job for job name
select public.run_cron_job_manually('refresh_fdw_EDS_views_AppDBName_EvntName');