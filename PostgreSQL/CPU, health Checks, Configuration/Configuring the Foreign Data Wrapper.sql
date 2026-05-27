-- 1. Connect to your "source" or "local" database where you want to run queries.

-- 2. Enable the extension (if not already done).

CREATE EXTENSION IF NOT EXISTS postgres_fdw;


CREATE SERVER test_db_Server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host '10.75.154.5', dbname 'ent_data_store', port '5432');

	
create USER MAPPING FOR CURRENT_USER   -- we have to first map current user to the foreign server.
    SERVER test_db_server
   OPTIONS (user 'test', password 'Test@2025');

	


--DROP USER MAPPING FOR test SERVER test_db_server;

CREATE USER MAPPING FOR test --we have to use user's login
SERVER test_db_server
OPTIONS (user 'test', password 'Test@2025');


ALTER USER MAPPING FOR test SERVER test_db_server
OPTIONS (set user 'test',set password 'Test@2025');

CREATE FOREIGN TABLE test_inventory_products (
    product_id INT,
    product_name VARCHAR(255),
    stock_quantity INT
)
SERVER inventory_server
OPTIONS (schema_name 'public', table_name 'products');

----------------------------------------

CREATE SCHEMA ent_data_store

IMPORT FOREIGN SCHEMA public
  FROM SERVER test_db_server
  INTO ent_data_store;  --local_schema


--------------------to troubleshoot----------------

SELECT * FROM pg_foreign_server;
SELECT * FROM pg_user_mappings;


------------------------------------

select * from ent_data_store.vw_employee




