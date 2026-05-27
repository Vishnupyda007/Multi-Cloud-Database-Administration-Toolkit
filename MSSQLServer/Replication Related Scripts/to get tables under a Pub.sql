SELECT msp.publication AS PublicationName,
       msa.publisher_db AS DatabaseName,
       msa.article AS ArticleName,
       msa.source_owner AS SchemaName,
       msa.source_object AS TableName
FROM distribution.dbo.MSarticles msa
JOIN distribution.dbo.MSpublications msp ON msa.publication_id = msp.publication_id
where msp.publication= 'Pub_SITR1'