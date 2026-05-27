SELECT 
   '--Server Name: ' + @@Servername + CHAR(13) + CHAR(10) +
    '-- Schema Name: ' + TABLE_SCHEMA + CHAR(13) + CHAR(10) +
    '-- View Name: ' + TABLE_NAME + CHAR(13) + CHAR(10) +
    '-- Full View Name: ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + CHAR(13) + CHAR(10) +
    '-- View Definition:' + CHAR(13) + CHAR(10) +
    ISNULL(OBJECT_DEFINITION(OBJECT_ID(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME))), '') + CHAR(13) + CHAR(10) +
    '-- ' + REPLICATE('-', 80) + CHAR(13) + CHAR(10)
AS CommentedView
FROM INFORMATION_SCHEMA.VIEWS;