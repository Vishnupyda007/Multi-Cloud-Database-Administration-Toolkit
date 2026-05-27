-- Define the rows you want to delete inside a CTE
WITH BatchToDelete AS (
    SELECT TOP (5000) *
    FROM tablename
    WHERE source_date_time > xxx AND source_date_time < yyy
)
-- Delete from the CTE
DELETE FROM BatchToDelete;