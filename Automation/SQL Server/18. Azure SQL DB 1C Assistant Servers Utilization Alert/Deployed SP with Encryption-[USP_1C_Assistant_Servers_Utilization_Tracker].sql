



/***** Object:  StoredProcedure [dbo].[USP_1C_Assistant_Servers_Utilization_Tracker]    Script Date: 11-11-2024 2.10.03 PM ******/     
-- =============================================    
-- Author:  <Hima Vishnu P>    
-- Create date: <26-09-2025>    
-- Description: <Description,,>    
------ =============================================    
ALTER PROCEDURE [dbo].[USP_1C_Assistant_Servers_Utilization_Tracker]
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #temp1CAssistant(
  	[ServerName] [nvarchar](250) NULL,
	[avg_cpu_percent] [decimal](5, 2) NULL,
	[avg_log_write_percent] [decimal](5, 2) NULL,
	[avg_memory_usage_percent] [decimal](5, 2) NULL,
	[max_worker_percent] [decimal](5, 2) NULL,
	[avg_instance_cpu_percent] [decimal](5, 2) NULL,
	[avg_instance_memory_percent] [decimal](5, 2) NULL,
	AllocatedDataGB [decimal](10, 2) NULL,
	UsedDataGB [decimal](10, 2) NULL,
	AllocatedLogGB [decimal](10, 2) NULL,
	UsedLogGB [decimal](10, 2) NULL,
	TotalAllocatedGB [decimal](10, 2) NULL,
	TotalUsedGB [decimal](10, 2) NULL,
	FreeInsideFilesGB [decimal](10, 2) NULL,
	DatabaseMaxDataSizeGB [decimal](10, 2) NULL,
	FreeToMaxGB [decimal](10, 2) NULL,
	FreeInsideFilesPct [decimal](10, 2) NULL,
	FreeToMaxPct [decimal](10, 2) NULL,
	DataUsedPctOfMax [decimal](10, 2) NULL,
	LogUsedPctOfAllocated [decimal](10, 2) NULL,
	[Captured_time] [datetime] NULL
    );

    -- Populate the temp table with only the servers that have breached the threshold
    INSERT INTO #temp1CAssistant
    SELECT *
    FROM [1C_AI_Assistant_AzureDB_Utilization_tbl]
    WHERE avg_cpu_percent >= 85
       OR avg_log_write_percent >= 85
       OR avg_memory_usage_percent >= 90
       OR max_worker_percent >= 85
       OR avg_instance_cpu_percent >= 85
       OR avg_instance_memory_percent >= 90
	   OR FreeToMaxPct <=30
	   or LogUsedPctOfAllocated >=85;

    -- Only proceed to build and send the email IF there is data in the temp table
    IF EXISTS (SELECT 1 FROM #temp1CAssistant)
    BEGIN
        DECLARE @html NVARCHAR(MAX);

        -- Initialize the HTML body with the header and introductory text
        SET @html = '
        <p>
        Hi ITOps 1C DBA Team,
        <br>This is an automated Critical Alert indicating that one or more AI Assistant DB server(s) have breached the 85% utilization threshold for key performance metrics. Connect to the affected server(s) immediately to diagnose the root cause. Focus on identifying long-running queries, blocking sessions, or unusual application activity that corresponds with the high utilization.<br>
        <br>
        </p>
        <style>
            table, th, td {
                border: 1px solid black;
                border-collapse: collapse;
                font-family: Serif;
                text-align: center;
                padding: 3px;
                font-size: 10pt;
            }
            th { background: #87ceeb; }
            p { font-family: Serif; }
        </style>
        <table id="tablaPrincipal">
        <tr>
            <th>Server Name</th>
            <th>Avg DB CPU Percent</th>
            <th>Avg DB Log Write Percent</th>
            <th>Avg Memory Usage Percent</th>
            <th>Max Worker Percent</th>
            <th>Avg Instance CPU Percent</th>
            <th>Avg Instance Memory Percent</th>
			<th>DataFileSizeGB</th>
			<th>DataUsedGB</th>
			<th>LogFileSizeGB</th>
			<th>LogUsedGB</th>
			<th>DatabaseMaxDataSizeGB</th>
			<th>FreeToMaxGBOfDataFile</th>
			<th>Data File Free %</th>
			<th>% of AllocatedLogUsed</th>
            <th>Captured Time</th>
        </tr>';

        -- Append the data rows to the HTML variable
        SELECT @html = @html +
        '<tr style="color:' + CASE WHEN max_worker_percent > 90 OR avg_cpu_percent > 90 THEN 'red' ELSE 'black' END + ';">
        <td>' + ServerName + '</td>' +
        '<td>' + CAST(avg_cpu_percent AS VARCHAR(10)) + '</td>' +
        '<td>' + CAST(avg_log_write_percent AS VARCHAR(10)) + '</td>' +
        '<td>' + CAST(avg_memory_usage_percent AS VARCHAR(10)) + '</td>' +
        '<td>' + CAST(max_worker_percent AS VARCHAR(10)) + '</td>' +
        '<td>' + CAST(avg_instance_cpu_percent AS VARCHAR(10)) + '</td>' +
        '<td>' + CAST(avg_instance_memory_percent AS VARCHAR(10)) + '</td>' +
		'<td>' + CAST(AllocatedDataGB AS VARCHAR(10)) + '</td>' +
		'<td>' + CAST(UsedDataGB AS VARCHAR(10)) + '</td>' +
		'<td>' + CAST(AllocatedLogGB AS VARCHAR(10)) + '</td>' +
		'<td>' + CAST(UsedLogGB AS VARCHAR(10)) + '</td>' +
		'<td>' + CAST(DatabaseMaxDataSizeGB AS VARCHAR(10)) + '</td>' +
		'<td>' + CAST(FreeToMaxGB AS VARCHAR(10)) + '</td>' +
		'<td>' + CAST(FreeToMaxPct AS VARCHAR(10)) + '</td>' +
		'<td>' + CAST(LogUsedPctOfAllocated as VArchar(10)) + '<td>' +
        '<td>' + CONVERT(VARCHAR, Captured_time, 120) + '</td>' +
        '</tr>'
        FROM #temp1CAssistant;
        
        -- Close the HTML table tag
        SET @html = @html + '</table>';

		select * from #temp1CAssistant with(nolock)
		Select @html 
        -- Execute the email command FROM WITHIN the IF block
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ITOps1CDBA',
			@recipients ='CRSDBASUPPORT@cognizant.com;EDMDBA@cognizant.com',    
            @copy_recipients = 'PydaVenkata.SrihimaVishnuSeshasai@cognizant.com',
            @body = @html,
            @body_format = 'HTML',
            @subject = 'Critical Alert: 1C Assistant Database utilization exceeded 85% (or) Free Space less than 30%';

    END -- End of the IF EXISTS block

    -- Drop the temp table outside the IF block to ensure it's always cleaned up
    DROP TABLE #temp1CAssistant;

END
GO

