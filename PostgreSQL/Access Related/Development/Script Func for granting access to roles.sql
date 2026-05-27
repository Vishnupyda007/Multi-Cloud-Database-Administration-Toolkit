
CREATE OR REPLACE FUNCTION _ddl_grants_dispatch()
RETURNS EVENT_TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  ev RECORD;
  sname TEXT;
  owner_regrole TEXT;
BEGIN
  FOR ev IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP

    -- ---- CREATE SCHEMA ----
    IF ev.command_tag = 'CREATE SCHEMA' AND ev.schema_name IS NOT NULL THEN
      sname := ev.schema_name;

      -- 1) USAGE on the new schema
      EXECUTE format('GRANT USAGE ON SCHEMA %I TO db_datareader, db_datawriter;', sname);

      -- 2) Immediate coverage for inline relations (tables + views)
      EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO db_datareader, db_datawriter;', sname);
      EXECUTE format('GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO db_datawriter;', sname);

      -- Inline materialized views (not covered by ALL TABLES)
      FOR ev IN
        SELECT matviewname FROM pg_matviews WHERE schemaname = sname
      LOOP
        EXECUTE format('GRANT SELECT ON %I.%I TO db_datareader, db_datawriter;', sname, ev.matviewname);
      END LOOP;

      -- 3) Default privileges for future tables & views by the schema owner
      SELECT n.nspowner::regrole::text INTO owner_regrole
      FROM pg_namespace n
      WHERE n.nspname = sname;

      EXECUTE format(
        'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT SELECT ON TABLES TO db_datareader, db_datawriter;',
        owner_regrole, sname);

      EXECUTE format(
        'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I GRANT INSERT, UPDATE, DELETE ON TABLES TO db_datawriter;',
        owner_regrole, sname);

    -- ---- CREATE TABLE / CREATE VIEW ----
    ELSIF ev.command_tag IN ('CREATE TABLE','CREATE VIEW')
          AND ev.schema_name IS NOT NULL AND ev.object_identity IS NOT NULL THEN

      -- Views and tables share SELECT; tables get writer DML
      EXECUTE format('GRANT SELECT ON %s TO db_datareader, db_datawriter;', ev.object_identity);
      IF ev.command_tag = 'CREATE TABLE' THEN
        EXECUTE format('GRANT INSERT, UPDATE, DELETE ON %s TO db_datawriter;', ev.object_identity);
      END IF;

    -- ---- CREATE MATERIALIZED VIEW ----
    E    ELSIF ev.command_tag = 'CREATE MATERIALIZED VIEW'
          AND ev.object_identity IS NOT NULL THEN

      EXECUTE format('GRANT SELECT ON %s TO db_datareader, db_datawriter;', ev.object_identity);

    END IF;

  END LOOP;
END;
