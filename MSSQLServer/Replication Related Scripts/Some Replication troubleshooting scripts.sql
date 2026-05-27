-----------replication inactive subscriber resolve

STEP 1: select * From distribution..MSsubscriptions

P.S:  Note down publisher_id, publisher db name, publication_id , subscriber_id and subscriber_db name of whose status is 0

Status of the subscription: 0 = Inactive; 1 = Subscribed; 2 = Active

subscription_type 0=PUSH, 1=PULL
 
STEP 2:  Update Status to 2

if exists (select 1 from distribution..MSsubscriptions where status = 0)

begin

UPDATE distribution..MSsubscriptions

SET STATUS = 2

WHERE publisher_id = '--publisher_id -- will be integer --'

    AND publisher_db = '--publisher db name ---'

    AND publication_id = '--publication_id -- will be integer --'

    AND subscriber_id = '--subscriber_id -- will be integer ---'

    AND subscriber_db = '-- subscriber_db ---'

end

else

begin

print 'The subscription is not INACTIVE.. you are good for now .... !!'

end
 
STEP 3: Right click on subscriber and choose view synchronizing status

 

-------------------------------------------------------


select top 1000 * from distribution.Msdistribution_history  order by time desc

select * from distribution.Msdistribution_agents
 
select * from distribution.MSlogreader_history where agent_id=11 order by time desc

select * from distribution.MSlogreader_agents
 

----------------------------------------------

use distribution

go

exec sp_browsereplcmds '0x00DA1F8B0002E6E0000100000000', '0x00DA1F8B0002E6E0000100000000'

go

 

------------------------------------



;With HugeCommands as (

SELECT article_id,count(1) [Counts]

  FROM [distribution].[dbo].[MSrepl_commands] with (nolock) 

  group by article_id --order by COunt(1) desc

  )
 
  select A.publication_id,P.publication,A.article_id,A.source_object,H.Counts from

  [distribution].[dbo].[MSarticles] a  with (nolock) 

Left Join

   HugeCommands H on A.article_id=H.article_id

   Left Join

   [distribution].[dbo].MSpublications P With(nolock)

   on A.publication_id=P.publication_id

   order by H.Counts desc
 
SELECT * 

   FROM distribution.dbo.MSarticles

   WHERE article_id in (

      SELECT article_id 

         FROM MSrepl_commands

         WHERE xact_seqno = 0x xact_seqno)
 
-----------------------------

a) SELECT article_id,count(1)

  FROM [distribution].[dbo].[MSrepl_commands] with (nolock) group by article_id order by count(1) desc
 
b) SELECT publication_id,article_id,source_object from
 
  [distribution].[dbo].[MSarticles] a  where a.article_id in (88,793,792,87) ---article id get from first query
 
------------

select  * from MSrepl_transactions (NOLOCK) t

join MSrepl_commands (NOLOCK) c

on t.publisher_database_id=c.publisher_database_id

and t.xact_seqno= c.xact_seqno

join MSarticles a

on a.article_id=c.article_id

join MSpublications pub

on a.publication_id = pub.publication_id

where t.xact_seqno = 0x00C0198E000D5E1800B9000000000000

--and pub.publication =< publication name>

order by t.xact_seqno asc

--------------------------------------

select * from MSlogreader_history order by time desc --if stats state=1 then read and write thread is fine, if stats state=2 then there is lag in read or write thread(from publisher to distributor)

select * from MSdistribution_history  order by time desc--if stats state=1 then read and write thread is fine, if stats state=2 then there is lag in read or write thread(from distributor to subscriber)

 