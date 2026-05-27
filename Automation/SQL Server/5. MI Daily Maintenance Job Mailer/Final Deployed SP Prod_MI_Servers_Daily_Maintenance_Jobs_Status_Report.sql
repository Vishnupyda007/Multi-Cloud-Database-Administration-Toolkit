USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[MI_Prod_Servers_Daily_Maintenance_Jobs_Status_Report]    Script Date: 1/27/2025 6:52:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/***** Object:  StoredProcedure [dbo].[MI_Prod_Servers_Daily_Maintenance_Jobs_Status_Report]    Script Date: 11-11-2024 2.10.03 PM ******/     
-- =============================================    
-- Author:  <Hima Vishnu P>    
-- Create date: <27-01-2025>    
-- Description: <Description,,>    
------ =============================================    
ALTER PROCEDURE [dbo].[MI_Prod_Servers_Daily_Maintenance_Jobs_Status_Report]    
     
AS    
BEGIN    
  --SET NOCOUNT ON added to prevent extra result sets from    
  --interfering with SELECT statements.    
    
--update MI_Servers_Storage_Space_Daily set [percent] =    
--(((Available_GB/(Total_TB*1024))*100))    
----as 'percent'     
--from    
--MI_Servers_Storage_Space_Daily     
CREATE TABLE #temp(    
 [Servername] [nvarchar](200), [JobName] [nvarchar](200), [LastRun_StartTime] [varchar](200),[LastRun_EndTime] [varchar](200),
	[Job_Enable_Status] [char](100), [Job_LastRun_Status] [char](100),[Next_Run_Date] [varchar](200)
);  
INSERT INTO #temp select * from MI_Prod_Servers_Daily_Maintenance_Jobs_Status     
   
Select * From #temp with(nolock)
     
Declare @date Nvarchar(MAX) = convert(nvarchar,getdate(),101);   
--SET @date = GETDATE();    
DECLARE @html varchar(MAX) = '   
<p>   
Hi Team,   
<br>Please find the below Production MI Servers Daily Maintenance job Status Report.<br>   
<br> <br>  
</p>  
<style>
        table, th, td {    
        border:1px solid black;    
        border-collapse: collapse;    
        font-family:Serif;   
        text-align: center;
        padding: 3px;
		font-size: 10.5pt;
        }    
        th {
        background:#87ceeb;
        }
</style>

<table id="tablaPrincipal">    
<tr>                       
<th>Server Name</th>
<th>Job Name</th>
<th>Last Run Start Time</th>
<th>Last Run End Time</th>
<th>Job Enable Status</th>
<th>Job Last Run Status</th>
<th>Next Run Date</th>
</tr>                

'SELECT @html =  @html + 
'<tr style="color:'+case when [Job_Enable_Status] = 'Disabled' then 'orange' when [Job_LastRun_Status] = 'Failed' then 'red' else 'black' end +';">
<td>'+ Servername +'</td>
<td>'+ JobName +'</td>
<td>'+ LastRun_StartTime +'</td> 
<td>'+ LastRun_EndTime +'</td> 
<td>'+ Job_Enable_Status +'</td>
<td>'+ Job_LastRun_Status +'</td>
<td>'+ Next_Run_Date +'</td> 
</tr>'  
FROM #temp with(nolock) order by [Job_Enable_Status],[Job_LastRun_Status] asc    
    
DROP TABLE #temp    
    
Select @html    
    
EXEC msdb.dbo.sp_send_dbmail    
@profile_name='CRS',    
@recipients='pydavenkata.srihimavishnuseshasai@cognizant.com',
--@recipients ='person1@email.com;person2@email.com;person3@email.com',  
@body = @html,    
@body_format ='HTML',    
@subject = 'Daily Prod MI Maintenance Jobs Status Report' ;    
    
END    
GO