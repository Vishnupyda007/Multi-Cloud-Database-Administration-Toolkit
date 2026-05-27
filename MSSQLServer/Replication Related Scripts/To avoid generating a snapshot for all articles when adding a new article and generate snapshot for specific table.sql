--Step-1:

EXEC sp_changepublication
@publication = N'Practice_Replication',
@property = N'allow_anonymous',
@value = 'False'
GO


--Step-1:

EXEC sp_changepublication
@publication = N'Practice_Replication',
@property = N'immediate_sync',
@value = 'False'
GO


--Step-3:

EXEC sp_refreshsubscriptions @publication = N'Practice_Replication'


--after executing the above, Snapshot always available will become false in subscription options in publisher properties.
--adding articles to and dropping articles from an existing publication, you must create a new snapshot for the publication. This is the recommended practice. To avoid generating a snapshot for all articles when adding a new article, publication property immediate_sync must be set to 0 and then call sp_addarticle, followed by sp_addsubscription. If it is pull subscription, you must call sp_refreshsubscriptions. Then generate a snapshot and this process will yield to generate snapshot only for the newly added articles.

--As invalidating the snapshot is not a recommended option, but still, this is more important when we deal with large replication database and we don’t want to reinitialize snapshot agent because of the database size and other considerations in mind. In order to do this; we need to set the publisher properties allow_anonymous and Immediate_sync to False







