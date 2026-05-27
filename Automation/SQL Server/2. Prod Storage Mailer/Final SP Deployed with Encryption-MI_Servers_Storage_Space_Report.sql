USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[MI_Servers_Storage_Space_Report]    Script Date: 2/12/2025 12:08:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


  
/****** Object:  StoredProcedure [dbo].[MI_Servers_Storage_Space_Report]    Script Date: 05-11-2024 5.10.03 PM ******/    
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
WITH ENCRYPTION

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
		p {
		font-family:Serif; 
		}
</style>
<table id="tablaPrincipal">    
<tr>                       
<th> Servername </th> 
<th> Total_Space_TB </th> 
<th> Used_Space_TB </th>       
<th> Available_Space_GB </th> 
<th> Available_Space_Percentage </th>                      
</tr>'SELECT @html =  @html + '<tr style="color:'+case when [percent] < 20 then 'red' else 'black' end +';">
<td style="text-align:Center;">'+case when [percent] <=10  then '<b>' else '' end +  Servername + '</td>
<td style="text-align:Center;">'+case when [percent] <=10  then '<b>' else '' end + cast(Total_TB as nvarchar(2000)) + '</td>
<td style="text-align:Center;">'+case when [percent] <=10  then '<b>' else '' end +cast(Used_TB as nvarchar(2000)) + '</td> 
<td style="text-align:Center;">'+case when [percent] <=10  then '<b>' else '' end+cast(Available_GB as nvarchar(2000)) + '</td> 
<td style="text-align:Center;">'+case when [percent] <=10  then '<b>' else '' end  + cast([Percent] as nvarchar(2000)) +'</td> 
</tr>'  
FROM #tempo order by [percent] asc    
    
   
DROP TABLE #tempo    
    
Select @html    
    
EXEC msdb.dbo.sp_send_dbmail    
@profile_name='CRS',    
@recipients='CRSDBASUPPORT@cognizant.com;EDMDBA@cognizant.com',    
@body = @html,    
@body_format ='HTML',    
@subject = 'Daily Prod MI Storage Report' ;    
    
END    
    
    
    
GO


