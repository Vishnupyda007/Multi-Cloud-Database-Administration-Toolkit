--Distribution Agent Performance
--You can query MSdistribution_history table to see how Distribution Agent performs.

USE distribution 
go 
SELECT TOP 100 time, 
Cast(comments AS XML) AS comments, 
runstatus, 
duration, 
xact_seqno, 
delivered_commands, 
average_commands, 
current_delivery_rate, 
delivered_transactions, 
error_id, 
delivery_latency 
FROM msdistribution_history WITH (nolock) 
ORDER BY time DESC 



--The output of the above query is similar to the output of the Log Reader history table. Look at the value of the Comments column. If you see messages with state 1 which means Distribution Agent is performing normally. Using xact_seqno you can identify the commands replicated. If you notice the same value for xact_seqno for a longer time which means it is replicating a large transaction.