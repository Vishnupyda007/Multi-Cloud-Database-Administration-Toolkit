
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_event_trigger WHERE evtname = 'et_on_all_create'
  ) THEN
    CREATE EVENT TRIGGER et_on_all_create
      ON ddl_command_end
      WHEN TAG IN ('CREATE SCHEMA','CREATE TABLE','CREATE VIEW','CREATE MATERIALIZED VIEW')
      EXECUTE FUNCTION _ddl_grants_dispatch();
  END IF;
END
$$;
