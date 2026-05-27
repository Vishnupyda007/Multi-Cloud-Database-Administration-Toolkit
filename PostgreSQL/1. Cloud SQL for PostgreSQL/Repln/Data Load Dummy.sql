BEGIN;

-- Parameters for generation
WITH params AS (
    SELECT
        30000::int AS n,                -- number of rows
        0::int     AS id_offset,        -- bump this by +10000 for a new batch
        50000000000::bigint AS id_base  -- keeps IDs far away from your existing ones
),
gs AS (
    -- Cross join params so we can reference its columns directly
    SELECT
        generate_series(1, n) AS g,
        id_offset,
        id_base
    FROM params
)
INSERT INTO public."CentralRepository_AssociateAddress_MIG" (
    "ASSOCIATE_ID",
    "EFFDATE",
    "ADDRESS1",
    "ADDRESS2",
    "ADDRESS3",
    "ADDRESS4",
    "PINCODE",
    "CITY",
    "STATE",
    "COUNTRY",
    "COUNTY",
    "ADDRESSTYPE",
    "ADDR_FIELD1",
    "ADDR_FIELD2",
    "ADDR_FIELD3",
    "HOUSE_TYPE",
    "NUM1",
    "NUM2",
    "LASTUPDATEDDATETIME",
    "PORTINGSTATUS",
    "TRACKINGID",
    "PERSONALPHONENO",
    "RECEIVEDDATETIME",
    "STATE_ADDRESS"
)
SELECT
    -- New 11-digit IDs starting from 50000000001
    (id_base + g + id_offset)::text AS "ASSOCIATE_ID",

    -- EFFDATE in the last ~10 years
    now() - (((random() * 3650)::int)::text || ' days')::interval AS "EFFDATE",

    -- Address lines
    ('Flat ' || (100 + (g % 900)))::varchar(75) AS "ADDRESS1",
    ('Street ' || (g % 500))::varchar(75) AS "ADDRESS2",
    CASE WHEN (g % 3) = 0 THEN ('Landmark ' || (g % 50))::varchar(75) ELSE NULL END AS "ADDRESS3",
    CASE WHEN (g % 5) = 0 THEN ('Area ' || (g % 80))::varchar(75) ELSE NULL END AS "ADDRESS4",

    -- PIN as 6-digit string
    lpad(((100000 + (g % 900000)))::text, 6, '0')::varchar(32) AS "PINCODE",

    -- City / State / Country
    (ARRAY['Chennai','Hyderabad','Bengaluru','Pune','Mumbai','Delhi','Kolkata','Ahmedabad'])[(g % 8) + 1]::varchar(50) AS "CITY",
    (ARRAY['Tamil Nadu','Telangana','Karnataka','Maharashtra','Maharashtra','Delhi','West Bengal','Gujarat'])[(g % 8) + 1]::varchar(50) AS "STATE",
    'India'::varchar(50) AS "COUNTRY",
    ('County-' || (g % 30))::varchar(30) AS "COUNTY",

    -- AddressType cycles to distribute composite PK
    (ARRAY['H','W','O','P'])[(g % 4) + 1]::varchar(4) AS "ADDRESSTYPE",

    -- Small fields
    upper(substr(md5((g || 'A1')::text), 1, 2))::varchar(2) AS "ADDR_FIELD1",
    upper(substr(md5((g || 'A2')::text), 1, 4))::varchar(4) AS "ADDR_FIELD2",
    upper(substr(md5((g || 'A3')::text), 1, 4))::varchar(4) AS "ADDR_FIELD3",

    (ARRAY['AP','IN','DU','VI'])[(g % 4) + 1]::varchar(2) AS "HOUSE_TYPE",
    lpad(((g % 999999) + 1)::text, 6, '0')::varchar(6) AS "NUM1",
    lpad((((g * 7) % 999999) + 1)::text, 6, '0')::varchar(6) AS "NUM2",

    now() - (((random() * 180)::int)::text || ' days')::interval AS "LASTUPDATEDDATETIME",

    (ARRAY['N','Y','P'])[(g % 3) + 1]::char(1) AS "PORTINGSTATUS",

    -- ✅ FIXED: cast parts to text before concatenation for md5 seed
    ('TRK-' || g::text || '-' || upper(substr(md5(g::text || now()::text), 1, 24)))::varchar(200) AS "TRACKINGID",

    -- Phone numbers (string)
    ('+91' || lpad(((6000000000 + (g % 3999999999))::bigint)::text, 10, '0'))::varchar(44) AS "PERSONALPHONENO",

    now() - (((random() * 60)::int)::text || ' days')::interval AS "RECEIVEDDATETIME",

    (ARRAY['Tamil Nadu','Telangana','Karnataka','Maharashtra','Maharashtra','Delhi','West Bengal','Gujarat'])[(g % 8) + 1]::varchar(50) AS "STATE_ADDRESS"
FROM gs
-- Remove this ON CONFLICT line if your Postgres is 9.4
ON CONFLICT ("ASSOCIATE_ID","ADDRESSTYPE") DO NOTHING;

COMMIT;

-- Verify approximate insert count (range check)
SELECT COUNT(*) AS new_rows
FROM public."CentralRepository_AssociateAddress_MIG"
WHERE "ASSOCIATE_ID" ~ '^[0-9]+$'
  AND "ASSOCIATE_ID"::bigint BETWEEN 50000000001 AND 50000000001 + 20000;


 --update 10%

 UPDATE public."CentralRepository_AssociateAddress_MIG"
SET "ADDRESS1" = "ADDRESS1" || ' (upd)',
    "LASTUPDATEDDATETIME" = now()
WHERE "ASSOCIATE_ID"::bigint >= 50000000001
  AND "ASSOCIATE_ID"::bigint < 50000000001 + 20000
  AND random() < 0.10;


---delete 5%
DELETE FROM public."CentralRepository_AssociateAddress_MIG"
WHERE "ASSOCIATE_ID"::bigint >= 50000000001
  AND "ASSOCIATE_ID"::bigint < 50000000001 + 20000
  AND ("ASSOCIATE_ID"::bigint % 20) = 0;