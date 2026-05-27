USE distribution
GO
SELECT
    t.publisher_database_id,
    MinDate        = MIN(entry_Time),
    MaxDate        = MAX(entry_Time), -- was set to MIN
    OldCommands = COUNT_BIG(*)
FROM
    dbo.msrepl_transactions t with (nolock)
 
    join dbo.msrepl_commands s with (nolock)
    ON  s.publisher_database_id = t.publisher_database_id
    AND s.xact_seqno            = t.xact_seqno -- this additional criteria was missing
WHERE entry_time < GETDATE() -1
GROUP BY
    t.publisher_database_id  --102414141 6.30pm