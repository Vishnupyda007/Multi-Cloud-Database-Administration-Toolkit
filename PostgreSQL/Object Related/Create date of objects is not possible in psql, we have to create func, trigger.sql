Create date” of objects: what’s possible?
The reality

PostgreSQL does not store object creation timestamps in the catalogs for most object types. There is no built‑in, retroactive “created_on” column to query.
To obtain creation times going forward, you must log DDL (e.g., with an event trigger) into your own audit table at creation time. (This is the standard approach recommended in the ecosystem.)

A practical, forward‑looking solution (event trigger–based DDL audit)
a) Create an audit table

CREATE SCHEMA IF NOT EXISTS ddl_audit;

CREATE TABLE IF NOT EXISTS ddl_audit.events
(
  event_time     timestamptz NOT NULL DEFAULT now(),
  username       text        NOT NULL DEFAULT session_user,
  command_tag    text        NOT NULL,                    -- e.g., CREATE TABLE
  object_type    text        NOT NULL,                    -- e.g., table, function
  schema_name    text,
  object_name    text,
  ddl_sql        text        NOT NULL                     -- the full DDL
);




b) Create an event trigger function:

CREATE OR REPLACE FUNCTION ddl_audit.log_ddl()
RETURNS event_trigger
LANGUAGE plpgsql
AS $$
DECLARE
  rec record;
BEGIN
  -- Loop over all DDL commands in this event
  FOR rec IN
    SELECT
      c.command_tag,
      (c.object_type)::text     AS object_type,
      (c.schema_name)::text     AS schema_name,
      (c.object_name)::text     AS object_name,
      c.command                 AS ddl_sql
    FROM pg_event_trigger_ddl_commands() AS c
  LOOP
    INSERT INTO ddl_audit.events(command_tag, object_type, schema_name, object_name, ddl_sql)
    VALUES (rec.command_tag, rec.object_type, rec.schema_name, rec.object_name, rec.ddl_sql);
  END LOOP;
END;
$$;




c) Hook it to ddl_command_end:

DROP EVENT TRIGGER IF EXISTS trg_ddl_audit;
CREATE EVENT TRIGGER trg_ddl_audit
  ON ddl_command_end
  EXECUTE PROCEDURE ddl_audit.log_ddl();




How to use it

From now on, whenever someone runs CREATE TABLE, CREATE VIEW, CREATE FUNCTION, etc., you’ll have a timestamped row in ddl_audit.events.
To see “creation date” of an object created after this trigger was installed:

SELECT *
FROM ddl_audit.events
WHERE command_tag LIKE 'CREATE%'
  AND schema_name = 'public'
  AND object_name = 'your_object_name'
ORDER BY event_time
LIMIT 1;


---------------------------

If you need “best effort” creation time for existing objects without prior auditing, the catalogs don’t have it. Some teams approximate using extension install times (for extension‑owned objects) or external logs (DDL history in CI/CD), but there’s no authoritative timestamp in PostgreSQL’s system catalogs for general objects.