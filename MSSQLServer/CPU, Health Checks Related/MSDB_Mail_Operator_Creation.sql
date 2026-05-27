USE [msdb]
GO

/****** Object:  Operator [Knowhub_Alerts]    Script Date: 5/2/2025 4:37:39 PM ******/
EXEC msdb.dbo.sp_add_operator @name=N'Knowhub_Alerts', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@email_address=N'KnowhubDevelopment@cognizant.com', 
		@category_name=N'[Uncategorized]'
GO


