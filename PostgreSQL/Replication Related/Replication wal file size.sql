SELECT slot_name, active,
  pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn))
FROM pg_replication_slots WHERE active = false;

-- Drop if confirmed inactive and no longer required:
SELECT pg_drop_replication_slot(
  'pgl__epln__ub3__o___ogical_250989f_sub_to_pub4_2f7056e3');
