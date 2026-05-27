SELECT
    current_database(),
    n.nspname AS schemaname,
    c.relname AS tablename,
    ROUND((c.reltuples / (
        CASE
            WHEN c.relpages = 0 THEN 1
            ELSE c.relpages
        END
    ))::numeric, 2) AS tuples_per_page,
    ROUND(c.reltuples::numeric) AS row_count,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
    pg_size_pretty(pg_indexes_size(c.oid)) AS index_size,

    -- Bloat size calculation with the explicit ::bigint cast
    pg_size_pretty(
        (CASE
            WHEN c.relpages > 0 AND c.reltuples > 0 THEN
                (c.relpages - CEIL(c.reltuples / (
                    (c.relpages * 8192.0 - c.relpages * 24) /
                    (
                        SELECT avg_width
                        FROM pg_stats s
                        WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                        LIMIT 1
                    )
                ))) * 8192
            ELSE 0
        END)::bigint  -- <--- THE FIX IS HERE
    ) AS bloat_size,

    -- Bloat percentage calculation (this one is fine as it deals with percentages)
    ROUND(
        (CASE
            WHEN c.relpages > 0 AND c.reltuples > 0 THEN
                100 * (c.relpages - CEIL(c.reltuples / (
                    (c.relpages * 8192.0 - c.relpages * 24) /
                    (
                        SELECT avg_width
                        FROM pg_stats s
                        WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                        LIMIT 1
                    )
                ))) / c.relpages
            ELSE 0
        END)::numeric, 2
    ) AS bloat_percentage
FROM
    pg_class c
JOIN
    pg_namespace n ON n.oid = c.relnamespace
WHERE
    c.relkind = 'r'
    AND n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
ORDER BY
    -- The ORDER BY clause must also have the cast to sort correctly
    (CASE
        WHEN c.relpages > 0 AND c.reltuples > 0 THEN
            (c.relpages - CEIL(c.reltuples / (
                (c.relpages * 8192.0 - c.relpages * 24) /
                (
                    SELECT avg_width
                    FROM pg_stats s
                    WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                    LIMIT 1
                )
            ))) * 8192
        ELSE 0
    END) DESC;



SELECT datname, 
pg_size_pretty(pg_database_size
 (datname)) AS total_size
 FROM pg_database
 ORDER BY 
pg_database_size(datname) DESC;


cREATE EXTENSION IF NOT EXISTS anon CASCADE;
ALTER DATABASE "TrailPoC_DB" SET anon.transparent_dynamic_masking TO true;
show anon.transparent_dynamic_masking
SELECT anon.init();
SELECT anon.start_dynamic_masking(); 


create role mask_analyst login password 'Masked@2025'

security label for anon on role mask_analyst is 'MASKED'

grant connect on database "TrailPoC_DB" to mask_analyst

grant usage on schema public to mask_analyst

grant  masked_analyst to test;

grant usage on schema public to test;
grant select (rating) on  public.film_details to mask_analyst;

-- This rule tells 'anon' to replace the email with a fake one
SECURITY LABEL FOR anon ON COLUMN public.customer.email
IS 'MASKED WITH FUNCTION anon.fake_Amount()';


SECURITY LABEL FOR anon ON COLUMN public.payment.amount
IS 'MASKED WITH FUNCTION anon.partial(amount, 2, ''XXXX'', 4)';

-- This rule tells 'anon' to replace the salary with a fixed value of 0
SECURITY LABEL FOR anon ON COLUMN public.film_details.rating
IS 'MASKED WITH VALUE ''0'''; -- Note the double single-quotes for a string literal


select * from film_details

grant select  (rating) on

Masked@2025





SELECT
    current_database(),
    n.nspname AS schemaname,
    c.relname AS tablename,
    ROUND((c.reltuples / (
        CASE
            WHEN c.relpages = 0 THEN 1
            ELSE c.relpages
        END
    ))::numeric, 2) AS tuples_per_page,
    ROUND(c.reltuples::numeric) AS row_count,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
    pg_size_pretty(pg_indexes_size(c.oid)) AS index_size,



    -- Bloat size calculation with the explicit ::bigint cast
    pg_size_pretty(
        (CASE
            WHEN c.relpages > 0 AND c.reltuples > 0 THEN
                (c.relpages - CEIL(c.reltuples / (
                    (c.relpages * 8192.0 - c.relpages * 24) /
                    (
                        SELECT avg_width
                        FROM pg_stats s
                        WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                        LIMIT 1
                    )
                ))) * 8192
            ELSE 0
        END)::bigint  -- <--- THE FIX IS HERE
    ) AS bloat_size,



    -- Bloat percentage calculation (this one is fine as it deals with percentages)
    ROUND(
        (CASE
            WHEN c.relpages > 0 AND c.reltuples > 0 THEN
                100 * (c.relpages - CEIL(c.reltuples / (
                    (c.relpages * 8192.0 - c.relpages * 24) /
                    (
                        SELECT avg_width
                        FROM pg_stats s
                        WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                        LIMIT 1
                    )
                ))) / c.relpages
            ELSE 0
        END)::numeric, 2
    ) AS bloat_percentage
FROM
    pg_class c
JOIN
    pg_namespace n ON n.oid = c.relnamespace
WHERE
    c.relkind = 'r'
    AND n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
ORDER BY
    -- The ORDER BY clause must also have the cast to sort correctly
    (CASE
        WHEN c.relpages > 0 AND c.reltuples > 0 THEN
            (c.relpages - CEIL(c.reltuples / (
                (c.relpages * 8192.0 - c.relpages * 24) /
                (
                    SELECT avg_width
                    FROM pg_stats s
                    WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                    LIMIT 1
                )
            ))) * 8192
        ELSE 0
    END) DESC;





SELECT datname, 
pg_size_pretty(pg_database_size
(datname)) AS total_size
FROM pg_database
ORDER BY 
pg_database_size(datname) DESC;





cREATE EXTENSION IF NOT EXISTS anon CASCADE;
ALTER DATABASE "TrailPoC_DB" SET anon.transparent_dynamic_masking TO true;
show anon.transparent_dynamic_masking
SELECT anon.init();
SELECT anon.start_dynamic_masking();





create role mask_analyst login password 'Masked@2025'



security label for anon on role mask_analyst is 'MASKED'



grant connect on database "TrailPoC_DB" to mask_analyst



grant usage on schema public to mask_analyst



grant  masked_analyst to test;



grant usage on schema public to test;
grant select (rating) on  public.film_details to mask_analyst;



-- This rule tells 'anon' to replace the email with a fake one
SECURITY LABEL FOR anon ON COLUMN public.customer.email
IS 'MASKED WITH FUNCTION anon.fake_email()';



SECURITY LABEL FOR anon ON COLUMN public.payment.amount
IS 'MASKED WITH FUNCTION anon.partial(amount, 2, ''XXXX'', 4)';



-- This rule tells 'anon' to replace the salary with a fixed value of 0
SECURITY LABEL FOR anon ON COLUMN public.film_details.rating
IS 'MASKED WITH VALUE ''0'''; -- Note the double single-quotes for a string literal


SECURITY LABEL FOR anon ON COLUMN public.address.postal_code
IS 'MASKED WITH FUNCTION anon.fake_postcode()';


select * from film_details



grant select (postal_code) on public.address to mask_analyst;


grant mask_analyst to "Test_PoC";
grant select on table address to "Test_PoC";


GRANT SELECT ON ALL SEQUENCES IN SCHEMA anon TO "Test_PoC";

grant connect on database og_db to "Test_PoC";
select * from address
 
select * from customer



--public Acc

