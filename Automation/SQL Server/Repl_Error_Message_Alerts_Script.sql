USE [Monitoring] 
IF OBJECT_ID('dbo.EDSQA_REPL_ERRORS_TBL_Email','U') IS NOT NULL
DROP TABLE dbo.EDSQA_REPL_ERRORS_TBL_Email
WAITFOR DELAY '00:00:00'

SELECT * INTO #REPL_ERROR_TBL FROM
(
SELECT 
--alert_id	
--,status	
--,agent_type	
--,agent_id	
--,error_id		
--,publisher	
publisher_db	
,publication
,alert_error_text
,alert_error_code
,article
--,publication_type	
,subscriber	
,subscriber_db	
--,destination_object	
--,source_object		
,time
FROM msdb..sysreplicationalerts WHERE time >= DATEADD(MINUTE, -30, GETDATE())
--ORDER BY time DESC
)a
IF EXISTS (SELECT * FROM #REPL_ERROR_TBL)
BEGIN
SELECT * INTO Monitoring..EDSQA_REPL_ERRORS_TBL_Email 
FROM #REPL_ERROR_TBL
END
DROP TABLE #REPL_ERROR_TBL
--SELECT * FROM Monitoring..EDSQA_REPL_ERRORS_TBL_Email 