
DECLARE @body_content nvarchar(max);
SET @body_content = N'
<p>   
Hi ITOps 1C DBA Team,
   
<br>We have detected replication errors in EDS QA related to below mentioend publications.
These errors are currently impacting the replication health, and we need immediate attention to resolve the issues.<br>
<br>EDS QA Publisher : ctsinazqaedssqlmi.inso13dfbbbfa2150.database.windows.net.<br>   
<br> <br>  
</p>  
<style>
 
table.GeneratedTable {
  width: 100%;
  background-color: #D3D3D3;
  border-collapse: collapse;
  border-width: 2px;
  border-color: #A9A9A9;
  border-style: solid;
  color: #000000;
}
table.GeneratedTable td, table.GeneratedTable th {
 
border:1px solid black;
border-collapse: collapse;
font-family:Serif;
} 
table.GeneratedTable th {
padding:10px;
text-align: center;
vertical-align: middle;
style=background:#87ceeb;
}
</style>

<table class="GeneratedTable">
<thead>
<tr>
<th>Publisher_db</th>
<th>Publication</th>
<th>Error_Message</th>
<th>Error_code</th>
<th>Article</th>
<th>Subscriber</th>
<th>Subscriber_db</th>
<th>ErrorReportedTime</th>
</tr>
</thead>
<tbody>' +
 
CAST(
 
(SELECT
 td = publisher_db, '',
 td = publication, '',
 td = alert_error_text, '',
 td = alert_error_code, '',
 td = article, '',
 td = subscriber, '',
 td = subscriber_db, '',
 td = time, ''
 
        FROM [CTSINAZQAEDSSQLMI.INSO13DFBBBFA2150.DATABASE.WINDOWS.NET].[Monitoring].[dbo].[EDSQA_REPL_ERRORS_TBL_Email]
		order by time desc
        FOR XML PATH('tr'), TYPE   
 
        ) AS nvarchar(max)
 
    ) +

 
  N'</tbody>
</table>';
IF EXISTS (
 
select * FROM [CTSINAZQAEDSSQLMI.INSO13DFBBBFA2150.DATABASE.WINDOWS.NET].[Monitoring].[dbo].[EDSQA_REPL_ERRORS_TBL_Email])
 
   BEGIN
 
      EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBA',
 
                                   @body         = @body_content,
 
                                                   @body_format = 'HTML',
 
                                   @recipients ='EDMDBA@cognizant.com;CRSDBASUPPORT@cognizant.com',
 
								   @copy_recipients='balakrishna.mannepalli@cognizant.com;kirankumar.gannavaram@cognizant.com;ashwathi.k@cognizant.com;vijaianand.pv@cognizant.com',
 
                                   @subject      = 'Immediate Attention Needed: Repliction Error Detected in EDS QA';
 
   END