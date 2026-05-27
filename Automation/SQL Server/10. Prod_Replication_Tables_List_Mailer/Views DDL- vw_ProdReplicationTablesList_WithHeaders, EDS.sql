
ALTER VIEW dbo.vw_ProdReplicationTablesList_WithHeaders
AS
SELECT 
    'SourceServer' AS PublisherServer,
    'Publication' AS Publication,
    'Article' AS ArticleName,
    'SourceSchema' AS SourceSchema,
    'Subscriber' AS Subscriber,
    'DestinationDatabase' AS DestinationDatabase,
    'DestinationSchema' AS DestinationSchema
UNION ALL
SELECT 
    SourceServer as PublisherServer,
    Publication,
    Article as ArticleName,
    SourceSchema,
    Subscriber,
    DestinationDatabase,
    DestinationSchema
	FROM dbo.ProdReplicationTablesList where SourceServer='ctsazsimicrsmas.inso1a101c37461fa.database.windows.net';
GO


ALTER VIEW dbo.vw_EDS_ProdReplicationTablesList_WithHeaders
AS
SELECT 
    'SourceServer' AS PublisherServer,
    'Publication' AS Publication,
    'Article' AS ArticleName,
    'SourceSchema' AS SourceSchema,
    'Subscriber' AS Subscriber,
    'DestinationDatabase' AS DestinationDatabase,
    'DestinationSchema' AS DestinationSchema
UNION ALL
SELECT 
    SourceServer as PublisherServer,
    Publication,
    Article as ArticleName,
    SourceSchema,
    Subscriber,
    DestinationDatabase,
    DestinationSchema
	FROM dbo.ProdReplicationTablesList where SourceServer='ctsinazprdedssqlmi.inso1a101c37461fa.database.windows.net';
GO

