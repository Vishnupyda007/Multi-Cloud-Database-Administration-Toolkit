

/****** Object:  StoredProcedure [dbo].[USP_DR_Replication_Status_Report]    Script Date: 2/12/2025 12:10:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/****** Object:  StoredProcedure [dbo].[USP_DR_Replication_Status_Report]      
--SET ANSI_NULLS ON      
--GO      
--SET QUOTED_IDENTIFIER ON      
--GO      
-- =============================================      
-- Author:  <Hima Vishnu P>      
-- Create date: <9:40PM,12 May,2025>      
-- Description: <Description,,>     
--- EXEC USP_Prod_Replication_Status_Report  
------ ============================================= ***/  

CREATE PROCEDURE [dbo].[USP_DR_Replication_Status_Report]   
WITH ENCRYPTION

AS      
BEGIN   
    CREATE TABLE #tempo(  
        status int,  
        warning int,   
        subscriber sysname,  
        subscriber_db sysname,  
        publisher_db sysname,  
        publication sysname,  
        publication_type int,  
        subtype int,  
        latency int,   
        latencythreshold int,  
        agentnotrunning int,  
        agentnotrunningthreshold int,  
        timetoexpiration int,  
        expirationthreshold int,  
        last_distsync datetime,  
        distribution_agentname sysname,  
        mergeagentname sysname NULL,  
        mergesubscriptionfriendlyname sysname NULL,  
        mergeagentlocation sysname NULL,  
        mergeconnectiontype sysname NULL,  
        mergePerformance sysname NULL,  
        mergerunspeed sysname NULL,  
        mergerunduration sysname NULL,  
        monitorranking int,   
        distributionagentjobid sysname NULL,  
        mergeagentjobid int,  
        distributionagentid int,  
        distributionagentprofileid int,  
        mergeagentid int,  
        mergeagentprofileid int,  
        logreaderagentname sysname NULL,  
        publisher sysname NULL  
    );  

    INSERT INTO #tempo 
    SELECT * 
    FROM [1CDBAMonitoring].dbo.[DR_Replication_Status_Report_Tbl] with(nolock);  

    DECLARE @body_HTML nvarchar(max) = N'';  
    DECLARE @hasData BIT = 0;    

    IF EXISTS (SELECT 1 FROM #tempo WHERE publisher = 'ctsazdrmibccrs.inso1a101c37461fa.database.windows.net')  
    BEGIN  
        SET @hasData = 1;  
        SET @body_HTML = @body_HTML + 
            N'<H2 align="Left"><font face="Lucida Bright" color="blue" size="3">PAAS DR Replication Status:</font></H2>' +  
            N'<table border="1">' +  
            N'<font face="fantasy" size="2" font-family="Serif"><tr><th style="background:#87ceeb">Publication</th><th style="background:#87ceeb">Destination Server</th>' +  
            N'<th style="background:#87ceeb">Replication Status</th><th style="background:#87ceeb">Latency (In Sec)</th><th style="background:#87ceeb">Time of Last Sync</th></tr></font><font face="bold" font-family="Serif" color="Black" size="2" style="height:100px" style="width:100%">' +  
            CAST((SELECT td = Publication, '',  
                         td = subscriber, '',  
                         td = CASE status   
                                WHEN 1 THEN 'Started'  
                                WHEN 2 THEN 'Succeed'  
                                WHEN 3 THEN 'In Progress'  
                                WHEN 4 THEN 'Idle'  
                                WHEN 5 THEN 'Retrying'  
                                WHEN 6 THEN 'Failed'  
                              END, '',  
                         td = CAST(latency AS VARCHAR(50)), '',  
                         td = CAST(last_distsync AS VARCHAR(100)), ''  
                  FROM #tempo 
                  WHERE publisher = 'ctsazdrmibccrs.inso1a101c37461fa.database.windows.net' 
                  ORDER BY latency DESC
                  FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +  
            N'</font></table>';
    END;  

    IF EXISTS (SELECT 1 FROM #tempo WHERE publisher ='ctsinazdredssqlmi.inso1a101c37461fa.database.windows.net')  
    BEGIN  
        SET @hasData = 1;  
        SET @body_HTML = @body_HTML +
            N'<br> <br>
			<H2 align="Left"><font face="Lucida Bright" color="blue" size="3">EDS DR Replication Status:</font></H2>' +  
            N'<table border="2">' +  
            N'<font face="bold" size="2" font-family="Serif"><tr><th style="background:#87ceeb">Publication</th><th style="background:#87ceeb">Destination Server</th>' +  
            N'<th style="background:#87ceeb">Replication Status</th><th style="background:#87ceeb">Latency (In Sec)</th><th style="background:#87ceeb">Time of Last Sync</th></tr></font><font face="bold" font-family="Serif" color="Black" size="2">' +  
            CAST((SELECT td = Publication, '',  
                         td = subscriber, '',  
                         td = CASE status   
                                WHEN 1 THEN 'Started'  
                                WHEN 2 THEN 'Succeed'  
                                WHEN 3 THEN 'In Progress'  
                                WHEN 4 THEN 'Idle'  
                                WHEN 5 THEN 'Retrying'  
                                WHEN 6 THEN 'Failed'  
                              END, '',  
                         td = CAST(latency AS VARCHAR(50)), '',  
                         td = CAST(last_distsync AS VARCHAR(100)), ''  
                  FROM #tempo 
                  WHERE publisher = 'ctsinazdredssqlmi.inso1a101c37461fa.database.windows.net' 
                  ORDER BY latency DESC
                  FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX)) +  
            N'</font></table>';  
    END; 

    IF @hasData = 1  
    BEGIN  
        SET @body_HTML = 
            '<style>  
                tr {  
                    border:1px solid black;  
                    border-collapse: collapse;  
                    font-family:Serif;  
                    style="background:#87ceeb";
                }  
                td, tr {  
                    padding: 3px;
                }  
            </style>' + @body_HTML;

        DROP TABLE #tempo;  
        SELECT @body_HTML;   

        EXEC msdb.dbo.sp_send_dbmail   
            @subject = 'DR Replication Status Report',  
            @profile_name = 'ITOps1CDBA',  
            @recipients = 'CRSDBASUPPORT@cognizant.com;EDMDBA@cognizant.com;CISADPInfraSupportTeam@cognizant.com',
            --@copy_recipients = 'kirankumar.gannavaram@cognizant.com;ashwathi.k@cognizant.com;pydavenkata.srihimavishnuseshasai@cognizant.com',  
            @body = @body_HTML,  
            @body_format = 'HTML';  
    END;  
END;
GO


