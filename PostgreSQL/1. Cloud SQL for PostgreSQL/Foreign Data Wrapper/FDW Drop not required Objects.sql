DO $$
DECLARE r record;
BEGIN
    FOR r IN
        SELECT foreign_table_name
        FROM information_schema.foreign_tables
        WHERE foreign_table_schema = 'ent_data_store_fdw'
          AND foreign_table_name NOT LIKE 'vw\_%' ESCAPE '\'
          AND foreign_table_name NOT LIKE '%\_view' ESCAPE '\'
    LOOP
        EXECUTE format(
            'DROP FOREIGN TABLE ent_data_store_fdw.%I',
            r.foreign_table_name
        );
    END LOOP;
END $$;
