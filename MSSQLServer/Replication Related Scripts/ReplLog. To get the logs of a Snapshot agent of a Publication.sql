USE distribution;
GO

SELECT 
    p.publication AS [PublicationName],
    sh.agent_id,
    sh.runstatus,
    sh.start_time,
    sh.time,
    sh.duration,
    sh.comments,
    sh.delivered_transactions,
    sh.delivered_commands,
    sh.delivery_rate,
    sh.error_id,
    sh.timestamp
FROM 
    dbo.MSsnapshot_history sh
INNER JOIN 
    dbo.MSpublications p ON sh.agent_id = p.publication_id
	where sh.agent_id=43
ORDER BY 
    sh.time DESC;
