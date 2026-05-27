-- Now run the same REVOKE commands 
REVOKE CONNECT ON DATABASE template1 FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
Important: You might need to temporarily allow connections to template1 to do this (ALTER DATABASE template1 WITH ALLOW_CONNECTIONS = true;), then disable them again afterward. In Cloud SQL, this is generally allowed.



---Google team shared---

1. Create the user
 CREATE USER app_user WITH PASSWORD 'secure_password';
 2. Revoke default PUBLIC privileges on the target DB (optional but good practice)
 This prevents all users from connecting unless explicitly granted
 REVOKE CONNECT ON DATABASE target_db FROM PUBLIC;
 3. Grant connection ONLY to the target DB
 GRANT CONNECT ON DATABASE target_db TO app_user;
 4. Restrict access within the database
 GRANT USAGE ON SCHEMA public TO app_user;
 GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_user




------------Pg_stat_statements-----------
pg_stat_statements.max = 10000

pg_stat_statements.track = top

pg_stat_statements.track_utility = on

pg_stat_statements.save = on




--------------------tcp_keepalives

tcp_keepalives_idle = 300–600  (5–10 minutes)

tcp_keepalives_interval = 30–60

tcp_keepalives_count = 5–10