/****** Object:  StoredProcedure [dbo].[USP_Non_Prod_Replication_Status_Report]    
--SET ANSI_NULLS ON    
--GO    
--SET QUOTED_IDENTIFIER ON    
--GO    
-- =============================================    
-- Author:  <Hima Vishnu P>    
-- Create date: <Create Date,,>    
-- Description: <Description,,>   
--- EXEC USP_Non_Prod_Replication_Status_Report
------ ============================================= ***/

ALTER PROCEDURE [dbo].[USP_Non_Prod_Replication_Status_Report]    
     
AS    
BEGIN 

CREATE TABLE #tempo(
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


INSERT INTO #tempo select * from DBAdmin.dbo.Non_Prod_Replication_Status_Report 



DECLARE @tableHTML NVARCHAR(MAX) ;

SET @tableHTML =

'<style>
 tr {
border:1px solid black;
border-collapse: collapse;
font-family:Serif;
style="background:#87ceeb";}
td,tr {
padding: 3px;}
</style>' +
N'<H2 align = "Left"><font face="Lucida Bright" color="blue" size = "2.5">CRSSIT Transactional Replication Status:</font></H2>' +
N'<table border="1">' +
N'<font face="fantasy" size = "2" font-family:Serif><tr><th style="background:#87ceeb">Publication</th><th style="background:#87ceeb">Destination Server</th>' +
N'<th style="background:#87ceeb">Replication Status</th><th style="background:#87ceeb"> Latency (In Sec)</th><th style="background:#87ceeb">Time of Last Sync</th></tr></font><font face="bold" font-family:Serif color="Black" size = "2" style="height:100px" style="width:100%">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In Progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM #tempo where publisher= 'CTSC01048403401\CRSSIT' order by latency DESC
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' +




N'<H2 align = "Left"><font face="Lucida Bright" color="blue" size = "2.5">CRSUAT Transactional Replication Status:</font></H2>' +
N'<table border="2">' +
N'<font face="bold" size = "2" font-family:Serif><tr><th style="background:#87ceeb">Publication</th><th style="background:#87ceeb">Destination Server</th>' +
N'<th style="background:#87ceeb">Replication Status</th><th style="background:#87ceeb"> Latency (In Sec)</th><th style="background:#87ceeb">Time of Last Sync</th></tr></font><font face="bold" font-family:Serif color="Black" size = "2">' +
CAST ( ( SELECT td =Publication, '',
td = subscriber, '',
td = CASE status 
WHEN 1 THEN 'Started'
WHEN 2 THEN 'Succeed'
WHEN 3 THEN 'In Progress'
WHEN 4 THEN 'Idle'
WHEN 5 THEN 'Retrying'
WHEN 6 THEN 'Failed'
END,'',
td = CAST(latency as VARCHAR(50)), '',
td = CAST(last_distsync as varchar(100)), ''
FROM #tempo where publisher= 'CTSC01048405301\CRSUAT' order by latency DESC
FOR XML PATH('tr'), TYPE 
) AS NVARCHAR(MAX) ) +
N'</font></table>' ;




--SET @tableHTML = REPLACE(@tableHTML, 'In progress', '<B><font face="verdana" color="GREEN" size = "2">In progress </Font></B>')
--SET @tableHTML = REPLACE(@tableHTML, 'Succeed', '<B><font face="verdana" color="GREEN" size = "2"> Succeed </Font></B>')
--SET @tableHTML = REPLACE(@tableHTML, 'Start', '<B><font face="verdana" color="GREEN" size = "2"> Start </Font></B>')
--SET @tableHTML = REPLACE(@tableHTML, 'Idle', '<B><font face="verdana" color="GREEN" size = "2"> Idle </Font></B>')
--SET @tableHTML = REPLACE(@tableHTML, 'Retrying', '<B><font face="verdana" color="Blue" size = "2"> Retrying </Font></B>')
--SET @tableHTML = REPLACE(@tableHTML, 'Failed', '<B><font face="verdana" color="Red" size = "3"> Failed </Font></B>')

DROP TABLE #tempo
Select @tableHTML 

EXEC msdb.dbo.sp_send_dbmail 
    @subject = 'Non Prod Replication Status Report',
	  @profile_name = 'CRS',
	@recipients='pydavenkata.srihimavishnuseshasai@cognizant.com;kirankumar.gannavaram@cognizant.com',
    @body = @tableHTML,
    @body_format = 'HTML' ;

END


go