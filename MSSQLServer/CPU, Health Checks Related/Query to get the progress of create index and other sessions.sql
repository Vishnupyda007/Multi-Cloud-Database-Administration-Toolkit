-- Replace with your actual session ID
DECLARE @SPID INT = 1710;

;WITH agg AS (
    SELECT 
        SUM(qp.row_count) AS RowsProcessed,
        SUM(qp.estimate_row_count) AS TotalRows,
        MAX(qp.last_active_time) - MIN(qp.first_active_time) AS ElapsedMS,
        MAX(IIF(qp.close_time = 0 AND qp.first_row_time > 0, qp.physical_operator_name, N'<Transition>')) AS CurrentStep
    FROM sys.dm_exec_query_profiles qp
    WHERE qp.session_id = @SPID
),
comp AS (
    SELECT *,
        (TotalRows - RowsProcessed) AS RowsLeft,
        (ElapsedMS / 1000.0) AS ElapsedSeconds
    FROM agg
)
SELECT 
    CurrentStep,
    TotalRows,
    RowsProcessed,
    RowsLeft,
    CONVERT(DECIMAL(5, 2), ((RowsProcessed * 1.0) / TotalRows) * 100) AS PercentComplete,
    ElapsedSeconds,
    ((ElapsedSeconds / RowsProcessed) * RowsLeft) AS EstimatedSecondsLeft,
    DATEADD(SECOND, ((ElapsedSeconds / RowsProcessed) * RowsLeft), GETDATE()) AS EstimatedCompletionTime
FROM comp;
