DO $$ DECLARE r RECORD;BEGIN FOR r IN SELECT datname
        FROM pg_database
        WHERE datistemplate = false AND datname NOT IN ('postgres','cloudsqladmin')
    LOOP
        RAISE NOTICE 'Applying reader/writer grants in %', r.datname;

        EXECUTE format('GRANT USAGE ON SCHEMA public TO db_datareader;');
        EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA public TO db_datareader;');
        EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO db_datareader;');

        EXECUTE format('GRANT USAGE ON SCHEMA public TO db_datawriter;');
        EXECUTE format('GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO db_datawriter;');
        EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT INSERT, UPDATE, DELETE ON TABLES TO db_datawriter;');
    END LOOP;END;$$;