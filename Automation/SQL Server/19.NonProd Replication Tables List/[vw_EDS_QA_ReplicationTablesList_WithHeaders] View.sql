USE [1CDBAMonitoring]
GO

/****** Object:  View [dbo].[vw_EDS_ProdReplicationTablesList_WithHeaders]    Script Date: 3/3/2026 4:36:22 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[vw_EDS_QA_ReplicationTablesList_WithHeaders]
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
	FROM dbo.QAUATReplicationTablesList where SourceServer='ctsinazqaedssqlmi.inso13dfbbbfa2150.database.windows.net';
GO


