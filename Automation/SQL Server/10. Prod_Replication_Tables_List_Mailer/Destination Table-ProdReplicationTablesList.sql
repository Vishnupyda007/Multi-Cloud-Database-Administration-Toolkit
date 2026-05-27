CREATE TABLE dbo.ProdReplicationTablesList
(
    SourceServer Nvarchar(300),
    Publication NVARCHAR(300),
    Article NVARCHAR(300),
    SourceSchema NVARCHAR(300),
    Subscriber NVARCHAR(300),
    DestinationDatabase NVARCHAR(300),
    DestinationSchema NVARCHAR(300),
    CaptureDate DATETIME DEFAULT GETDATE()
);


