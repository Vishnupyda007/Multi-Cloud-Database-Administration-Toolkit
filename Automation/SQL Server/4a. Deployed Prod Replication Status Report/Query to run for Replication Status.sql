IF OBJECT_ID('tempdb..##TEMPReplStatus') IS NOT NULL
    DROP TABLE ##TEMPReplStatus
CREATE TABLE ##TEMPReplStatus(
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
use distribution
EXEC distribution.[sys].[sp_replmonitorhelpsubscription] @publication_type = 0
INSERT into ##TEMPReplStatus
EXEC distribution.[sys].[sp_replmonitorhelpsubscription] @publication_type = 0