cREATE EXTENSION IF NOT EXISTS anon CASCADE;
ALTER DATABASE "TrailPoC_DB" SET anon.transparent_dynamic_masking TO true;
show anon.transparent_dynamic_masking
SELECT anon.init();
SELECT anon.start_dynamic_masking(); 


create role mask_analyst2 with login password 'Masked@2025'

security label for anon on role mask_analyst2 is 'MASKED'

grant connect on database "TrailPoC_DB" to mask_analyst2

grant usage on schema public to mask_analyst2

grant  masked_analyst to test;

grant usage on schema public to test;
grant select (rating) on  public.film_details to mask_analyst2;

-- This rule tells 'anon' to replace the email with a fake one
SECURITY LABEL FOR anon ON COLUMN public.customer.email
IS 'MASKED WITH FUNCTION anon.fake_Amount()';


SECURITY LABEL FOR anon ON COLUMN public.payment.amount
IS 'MASKED WITH FUNCTION anon.partial(amount, 2, ''XXXX'', 4)';

-- This rule tells 'anon' to replace the salary with a fixed value of 0
SECURITY LABEL FOR anon ON COLUMN public.film_details.rating
IS 'MASKED WITH VALUE ''0'''; -- Note the double single-quotes for a string literal


select * from film_details


--------



grant  masked_analyst to test;



grant usage on schema public to test;
grant select on table public.film_details to mask_analyst2;



-- This rule tells 'anon' to replace the email with a fake one
SECURITY LABEL FOR anon ON COLUMN public.customer.email
IS 'MASKED WITH FUNCTION anon.fake_email()'; --working


SECURITY LABEL FOR anon ON COLUMN public.film_details.rating
IS 'MASKED WITH function anon.random_hash(rating)'; -- Note the double single-quotes for a string literal


SECURITY LABEL FOR anon ON COLUMN public.address.phone
IS 'MASKED WITH FUNCTION anon.random_phone(''xxx'')'; --working

--anon.random_phone

SECURITY LABEL FOR anon ON COLUMN public.payment.amount
IS 'MASKED WITH FUNCTION anon.partial(amount, 2, ''XXXX'', 4)';



-- This rule tells 'anon' to replace the salary with a fixed value of 0
SECURITY LABEL FOR anon ON COLUMN public.film_details.rating
IS 'MASKED WITH VALUE ''seed'''; -- Note the double single-quotes for a string literal


SECURITY LABEL FOR anon ON COLUMN public.city.city
IS 'MASKED WITH FUNCTION anon.fake_city()'; 



SECURITY LABEL FOR anon ON COLUMN public.staff.email
IS 'MASKED WITH FUNCTION anon.fake_email()'; 


SECURITY LABEL FOR anon ON COLUMN public.address.postal_code
IS 'MASKED WITH FUNCTION anon.fake_postcode()'; --working


select * from film_details



grant select on table film_details to mask_analyst2;


grant select on table film_details to mask_analyst2;


grant select on table city to mask_analyst2;

GRANT SELECT ON ALL SEQUENCES IN SCHEMA anon TO mask_analyst2;

grant connect on database og_db to "Test_PoC";
select * from customer
 
select * from film_details


select * from city


