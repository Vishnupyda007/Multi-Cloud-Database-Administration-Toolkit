-- Table: maintenance.stats_update_run_log

-- DROP TABLE IF EXISTS maintenance.stats_update_run_log;

create schema maintenance;
CREATE TABLE IF NOT EXISTS maintenance.stats_update_run_log
(
    run_id bigint NOT NULL,
    run_ts timestamp with time zone NOT NULL DEFAULT now(),
    dbname text COLLATE pg_catalog."default" NOT NULL,
    target text COLLATE pg_catalog."default" NOT NULL,
    action text COLLATE pg_catalog."default" NOT NULL,
    started_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone NOT NULL,
    success boolean NOT NULL,
    detail text COLLATE pg_catalog."default",
    CONSTRAINT stats_update_run_log_pkey PRIMARY KEY (run_id)
)

TABLESPACE pg_default;





-- 1) Create the sequence (idempotent)
CREATE SEQUENCE IF NOT EXISTS maintenance.stats_update_run_log_run_id_seq
    INCREMENT BY 1
    START WITH 1
    MINVALUE 1
    NO MAXVALUE
    CACHE 1;

-- 2) Make the sequence "owned by" the column so it drops automatically with the column
ALTER SEQUENCE maintenance.stats_update_run_log_run_id_seq
    OWNED BY maintenance.stats_update_run_log.run_id;

-- 3) Set the column default to use the sequence
ALTER TABLE maintenance.stats_update_run_log
    ALTER COLUMN run_id SET DEFAULT nextval('maintenance.stats_update_run_log_run_id_seq');

-- 4) (Important) If the table already has rows, advance the sequence so it won’t collide--not required
SELECT setval(
    'maintenance.stats_update_run_log_run_id_seq',
    COALESCE((SELECT MAX(run_id) FROM maintenance.stats_update_run_log), 0)
);
s


CREATE INDEX IF NOT EXISTS ix_stats_update_run_log_started_at
    ON maintenance.stats_update_run_log (started_at DESC);