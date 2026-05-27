SELECT 
    @@SERVERNAME as SourceServer,
    pub.name AS [Publication],
    art.name AS [Article],
	sch.name as [SourceSchema],
    serv.name AS [Subscriber],
    sub.dest_db AS [DestinationDatabase],
    art.dest_owner AS [DestinationSchema]
FROM dbo.syssubscriptions sub with(nolock)
INNER JOIN sys.servers serv with(nolock)
    ON serv.server_id = sub.srvid
INNER JOIN dbo.sysarticles art with(nolock)
    ON art.artid = sub.artid
INNER JOIN dbo.syspublications pub with(nolock)
    ON pub.pubid = art.pubid
inner join sys.objects obj with(nolock)
   ON obj.object_id=art.objid
INNER JOIN sys.schemas sch with(nolock)
    ON sch.schema_id = obj.schema_id
order by pub.name asc

