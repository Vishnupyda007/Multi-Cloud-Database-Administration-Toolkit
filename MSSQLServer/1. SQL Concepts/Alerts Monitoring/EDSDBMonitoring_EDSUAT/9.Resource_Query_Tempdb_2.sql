exec sp_whoisactive @sort_order = '[tempdb_current] DESC' --physical_io, reads, physical_reads, writes, tempdb_current,
,@get_transaction_info = 1
,@show_sleeping_spids=0
,@output_column_list = '[dd hh:mm:ss.mss][start_time][session_id][sql_text][status][wait_info][IO][temp%][reads][writes][login_name][host_name][database_name][program_name]'
go



