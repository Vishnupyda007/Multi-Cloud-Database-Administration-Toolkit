USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[USP_Prod_PAAS_Replication_Error_Alert]    Script Date: 2/12/2025 12:09:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


  
/****** Object:  StoredProcedure [dbo].[USP_Prod_PAAS_Replication_Error_Alert]        
--SET ANSI_NULLS ON        
--GO        
--SET QUOTED_IDENTIFIER ON        
--GO        
-- =============================================        
-- Author:  <Hima Vishnu P>        
-- Create date: <8:09PM,15 Feb,2025>        
-- Description: <Description,,>       
--- EXEC USP_Non_Prod_Replication_Error_Alert    
------ ============================================= ***/    
ALTER PROCEDURE [dbo].[USP_Prod_PAAS_Replication_Error_Alert]  
WITH ENCRYPTION

AS        
BEGIN     
    CREATE TABLE #temp  
    (  
        [publisher] nvarchar(200) NOT NULL,  
        [publisher_db] nvarchar(200) NOT NULL,  
        [publication] nvarchar(400) NULL,  
        [alert_error_text] nvarchar(max) NOT NULL,  
        [alert_error_code] nvarchar(200) NOT NULL,  
        [article] nvarchar(400) NULL,  
        [subscriber] nvarchar(200) NOT NULL,  
        [subscriber_db] nvarchar(200) NOT NULL,  
        [time] datetime NOT NULL  
    );   
  
    INSERT INTO #temp   
    SELECT * FROM [DBAdmin].[dbo].[Prod_PAAS_Replication_Error_Alert_Mail] with(nolock);  
  
 --select * from #temp with(nolock)  
  
    DECLARE @body_HTML nvarchar(max) = N'';  
    DECLARE @hasData BIT = 0;  
  
    IF EXISTS (SELECT 1 FROM #temp WHERE publisher = 'ctsazsimicrsmas.inso1a101c37461fa.database.windows.net')  
    BEGIN  
        SET @hasData = 1;  
        SET @body_HTML = @body_HTML +     
        N'<H2 align = "Left"><font face="Lucida Bright" color="blue" size = "2.5">PAAS Master Transactional Replication Error Status:</font></H2>' +    
        N'<table border="1">' +    
        N'<font face="fantasy" size = "2" font-family:Serif><tr><th style="background:#87ceeb">Publisher DB</th>' +    
        N'<th style="background:#87ceeb">Publication</th><th style="background:#87ceeb">Error Message</th>
		<th style="background:#87ceeb">Error Code</th><th style="background:#87ceeb">Article</th>
		<th style="background:#87ceeb">Subscriber</th><th style="background:#87ceeb">Subscriber_db</th>
		<th style="background:#87ceeb">Reported Time</th></tr></font>
		<font face="bold" font-family:Serif color="Black" size = "2">'+    
          
        CAST((SELECT   
            td = publisher_db, '',    
            td = publication, '',    
            td = alert_error_text, '',    
            td = alert_error_code, '',    
            td = article, '',    
            td = subscriber, '',    
            td = subscriber_db, '',    
            td = CAST(time as varchar(100)), ''    
        FROM   
            (SELECT DISTINCT   
                publisher_db,   
                publication,   
                alert_error_text,   
                alert_error_code,   
                article,   
                subscriber,   
                subscriber_db,   
                time   
            FROM #temp   
            WHERE publisher = 'ctsazsimicrsmas.inso1a101c37461fa.database.windows.net') AS subquery  
        ORDER BY   
            time DESC,   
            publisher_db DESC   
        FOR XML PATH('tr'), TYPE       
        ) AS nvarchar(max)) +       
        N'</font></table>';  
    END  
  
  --  IF EXISTS (SELECT 1 FROM #temp WHERE publisher = 'CTSC01048405301\CRSUAT')  
  --  BEGIN  
  --      SET @hasData = 1;  
  --      SET @body_HTML = @body_HTML +     
  --      N'<H2 align = "Left"><font face="Lucida Bright" color="blue" size = "2.5">CRSUAT Transactional Replication Error Status:</font></H2>' +    
  --      N'<table border="1">' +    
  --      N'<font face="fantasy" size = "2" font-family:Serif><tr><th style="background:#87ceeb">Publisher DB</th>' +    
  --      N'<th style="background:#87ceeb">Publication</th>
		--<th style="background:#87ceeb">Error Message</th><th style="background:#87ceeb">Error Code</th>
		--<th style="background:#87ceeb">Article</th><th style="background:#87ceeb">Subscriber</th>
		--<th style="background:#87ceeb">Subscriber DB</th>
  --      <th style="background:#87ceeb">Reported Time</th></tr></font>
  --      <font face="bold" font-family:Serif color="Black" size = "2">' +    
          
  --      CAST(    
          
  --      (SELECT   
  --          td = publisher_db, '',    
  --          td = publication, '',    
  --          td = alert_error_text, '',    
  --          td = alert_error_code, '',    
  --          td = article, '',    
  --          td = subscriber, '',    
  --          td = subscriber_db, '',    
  --          td = CAST(time as varchar(100)), ''   
  --      FROM   
  --          (SELECT DISTINCT   
  --              publisher_db,   
  --              publication,   
  --              alert_error_text,   
  --              alert_error_code,   
  --              article,   
  --              subscriber,   
  --              subscriber_db,   
  --              time   
  --          FROM #temp   
  --          WHERE publisher = '') AS subquery  
  --      ORDER BY   
  --          time DESC   
  --      FOR XML PATH('tr'), TYPE       
  --      ) AS nvarchar(max)) +    
  --      N'</font></table>';  
  --  END  
  
 
  
    IF @hasData = 1  
    BEGIN  
        SET @body_HTML =     
        N'<p>       
        Hi ITOps 1C DBA Team,    
        <br>We have detected replication error(s) in PAAS Master related to below mentioned publication(s).<br>
		<br> <br>      
        </p>' +  
  N'<style>    
        tr {    
        border:1px solid black;    
        border-collapse: collapse;    
        font-family:Serif;    
        style="background:#87ceeb";}    
        td,tr {    
        padding: 3px;} 
		p {
		font-family:Serif;}
        </style>' + @body_HTML;  
  
        EXEC msdb.dbo.sp_send_dbmail     
        @profile_name = 'CRS',    
        @body         = @body_HTML,    
        @body_format  = 'HTML',    
        @recipients ='RaviShankar.C@cognizant.com;Janani.M2dcbb3@cognizant.com;Badam.Navya@cognizant.com; Bindu.Raavi@cognizant.com;pradheep.kumartk@cognizant.com; megha.singhal@cognizant.com;
		Sneha.S5@cognizant.com;Vimalraj.S3@cognizant.com;vidya.erragopula@cognizant.com;
		Burra.Sandhya@cognizant.com;PydaVenkata.SrihimaVishnuSeshasai@cognizant.com;EDMDBA@cognizant.com',    
        @copy_recipients='rambabu.s@cognizant.com;vijaianand.pv@cognizant.com;kirankumar.gannavaram@cognizant.com;
		ashwathi.k@cognizant.com;balakrishna.mannepalli@cognizant.com',    
        @subject = 'Action Required: Replication Error Detected in PAAS Master';    
    END  
  
    DROP TABLE #temp;  
END    
GO


