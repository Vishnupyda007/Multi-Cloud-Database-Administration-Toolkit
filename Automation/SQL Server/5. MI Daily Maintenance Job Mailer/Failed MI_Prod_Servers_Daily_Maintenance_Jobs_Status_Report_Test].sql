USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[MI_Prod_Servers_Daily_Maintenance_Jobs_Status_Report]    Script Date: 1/27/2025 6:52:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





 
    
/***** Object:  StoredProcedure [dbo].[MI_Prod_Servers_Weekly_Maintenance_Jobs_Status_Report]    Script Date: 11-11-2024 2.10.03 PM ******/     
-- =============================================    
-- Author:  <Hima Vishnu P>    
-- Create date: <27-01-2025>    
-- Description: <Description,,>    
------ =============================================    
Create PROCEDURE [dbo].[MI_Prod_Servers_Daily_Maintenance_Jobs_Status_Report_Test]    
     
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
<style>    
        tr {    
        border:1px solid black;    
        border-collapse: collapse;    
        font-family:Serif;   
		align: Center;
        style="background:#87ceeb";}    
        td,tr { 
		align:center;
		text-align:Center;
        padding: 3px;}    
</style>

<table id="tablaPrincipal"    
<tr  font-style:initial;style="height:80">                       
<table border="1"> 
<font face="fantasy" size = "2" font-family:Serif><tr>
<th style="background:#87ceeb">Server Name</th>
<th style="background:#87ceeb">Job Name</th>
<th style="background:#87ceeb">Last Run Start Time</th>
<th style="background:#87ceeb">Last Run End Time</th>
<th style="background:#87ceeb">Job Enable Status</th>
<th style="background:#87ceeb">Job Last Run Status</th>
<th style="background:#87ceeb">Next Run Date</th>
</tr></font>
<font face="bold" font-family:Serif color="Black" size = "2">                

'SELECT @html =  @html + 
'<tr style="color:'+case when [Job_Enable_Status] = 'Disabled' then 'orange' when [Job_LastRun_Status] = 'Failed' then 'red' else 'black' end +';">
<td style="text-align:Center;">'+ Servername +'</td>
<td style="text-align:Center;">'+ JobName +'</td>
<td style="text-align:Center;">'+ LastRun_StartTime +'</td> 
<td style="text-align:Center;">'+ LastRun_EndTime +'</td> 
<td style="text-align:Center;">'+ Job_Enable_Status +'</td>
<td style="text-align:Center;">'+ Job_LastRun_Status +'</td>
<td style="text-align:Center;">'+ Next_Run_Date +'</td> 
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


