USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[MI_Prod_Servers_Weekly_Maintenance_Jobs_Status_Report]    Script Date: 11/11/2024 2:08:29 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
 
    
/***** Object:  StoredProcedure [dbo].[MI_Prod_Servers_Weekly_Maintenance_Jobs_Status_Report]    Script Date: 11-11-2024 2.10.03 PM ******/     
-- =============================================    
-- Author:  <Author,,Name>    
-- Create date: <Create Date,,>    
-- Description: <Description,,>    
------ =============================================    
ALTER PROCEDURE [dbo].[MI_Prod_Servers_Weekly_Maintenance_Jobs_Status_Report]    
     
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
    
INSERT INTO #temp select * from MI_Prod_Servers_Weekly_Maintenance_Jobs_Status     
    
     
    
Select * From #temp    
     
Declare @date Nvarchar(MAX) = convert(nvarchar,getdate(),101);   
--SET @date = GETDATE();    
DECLARE @html varchar(MAX) = '   
<p>   
Hi Team,   
<br>Please find the below Production MI Servers Bi-Weekly Maintenance jobs Status Report.<br>   
<br> <br>  
</p>  
<style>

table, td, th {
border:1px solid black;
border-collapse: collapse;}
th {
padding:10px;
text-align: center;
vertical-align: middle;}
</style>
<table id="tablaPrincipal"; style="font-family:Serif  
<table border ="1">     
<tr style="background:#87ceeb;; font-style:initial;style="height:80">                       
<th> Server Name </th> 
<th> Job Name </th> 
<th> Last Run Start Time </th>       
<th> Last Run End Time </th>
<th> Job Enable Status </th> 
<th> Job Last Run Status </th> 
<th> Next Run Date </th>                    
</tr>
'SELECT @html =  @html + '<tr style="color:'+case when [Job_LastRun_Status] = 'Failed' then 'red' else 'black' end +';"><td style="text-align: Center;">'  
+ Servername +'</td><td style="text-align: Center;">'+ JobName + '</td><td style="text-align: Center;">'+ LastRun_StartTime  + '</td style="text-align: Center;"> <td style="text-align: Center;">'+ LastRun_EndTime  + '</td> <td style="text-align: Center;">'+ Job_Enable_Status +'</td><td style="text-align: Center;">'+Job_LastRun_Status +'</td><td style="text-align: Center;">'+ Next_Run_Date +'</td> </tr>'  
FROM #temp order by [Job_LastRun_Status] asc    
    
   
DROP TABLE #temp    
    
Select @html    
    
EXEC msdb.dbo.sp_send_dbmail    
@profile_name='CRS',    
@recipients='pydavenkata.srihimavishnuseshasai@cognizant.com',    
@body = @html,    
@body_format ='HTML',    
@subject = 'Test- Bi Weekly Prod MI Maintenance Jobs Status Report' ;    
    
END    
    
    
    
  
GO


