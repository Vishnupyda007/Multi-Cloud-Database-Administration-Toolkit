USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[MI_Servers_Storage_Space_Report]    Script Date: 11/5/2024 4:23:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

  
/****** Object:  StoredProcedure [dbo].[MI_Servers_Storage_Space_Report]    Script Date: 21-02-2023 5.10.03 PM ******/  
--SET ANSI_NULLS ON  
--GO  
--SET QUOTED_IDENTIFIER ON  
--GO  
-- =============================================  
-- Author:  <Author,,Name>  
-- Create date: <Create Date,,>  
-- Description: <Description,,>  
------ =============================================  
ALTER PROCEDURE [dbo].[MI_Servers_Storage_Space_Report]  
   
AS  
BEGIN  
  --SET NOCOUNT ON added to prevent extra result sets from  
  --interfering with SELECT statements.  
  
--update MI_Servers_Storage_Space_Daily set [percent] =  
--(((Available_GB/(Total_TB*1024))*100))  
----as 'percent'   
--from  
--MI_Servers_Storage_Space_Daily   
  
CREATE TABLE #tempo(  
 Servername nvarchar(200), total_TB Decimal(9,3), Used_TB decimal(9,3),Available_GB decimal(9,3) ,[percent] int   
)  
  
INSERT INTO #tempo select * from MI_Servers_Storage_Space_Daily   
  
update #tempo set [percent] =  
(((Available_GB/(Total_TB*1024))*100))  
--as 'percent'   
from  
#tempo   
  
Select * From #tempo  
   
Declare @date Nvarchar(MAX)  
SET @date = GETDATE();  
DECLARE @html varchar(MAX) = ' 
<p> 
Hi Team, 
<br>Please find the below Production MI Servers storage details.<br> 
<br> <br>
</p>
<table id="tablaPrincipal" border=2  
<table border = 1>   
<tr style="background:#a7bfde;font-weight:bold;">                     
<th> Servername </th> <th> Total_Space_TB </th> <th> Used_Space_TB </th>     
<th> Available_Space_GB </th> <th> Available_Space_Percentage </th>                    
</tr>'SELECT @html =  @html + '<tr style="color:'+case when [percent] <= 20 then 'red' else 'black' end +';"><td>'+  
case when [percent] <=10  then '<b>' else '' end +    
Servername + '</td><td>'+case when [percent] <=10  then '<b>' else '' end    + cast(Total_TB as nvarchar(2000)) + '</td><td>'+case when [percent] <=10  then '<b>' else '' end +cast(Used_TB as nvarchar(2000))  
+ '</td> <td>' +case when [percent] <=10  then '<b>' else '' end+cast(Available_GB as nvarchar(2000)) + '</td> <td>'+case when [percent] <=10  then '<b>' else '' end  + cast([Percent] as nvarchar(2000)) +'</td> </tr>'   
FROM #tempo order by [percent] asc  
  
--DECLARE @html varchar(MAX) = '<table id="tablaPrincipal" border=0>      
--<tr style="background:#a7bfde;font-weight:bold;">                
--<td>Servername</td>                        <td>Total_TB</td>       
--<td>Used_TB</td>                        <td>Available_GB</td>            
--<td>Percent</td>                   
--</tr>'SELECT @html = @html + '<tr  background= '+ case when [percent]>20  then 'red' else 'green' end  
--+';"><td>' +  Servername + '</td><td>' + cast(Total_TB as nvarchar(2000)) +   
--'</td><td>' +cast(Used_TB as nvarchar(2000)) + '</td> <td>' +cast(Available_GB as nvarchar(2000))  
--+ '</td> <td>' + cast([percent] as nvarchar(2000)) + '</td> </tr>' FROM #tempo  
--bgcolor="black" style="font-weight:bold;color:white"  
DROP TABLE #tempo  
  
Select @html  
  
EXEC msdb.dbo.sp_send_dbmail  
@profile_name='CRS',  
@recipients='CRSDBASUPPORT@cognizant.com',  
@body = @html,  
@body_format ='HTML',  
@subject = 'Daily Prod MI Storage Report' ;  
  
END  
  
  
  
--Exec [dbo].[FinalReport ]  
GO

