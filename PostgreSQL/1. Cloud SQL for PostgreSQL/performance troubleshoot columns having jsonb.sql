explain (analyse)
SELECT * FROM eventdetails ed where eventid=948


select pg_size_pretty(pg_total_Relation_size('eventdetails'))

select avg(pg_column_size(t)) from eventdetails t

select eventid,id,templateid from eventdetails  

select eventgeneralfieldvalues, eventfieldvalues,eventpreparationvalues,actionitemvalues,agendaitemvalues from eventdetails


select eventfieldvalues from eventdetails


select * from event_type
