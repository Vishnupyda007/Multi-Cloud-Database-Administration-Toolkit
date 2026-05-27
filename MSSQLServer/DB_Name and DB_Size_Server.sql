SELECT DB_NAME( dbid ) AS DatabaseName,CAST( ( SUM( size ) * 8 ) / ( 1024.0 * 1024.0 ) AS decimal( 10, 2 ) ) AS DBSizeGB
FROM sys.sysaltfiles  where dbid>4 AND dbid <> 32767  GROUP BY DB_NAME( dbid ) order by DBSizeGB desc

