
REVOKE ALL ON DATABASE og_db FROM test_role;
REVOKE ALL ON DATABASE og_db FROM test_role;

-- An admin with permission to manage 'test_role' must run this
GRANT test_role TO dbreader_granter;

create role "test-1" with login password 'Test-1234'

drop owned by "test-1";
drop role "test-1";

select * from public.actor

grant connect on database og_db to "test-1";

grant select on table public.actor to "test-1";
grant usage on schema public to "test-1"