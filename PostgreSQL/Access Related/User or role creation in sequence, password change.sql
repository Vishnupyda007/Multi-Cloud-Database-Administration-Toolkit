
CREATE ROLE test_user WITH LOGIN PASSWORD 'StrongPass@123';



-- Grant CONNECT privilege on a specific database
GRANT CONNECT ON DATABASE ent_data_store TO test_user;


-- Grant usage on schema (optional)
GRANT USAGE ON SCHEMA public TO test_user;


ALTER USER "OneC_4652" WITH PASSWORD 'your_new_password_here';
