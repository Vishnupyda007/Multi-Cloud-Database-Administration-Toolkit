-- Per-database overrides (no restart needed):
ALTER DATABASE "Repln_Sub2_PoC" SET synchronous_commit = 'off';
ALTER DATABASE "Repln_Sub2_PoC" SET work_mem = '65536';           -- 64 MB
ALTER DATABASE "Repln_Sub2_PoC" SET maintenance_work_mem = '262144'; -- 256 MB
--ALTER DATABASE "Repln_Sub2_PoC" SET autovacuum_vacuum_scale_factor = 0.05;
--ALTER DATABASE "Repln_Sub2_PoC" SET autovacuum_analyze_scale_factor = 0.02;

select * from pg_settings where category='Replication / Standby Servers'

ALTER DATABASE "Repln_Sub2_PoC" SET wal_receiver_timeout = '300000'; -- 5 minutes

ALTER DATABASE "Repln_Sub2_PoC"
  SET wal_receiver_status_interval = '5';



SELECT name, setting, unit,
FROM pg_settings
WHERE name IN (
  'max_worker_processes',
  'max_replication_slots',
  'max_wal_senders',
  'work_mem',
  'maintenance_work_mem',
  'max_logical_replication_workers',
  'max_sync_workers_per_subscription',
  'wal_compression',
  'shared_buffers',
  'wal_buffers',
  'checkpoint_completion_target',
  'synchronous_commit'
)
ORDER BY name;