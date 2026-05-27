DO $pl$
BEGIN
    IF EXTRACT(ISODOW FROM (now() AT TIME ZONE 'Asia/Kolkata')) = 5 THEN
        RAISE NOTICE 'Skipping Friday run at % (Asia/Kolkata)', now() AT TIME ZONE 'Asia/Kolkata';
        RETURN;
    END IF;

    CALL maintenance.usp_update_stats_all_user_dbs_proc(
      '10.75.151.3', 5432, 'postgres', 'DBMaintenanceUser', 'DBmaintenance@26',
      NULL, ARRAY['postgres','template0','template1','cloudsqladmin'],
      NULL, NULL,
      true,
      true,
      0
    );
END
$pl$;