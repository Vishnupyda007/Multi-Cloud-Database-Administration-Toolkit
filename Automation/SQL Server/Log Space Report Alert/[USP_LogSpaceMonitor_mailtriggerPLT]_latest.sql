USE [master]
GO

/****** Object:  StoredProcedure [dbo].[USP_LogSpaceMonitor_mailtriggerPLT]    Script Date: 6/16/2025 7:02:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
ALTER Proc [dbo].[USP_LogSpaceMonitor_mailtriggerPLT]   
  
AS   
Begin   
  
DECLARE @servername varchar(max)  
SELECT @servername = Instancename FROM [dbo].[atLogspacePLT]   
     
Declare @Heading varchar(100),@head varchar(100),@tableHtml varchar(max)     
  
if exists(select * from [dbo].[atLogspacePLT] where UsedSpace_Per >=80 )     
 Begin    
   
    
 Set @Heading = 'Log Space details for SERVER : '+ @servername     
 SET @tableHTML = N'<HTML>  
<HEAD>  
<TITLE>Fragmentation</TITLE>  
<BODY>'+                                                               
'<style>
 td {
 font-size:14;
 }
 td,TH {
 font-family:Serif;
 }
</style>
<TABLE border="1" style="border-collapse:collapse; style="font-family:verdana; font-size:12;">     
<TR><TH COLSPAN="7" bgColor="Blue" style="font-family:verdana; font-size:15; font-weight:bold; text-align:Center"><H>'+ @Heading +'</H></TH></TR>     
<TH bgColor="#ADD8E6" style="color:black;"><STRONG>DB Name</STRONG></FONT></TH>     
<TH bgColor="#ADD8E6" style="color:black;"><STRONG>Old Size (MB)</STRONG></FONT></TH>     
<TH bgColor="#ADD8E6" style="color:black;"><STRONG>Current Log Size (MB)</STRONG></FONT></TH>     
<TH bgColor="#ADD8E6" style="color:black;"><STRONG>Used Space (%)</STRONG></FONT></TH>     
<TH bgColor="#ADD8E6" style="color:black;"><STRONG>File Size changed</STRONG></FONT></TH>     
<TH bgColor="#ADD8E6" style="color:black;"><STRONG>Recovery Model</STRONG></FONT></TH>   
<TH bgColor="#ADD8E6" style="color:black;"><STRONG>Reason : Log not getting Reused</STRONG></FONT></TH></TR>'+     
                        CAST((select        
                         td = DBName, ''     
                        ,td =  oldsize, ''     
                        ,td =  CurSize_MB, ''     
                        ,td =  UsedSpace_Per, ''     
                        ,td =  GrowthTime, ''     
                        ,td =  RecoveryModel, ''    
                        ,td =  LogWait_Description , ''     
                        From (select (case when L.oldsize<> L.CurSize_MB Then L.dbname+'***'     
                        else L.dbname 
						End) as
   DBName ,L.Oldsize,convert(varchar(10),L.CurSize_MB) as 'CurSize_MB',convert(varchar(10),L.UsedSize) as 'UsedSpace_Per',convert(varchar(20),L.GrowthTime) as 'GrowthTime',  
  L.RecoveryModel, L.LogWait_Description  from LogSpacePLT L     
      where L.UsedSize >=80)t     
                  FOR XML PATH('tr'), TYPE      
            ) AS NVARCHAR(MAX) ) +     
  N'</TABLE><BR><BR><B> <I> Note: <DBName>*** indicates that file size has been changed !</BODY></HTML>';      
--print      
 print @tableHTML      
 select @tableHtml
 select * from [dbo].[atLogspacePLT] where UsedSpace_Per >=80 
	
--############################Send Mail#############################     
     
 set @head = 'Log Space Report '+@servername+' > 90%'     
     
 --exec msdb.dbo.sp_send_dbmail         
 --@profile_name = 'Profile',   
 --@recipients = 'crs@cognizant.com',        
 --@subject = @head,     
 --@body = @tableHTML,         
 --@body_format = 'HTML'   
   
 exec msdb.dbo.sp_send_dbmail         
 @profile_name = '1C Mails',   
 --@recipients = 'Ashwathi.K@cognizant.com;Jisha.VB@cognizant.com;CRSDBASUPPORT@cognizant.com', 
 @recipients='CRSDBASUPPORT@cognizant.com',
 --@recipients='PydaVenkata.SrihimaVishnuSeshasai@cognizant.com',
 @subject = @head,     
 @body = @tableHTML,         
 @body_format = 'HTML'      
      
     
End   
End   
  
  
GO

