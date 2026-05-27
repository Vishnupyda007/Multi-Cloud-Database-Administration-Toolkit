DECLARE @tableHTML NVARCHAR(MAX) ;
CREATE TABLE #TEMP(
status int
,warning int 
,subscriber sysname
,subscriber_db sysname
,publisher_db sysname
,publication sysname
,publication_type int
,subtype int
,latency int 
,latencythreshold int
,agentnotrunning int
,agentnotrunningthreshold int
,timetoexpiration int
,expirationthreshold int
,last_distsync datetime
,distribution_agentname sysname
,mergeagentname sysname NULL
,mergesubscriptionfriendlyname sysname NULL
,mergeagentlocation sysname NULL
,mergeconnectiontype sysname NULL
,mergePerformance sysname NULL
,mergerunspeed sysname NULL
,mergerunduration sysname NULL
,monitorranking int 
,distributionagentjobid sysname NULL
,mergeagentjobid int
,distributionagentid int
,distributionagentprofileid int
,mergeagentid int
,mergeagentprofileid int
,logreaderagentname sysname null
,publisher sysname null
)
EXEC sp_replmonitorhelpsubscription @publication_type = 0
INSERT #TEMP
EXEC sp_replmonitorhelpsubscription @publication_type = 0

SET @tableHTML =
N'<H3 align = "Left"><font face="verdana" color="green" size = "2">CRSSIT Transactional Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM #TEMP
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' ;


SET @tableHTML =
N'<H3 align = "Left"><font face="verdana" color="green" size = "2">CRSUAT Transactional Replication Status:</font></H3>' +
N'<table border="1">' +
N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>DestinationServer</th>' +
N'<th>Replication Status</th><th> Latency (In Sec)</th><th>Time of Last Sync</th></tr></font><font face="verdana" color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM #TEMP
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' +


--SET @tableHTML = @tableHTML + 
--N'<H3 align = "Left"><font face="verdana" color="green" size = "2">Snapshot Replication Status:</font></H3>' +
--N'<table border="1">' +
--N'<font face="verdana" color="blue" size = "2"><tr><th>Publication</th><th>Replication Status</th>' +
--N'<th>Start Time</th><th> Duration (In Sec) </th><th>Comments </th></tr></font><font face="verdana" color="Black" size = "2">' +
--CAST ( ( SELECT td =C.PUBLICATION, '',
--td = CASE A.RUNSTATUS 
--WHEN 1 THEN 'Start'
--WHEN 2 THEN 'Succeed'
--WHEN 3 THEN 'In progress'
--WHEN 4 THEN 'Idle'
--WHEN 5 THEN 'Retrying'
--WHEN 6 THEN 'Failed'
--END, '',
--td = CAST(A.START_TIME AS VARCHAR(50)), '',
--td = A.DURATION, '',
--td = A.COMMENTS, ''
--FROM DISTRIBUTION.DBO.MSSNAPSHOT_HISTORY A
--JOIN
--(SELECT AGENT_ID, MAX(TIME) TIME FROM DISTRIBUTION.DBO.MSSNAPSHOT_HISTORY 
--GROUP BY AGENT_ID) B
--ON A.AGENT_ID = B.AGENT_ID
--AND A.TIME = B.TIME
--JOIN MSSNAPSHOT_AGENTS C
--ON A.AGENT_ID = C.ID
--AND C.PUBLICATION_TYPE = 1
--FOR XML PATH('tr'), TYPE 
--) AS NVARCHAR(MAX) ) +
--N'</font></table>' ;

--SET @tableHTML = REPLACE(@tableHTML, 'In progress', '<B><font face="verdana" color="GREEN" size = "2">In progress </Font></B>')
--SET @tableHTML = REPLACE(@tableHTML, 'Succeed', '<B><font face="verdana" color="GREEN" size = "2"> Succeed </Font></B>')
--SET @tableHTML = REPLACE(@tableHTML, 'Start', '<B><font face="verdana" color="GREEN" size = "2"> Start </Font></B>')
--SET @tableHTML = REPLACE(@tableHTML, 'Idle', '<B><font face="verdana" color="GREEN" size = "2"> Idle </Font></B>')
--SET @tableHTML = REPLACE(@tableHTML, 'Retrying', '<B><font face="verdana" color="Blue" size = "2"> Retrying </Font></B>')
--SET @tableHTML = REPLACE(@tableHTML, 'Failed', '<B><font face="verdana" color="Red" size = "3"> Failed </Font></B>')

DROP TABLE #TEMP
Select @tableHTML 

EXEC msdb.dbo.sp_send_dbmail 
    @subject = 'Non Prod Replication Status Report',
	  @profile_name = 'CRS',
	  @recipients='pydavenkata.srihimavishnuseshasai@cognizant.com',
    @body = @tableHTML,
    @body_format = 'HTML' ;

go


