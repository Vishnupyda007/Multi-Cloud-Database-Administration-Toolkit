SELECT 

    DB_NAME(s.database_id)              AS DatabaseName,

    s.session_id                        AS SessionID,

    s.login_name                        AS LoginName,

    s.program_name                      AS ApplicationName,

    r.status                            AS Status,

    r.start_time                        AS QueryStartTime,

    DATEDIFF(SECOND, r.start_time, 

        GETDATE())                      AS ElapsedSecs,

    -- TempDB Used by Task (most accurate for running query)

    ROUND((tsu.user_objects_alloc_page_count

         - tsu.user_objects_dealloc_page_count)

         * 8 / 1024.0, 2)              AS Task_UserObjects_MB,

    ROUND((tsu.internal_objects_alloc_page_count

         - tsu.internal_objects_dealloc_page_count)

         * 8 / 1024.0, 2)              AS Task_InternalObjects_MB,

    ROUND(((tsu.user_objects_alloc_page_count

          - tsu.user_objects_dealloc_page_count)

         + (tsu.internal_objects_alloc_page_count

          - tsu.internal_objects_dealloc_page_count))

         * 8 / 1024.0, 2)              AS Task_Total_TempDB_MB,

    -- TempDB Used by Session (accumulated)

    ROUND(((ssu.user_objects_alloc_page_count

          - ssu.user_objects_dealloc_page_count)

         + (ssu.internal_objects_alloc_page_count

          - ssu.internal_objects_dealloc_page_count))

         * 8 / 1024.0, 2)              AS Session_Total_TempDB_MB,

    -- Exact Running Query Text

    SUBSTRING(qt.text,

        (r.statement_start_offset / 2) + 1,

        ((CASE r.statement_end_offset

            WHEN -1 THEN DATALENGTH(qt.text)

            ELSE r.statement_end_offset

          END - r.statement_start_offset) / 2) + 1

    )                                   AS RunningQueryText,

    -- Full Batch Text

    qt.text                             AS FullBatchText

FROM sys.dm_exec_requests r

INNER JOIN sys.dm_exec_sessions s

    ON r.session_id = s.session_id

INNER JOIN sys.dm_db_session_space_usage ssu

    ON s.session_id = ssu.session_id

INNER JOIN sys.dm_db_task_space_usage tsu

    ON r.session_id = tsu.session_id

    AND r.request_id = tsu.request_id

CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) qt

WHERE s.is_user_process = 1

AND ((tsu.user_objects_alloc_page_count

   - tsu.user_objects_dealloc_page_count)

  + (tsu.internal_objects_alloc_page_count

   - tsu.internal_objects_dealloc_page_count)) >= 0

ORDER BY Task_Total_TempDB_MB DESC;

 