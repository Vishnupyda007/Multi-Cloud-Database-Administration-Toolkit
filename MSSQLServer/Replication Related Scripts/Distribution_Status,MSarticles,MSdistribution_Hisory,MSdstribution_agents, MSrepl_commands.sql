----To know status of Distribution of tables and helps to get which table causing issue
USE [distribution]
SELECT ds.*, a.article
FROM MSdistribution_status ds
JOIN MSarticles a ON ds.article_id = a.article_id;



select * from MSarticles
select * from [dbo].[MSdistribution_agents]
select * from [dbo].[MSdistribution_history]
select * from [dbo].[MSrepl_commands]

select * from msdb.dbo.MSdistpublishers