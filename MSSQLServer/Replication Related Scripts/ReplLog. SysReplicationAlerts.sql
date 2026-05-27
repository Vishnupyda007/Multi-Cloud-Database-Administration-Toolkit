SELECT 	
    publisher,
    publisher_db,
    ISNULL(publication, 'NULL') AS publication,
    alert_error_text,
    alert_error_code,
    ISNULL(article, 'NULL') AS article,
    subscriber,
    subscriber_db,
    time
FROM [msdb].[dbo].sysreplicationalerts
ORDER BY time DESC