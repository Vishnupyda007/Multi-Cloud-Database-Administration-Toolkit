SELECT c.relname as View_name,
    'CREATE OR REPLACE VIEW '
    || quote_ident(n.nspname)
    || '.'
    || lower(quote_ident(c.relname))
    || E' AS\n'
    || pg_get_viewdef(c.oid, true)
    || E';\n'
    AS view_ddl
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE c.relkind = 'v'
  AND lower(c.relname) IN
  (
      'vw_centralrepository_sfdc_account',
      'vw_centralrepository_sfdc_account_team',
      'vw_centralrepository_sfdc_opportunity',
      'vw_centralrepository_sfdc_product',
      'rhms_tbl_eds_roledatails_view',
      'vw_centralrepository_rhms_rolemaster',
      'vw_centralrepository_sfdc_opportunity_service_line_item',
      'mainspring_eds_archetypeprojectdemographics_view'
  )
ORDER BY lower(c.relname);