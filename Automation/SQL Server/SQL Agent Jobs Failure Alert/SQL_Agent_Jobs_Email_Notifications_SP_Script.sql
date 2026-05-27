DECLARE @body_content nvarchar(max);
SET @body_content = N'
<p>   
Hi EDS QA/Support Team,   
<br>Please find the below mentioned failed app jobs notifications and kindly check the reason for failures and do the needful.<br>   
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
  border-width: 2px;
  border-color: #A9A9A9;
  border-style: solid;
  padding: 3px;
  font-family:Serif;
}

table.GeneratedTable thead {
  background-color: #A9A9A9;
}
</style>


<table class="GeneratedTable">
  <thead>
    <tr>
         <th>ServerName</th>
         <th>JobName</th>
         <th>LastRun_StartTime</th>
         <th>LastRun_EndTime</th>
         <th>Job_LastRun_Status</th>
		 <th>ErrorMessage</th>
		 <th>Next_Run_Date</th>
		 <th>Frequency</th>
		 <th>NextScheduledTime</th>
    </tr>
  </thead>
  <tbody>' +
CAST(
(SELECT td = ServerName, '',
                               td = JobName, '',
                               td = LastRun_StartTime, '',
                               td = LastRun_EndTime, '',
                               td = Job_LastRun_Status, '',
							   td = ErrorMessage, '',
							   td = Next_Run_Date, '',
							   td = Frequency, '',
							   td = Time, ''
                            
        FROM [CTSINAZQAEDSSQLMI.INSO13DFBBBFA2150.DATABASE.WINDOWS.NET].[Monitoring].[dbo].[SQLMI_sysjobhistory_TBL_Email]
        FOR XML PATH('tr'), TYPE   
        ) AS nvarchar(max)
    ) +

				
  N'</tbody>
</table>';

IF EXISTS (select top 1 * FROM [CTSINAZQAEDSSQLMI.INSO13DFBBBFA2150.DATABASE.WINDOWS.NET].[Monitoring].[dbo].[SQLMI_sysjobhistory_TBL_Email]) 
   BEGIN
      EXEC msdb.dbo.sp_send_dbmail @profile_name = 'DBA',
                                   @body         = @body_content,
                                                             @body_format = 'HTML',
                                   @recipients ='EDMDBA@cognizant.com',
								   --;CRSEDSMigration@cognizant.com;EDSQA@cognizant.com
                                   @subject      = 'Action Required:SQL Agent Application Jobs Failure Alerts in EDS QA'; 
   END
