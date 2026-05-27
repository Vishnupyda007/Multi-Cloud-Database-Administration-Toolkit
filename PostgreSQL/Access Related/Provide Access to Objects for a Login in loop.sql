DO $$
DECLARE
    table_name TEXT;
BEGIN
    FOR table_name IN (SELECT "tablename" FROM pg_tables WHERE "schemaname" = 'public')
    LOOP
        EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE "public".%I TO "csagenticaiapp-smp-4652-np-sa@cb0104074a-citnonprod-gc.iam"', table_name);
    END LOOP;
END$$;



