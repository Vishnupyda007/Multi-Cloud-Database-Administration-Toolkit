SELECT name, setting, source
FROM pg_settings
WHERE name LIKE 'pgaudit.%'
ORDER BY name;


SHOW pgaudit.log;
SHOW pgaudit.log_statement_once;
SHOW pgaudit.log_parameter;
SHOW pgaudit.log_catalog;


SELECT extname, extversion
FROM pg_extension
WHERE extname = 'pgaudit';