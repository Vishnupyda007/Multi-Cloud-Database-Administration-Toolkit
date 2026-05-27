USE distribution;
GO

SELECT
    la.name AS 'LogReaderAgent_Name',
    la.publisher_db AS 'Publisher_db',
    lh.start_time AS 'Job_Start_Time',
    lh.[time] AS 'Message_Log_Time',
    CAST(lh.comments AS XML) AS Comments,
    CASE lh.runstatus
        WHEN 1 THEN 'Start'
        WHEN 2 THEN 'Succeed'
        WHEN 3 THEN 'In-Progress'
        WHEN 4 THEN 'Idle'
        WHEN 5 THEN 'Retry'
        WHEN 6 THEN 'Fail'
    END AS 'Run_Status',
    lh.duration AS 'Duration_Message_Session_sec',
    lh.delivered_transactions AS 'Delivered_Transactions_Per_Session',
    lh.delivered_commands AS 'Delivered_Cmds_Per_Session',
    lh.average_commands AS 'Avg_Cmds',
    lh.delivery_rate AS 'Cmd_Per_Sec',
    lh.delivery_latency AS 'Delivery_Latency_ms'
FROM
    MSlogreader_history lh WITH (NOLOCK)
INNER JOIN
    MSlogreader_agents la ON lh.agent_id = la.id
ORDER BY
    lh.[time] DESC;



Comments Column: This column often contains an XML snippet with detailed performance stats, including the number of commands processed per second (cmdspersec).

Run_Status: "In-Progress" or "Idle" are normal. "Retry" or "Fail" indicate problems.

delivery_latency: This shows the latency in milliseconds between a transaction being committed on the Publisher and being delivered to the Distributor. 
 

------------------------------------------------------

Using sp_replcounters
This stored procedure provides a quick summary of replication activity, including the number of transactions and commands waiting to be delivered.

When to use it: For a very quick, high-level overview of the current state.

Script: Execute this on the Publisher server against the published database.

SQL
USE [YourPublicationDatabase];
GO
EXEC sp_replcounters;
GO
What to look for in the output:

Replicated transactions: The number of transactions in the log awaiting delivery to the distribution database. A consistently high or growing number indicates the Log Reader Agent is falling behind.

Replication rate trans/sec: The rate at which transactions are being processed.

