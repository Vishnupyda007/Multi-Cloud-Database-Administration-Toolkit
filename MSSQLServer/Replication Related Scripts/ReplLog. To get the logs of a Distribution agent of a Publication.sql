Use distribution
go
Select h.agent_id,h.start_time,h.time, h.comments, a.name,a.publication  from msdistribution_history h inner join MSdistribution_agents a on h.agent_id=a.id
Where agent_id= 43
Order by time desc