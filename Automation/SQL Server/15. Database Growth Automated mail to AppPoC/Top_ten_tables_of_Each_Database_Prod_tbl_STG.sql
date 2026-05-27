create TABLE Top_ten_tables_of_Each_Database_Prod_tbl_STG (
       ServerName NVARCHAR(128),
    DatabaseName NVARCHAR(128),
    TableName NVARCHAR(256),
    TotalRows BIGINT,
    TableSizeGB DECIMAL(18,2),
    CaptureDate DATETIME
);