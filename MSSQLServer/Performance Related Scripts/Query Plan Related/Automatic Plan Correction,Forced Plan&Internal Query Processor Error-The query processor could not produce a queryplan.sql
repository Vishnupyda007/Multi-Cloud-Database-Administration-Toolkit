Automatic Plan Correction and Understanding Forced Plans and Potential Issues:


Issue:
Internal Query Processor Error: The query processor could not produce a query plan. For more information, contact Customer Support Services.

Plan forcing, a feature available through the Query Store, allows you to dictate the specific execution plan that SQL Server should use for a particular query. This is useful for stabilizing performance when the query optimizer chooses a suboptimal plan. However, several factors related to legacy stored procedures can lead to failures or inefficiencies when a plan is forced.

Query to get the object id /Object name :

Select * from sys.objects where name='Object name'


-----QUery to get query IDs using an Object ID or Object Name:

SELECT 
    q.query_id,
    q.object_id,
    qt.query_sql_text
FROM 
    sys.query_store_query q
JOIN 
    sys.query_store_query_text qt
ON 
    q.query_text_id = qt.query_text_id
WHERE 
    q.object_id ='717297665'

    -------OR--------

SELECT qs.query_id, qs.query_text_id, qt.query_sql_text, o.name AS object_name, qs.last_compile_start_time,qs.last_execution_time,qs.query_hash
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS qs ON qt.query_text_id = qs.query_text_id
JOIN sys.query_store_plan AS qsp ON qs.query_id = qsp.query_id
LEFT JOIN sys.objects AS o ON qs.object_id = o.object_id
WHERE o.name = 'usp_get_PartialRoutedRoutes'




-------Query to get plan ID, is_forced status and etc using query ID:

select * from sys.query_store_plan where query_id in (8671960,8671959)


----or-------------


SELECT p.query_id,
    p.plan_id, 
    p.is_forced_plan, 
    rs.avg_duration, 
    rs.avg_cpu_time, 
    rs.count_executions,
	p.last_force_failure_reason,
	p.force_failure_count,
	p.last_execution_time
FROM sys.query_store_plan p
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE p.query_id in (11002520,11036405)
ORDER BY last_execution_time desc,rs.avg_duration;



-----------to get all forced plans--------

SELECT 
    q.query_id,
    qt.query_sql_text,
    p.plan_id,
    p.is_forced_plan,
    p.force_failure_count,
    rs.avg_duration,
    rs.avg_cpu_time,
    rs.avg_logical_io_reads,
    rs.execution_type_desc,
    rs.count_executions,
    p.last_execution_time
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE p.is_forced_plan = 1
ORDER BY rs.avg_duration DESC;



---------Query to unforce the forced plan for a plan id:


Syntax:
EXEC sp_query_store_unforce_plan <query_id>, <query_plan_ID>;

Eg:EXEC sp_query_store_unforce_plan 7471366, 7056898;



------------Query to off Automatic Plan Correction for a specific Query:

Disable the APRC for Specific query:
Syntax: 
EXECUTE sys.sp_configure_automatic_tuning 'FORCE_LAST_GOOD_PLAN', 'QUERY', <query_id>, 'OFF';

Eg:EXECUTE sys.sp_configure_automatic_tuning 'FORCE_LAST_GOOD_PLAN', 'QUERY', '7471366', 'OFF';




------------------------------------------
Additonal Queries:

Force the chosen plan_id for the query_id:

Syx: ALTER QUERY <your_query_id> FORCE PLAN <your_plan_id>;


Force the Plan:

EXEC sp_query_store_force_plan @query_id = 5, @plan_id = 1;



Recompiling the SP: Recompilation will to remove cache and outdated plans.

sp_recompile 'usp_get_PartialRoutedRoutes'



----Query to find potential reasons for a query ID being ignored:
SELECT
    dtr.recommendation_id,
    dtr.recommendation_type,
    dtr.details.value('(//Value)[1]', 'nvarchar(max)') AS reason_for_ignore, -- Adjust the XPath based on the XML structure
    dtr.state
FROM sys.dm_db_tuning_recommendations AS dtr
WHERE dtr.recommendation_type = 'FORCE_LAST_GOOD_PLAN'
AND dtr.details.exist('//QueryId[text() = <your_query_id>]') = 1; -- Replace <your_query_id>

-----------OR-working--------------------------

select * from sys.dm_db_tuning_recommendations


---------or--------

SELECT
    name,
    reason,
    score,
    JSON_VALUE(details, '$.implementationDetails.script') AS script,
    details.*
FROM
    sys.dm_db_tuning_recommendations
CROSS APPLY
    OPENJSON(details, '$.planForceDetails')
    WITH (
        [query_id] INT '$.queryId',
        regressed_plan_id INT '$.regressedPlanId',
        last_good_plan_id INT '$.recommendedPlanId'
    ) AS details
WHERE
    --JSON_VALUE(STATE, '$.currentValue') = 'Active'
    query_id in (11002520,11036405);


--- query to retrieve detailed information about query plans that have been manually forced using the Query Store feature in Azure SQL DB Server:

SELECT
    qt.query_text_id,
    qt.query_sql_text,
    q.query_id,
    rs.plan_id,
    fpl.force_failure_count,
    fpl.last_force_failure_reason,
    fpl.last_force_failure_time,
    fpl.force_plan_state,
    CASE fpl.force_plan_state
        WHEN 0 THEN 'Not Forced'
        WHEN 1 THEN 'Forced'
        WHEN 2 THEN 'Failed to Force'
        WHEN 3 THEN 'Force Throttled'
        ELSE 'Unknown'
    END AS force_plan_state_desc,
    fpl.last_good_plan_id,
    rs_lgp.plan_id AS last_good_plan_plan_id,
    qpe_lgp.query_plan AS last_good_plan_query_plan,
    qpe_lgp.query_plan_hash AS last_good_plan_query_plan_hash
FROM sys.query_store_query_text AS qt
INNER JOIN sys.query_store_query AS q
    ON qt.query_text_id = q.query_text_id
INNER JOIN sys.query_store_plan AS p
    ON q.query_id = p.query_id
INNER JOIN sys.query_store_runtime_stats AS rs
    ON p.plan_id = rs.plan_id
LEFT JOIN sys.query_store_forced_plan AS fpl
    ON p.plan_id = fpl.plan_id
LEFT JOIN sys.query_store_plan AS p_lgp
    ON fpl.last_good_plan_id = p_lgp.plan_id
LEFT JOIN sys.query_store_runtime_stats AS rs_lgp
    ON p_lgp.plan_id = rs_lgp.plan_id
LEFT JOIN sys.query_store_query_plan AS qpe_lgp
    ON p_lgp.plan_id = qpe_lgp.plan_id
WHERE
    fpl.force_plan_state = 1 -- To filter for queries with a forced plan
    OR q.query_id = <your_query_id>
    OR p.plan_id = <your_plan_id>;

	---------------------Similar for MI Server------------

select * from sys.query_store_plan where query_id in (8671960,8671959)



------------to examine the details of the forced plan using the query you previously provided

SELECT qpe.query_plan
FROM sys.query_store_plan AS p
JOIN sys.query_store_query AS q ON p.query_id = q.query_id
JOIN sys.query_store_query_text AS qt ON q.query_text_id = qt.query_text_id
CROSS APPLY sys.dm_exec_query_plan (p.plan_id) AS qpe
WHERE p.plan_id = <your_forced_plan_id>;


-------To get whether APRC is off for a specfic forced plan 

SELECT *
FROM sys.database_automatic_tuning_configurations;



Summary of the reasons and troubleshooting steps for the "Internal Query Processor Error" when a forced plan causes issues:

**Reasons for "Internal Query Processor Error" with Forced Plans:**

* **Invalid Forced Plan:** The most likely reason. The forced plan has become incompatible with the current database state due to:
    * **Schema Changes:** Index drops/creations, column data type changes.
    * **Statistics Changes:** Significant data distribution shifts (less common for complete failure).
    * **Database Option Changes:** Alterations affecting query execution.
    * **SQL Server Upgrade/Patch:** Optimizer changes making the old plan invalid.
* **Corruption/Inconsistency:** Rare, but the stored forced plan might be internally corrupted.

**Why Unforcing Fixes It:**

* Allows the query optimizer to generate a *new*, compatible execution plan based on the current database environment.

**Troubleshooting Steps (Summary):**

1.  **Examine the Forced Plan:** If possible, inspect the XML of the problematic forced plan for unusual operators or references.
2.  **Compare Database Schema:** Check for any recent changes to tables or indexes involved in the query.
3.  **Review Database Options:** Verify if any relevant database-level settings have been modified.
4.  **Check SQL Server Error Logs:** Look for other related errors or warnings.
5.  **Consider Re-forcing (Cautiously):** If forcing is still desired, capture and force a *new* execution plan of the query in its current environment, *not* the old problematic one.

**In essence: The forced plan likely became outdated or invalid due to changes in the database. Unforcing allows the system to create a fresh, compatible plan.**



-----[References]
 sp_configure_automatic_tuning (Transact-SQL) - SQL Server | Microsoft Learn

https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-query-store-unforce-plan-transact-sql?view=sql-server-ver16

