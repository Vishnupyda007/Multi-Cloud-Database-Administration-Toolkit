-- =========== INDEX CREATION SCRIPT ===========

-- Index on Payment table for customer lookups and date filtering.
-- Helps queries that aggregate customer spending over time.
CREATE INDEX IF NOT EXISTS idx_payment_customer_id_payment_date ON payment (customer_id, payment_date);

-- Composite index on Rental table.
-- Massively helps the window functions that partition by customer and order by date.
CREATE INDEX IF NOT EXISTS idx_rental_customer_id_rental_date ON rental (customer_id, rental_date);

-- Index to speed up finding which film is on which inventory item.
CREATE INDEX IF NOT EXISTS idx_inventory_film_id ON inventory (film_id);

-- Index on the Film Actor table.
-- Crucial for the self-join in the actor collaboration query.
CREATE INDEX IF NOT EXISTS idx_film_actor_film_id_actor_id ON film_actor (film_id, actor_id);

-- A basic index on film release year, which is a common filter.
CREATE INDEX IF NOT EXISTS idx_film_release_year ON film (release_year);


-- === ADVANCED INDEX FOR FUZZY STRING MATCHING ===

-- Step 1: Enable the 'pg_trgm' extension. This provides trigram functions
-- that are necessary for efficient fuzzy string matching.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Step 2: Create a GIN (Generalized Inverted Index) on the customer's last name.
-- This is a special index type designed for text search and is perfect
-- for speeding up similarity checks.
CREATE INDEX IF NOT EXISTS idx_customer_lastname_gin_trgm ON customer USING GIN (last_name gin_trgm_ops);
