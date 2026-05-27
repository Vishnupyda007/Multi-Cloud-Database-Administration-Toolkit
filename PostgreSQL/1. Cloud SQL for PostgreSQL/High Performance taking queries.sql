

SELECT * FROM film_details WHERE category = 'Sci-Fi' LIMIT 10;



SELECT * FROM customer_details WHERE customer_id = 123;



SELECT * FROM sales_report_by_store WHERE sale_date = (CURRENT_DATE - INTERVAL '1 day');


SELECT * FROM film_inventory WHERE film_title LIKE 'Awesome New Movie 1%';



SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_revenue
FROM
    customer c
JOIN
    payment p ON c.customer_id = p.customer_id
GROUP BY
    c.customer_id, c.first_name, c.last_name
ORDER BY
    total_revenue DESC
LIMIT 20;




WITH FilmRentals AS (
    SELECT
        s.store_id,
        f.title,
        COUNT(r.rental_id) AS rental_count,
        ROW_NUMBER() OVER(PARTITION BY s.store_id ORDER BY COUNT(r.rental_id) DESC) as rn
    FROM
        rental r
    JOIN
        inventory i ON r.inventory_id = i.inventory_id
    JOIN
        film f ON i.film_id = f.film_id
    JOIN
        store s ON i.store_id = s.store_id
    GROUP BY
        s.store_id, f.title
)
SELECT
    store_id,
    title,
    rental_count
FROM
    FilmRentals
WHERE
    rn <= 10
ORDER BY
    store_id, rental_count DESC;



SELECT
    co.country,
    TO_CHAR(p.payment_date, 'YYYY-MM') AS payment_month,
    SUM(p.amount) AS monthly_revenue
FROM
    payment p
JOIN
    customer c ON p.customer_id = c.customer_id
JOIN
    address a ON c.address_id = a.address_id
JOIN
    city ci ON a.city_id = ci.city_id
JOIN
    country co ON ci.country_id = co.country_id
GROUP BY
    co.country, payment_month
ORDER BY
    co.country, payment_month;



SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) as total_spent
FROM
    customer c
JOIN
    payment p ON c.customer_id = p.customer_id
WHERE
    c.customer_id IN (
        SELECT DISTINCT r.customer_id
        FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film_category fc ON i.film_id = fc.film_id
        JOIN category cat ON fc.category_id = cat.category_id
        WHERE cat.name = 'Sci-Fi'
    )
GROUP BY
    c.customer_id, c.first_name, c.last_name
HAVING
    SUM(p.amount) > 150.00
ORDER BY
    total_spent DESC;




SELECT
    f.title,
    a.first_name,
    a.last_name,
    AVG(r.return_date - r.rental_date) AS average_rental_duration
FROM
    film f
JOIN
    film_actor fa ON f.film_id = fa.film_id
JOIN
    actor a ON fa.actor_id = a.actor_id
JOIN
    inventory i ON f.film_id = i.film_id
JOIN
    rental r ON i.inventory_id = r.inventory_id
WHERE
    a.first_name = 'Actor' AND a.last_name LIKE 'LastName 1%' -- Find actors like "LastName 10", "LastName 11", etc.
    AND r.return_date IS NOT NULL
GROUP BY
    f.title, a.first_name, a.last_name
ORDER BY
    average_rental_duration DESC
LIMIT 50;





WITH RankedFilms AS (
    SELECT
        film_id,
        title,
        ts_rank(fulltext, to_tsquery('english', 'Awesome & New & Movie')) AS relevance_rank
    FROM
        film
    WHERE
        fulltext @@ to_tsquery('english', 'Awesome & New & Movie')
)
SELECT
    rf.title,
    rf.relevance_rank,
    SUM(p.amount) AS total_revenue
FROM
    RankedFilms rf
JOIN
    inventory i ON rf.film_id = i.film_id
JOIN
    rental r ON i.inventory_id = r.inventory_id
JOIN
    payment p ON r.rental_id = p.rental_id
GROUP BY
    rf.title, rf.relevance_rank
ORDER BY
    relevance_rank DESC, total_revenue DESC
LIMIT 50;




SELECT
    TO_CHAR(p.payment_date, 'YYYY-MM') AS month,
    s.store_id,
    co.country,
    SUM(p.amount) AS total_revenue,
    AVG(p.amount) AS avg_rental_price,
    COUNT(p.payment_id) AS total_rentals
FROM
    payment p
JOIN
    customer c ON p.customer_id = c.customer_id
JOIN
    address a ON c.address_id = a.address_id
JOIN
    city ci ON a.city_id = ci.city_id
JOIN
    country co ON ci.country_id = co.country_id
JOIN
    store s ON c.store_id = s.store_id
GROUP BY
    month, s.store_id, co.country
HAVING
    SUM(p.amount) > 500 -- Only show results for country/store combos with significant revenue
ORDER BY
    month, total_revenue DESC;




SELECT
    i.inventory_id,
    f.title,
    s.store_id,
    i.last_update
FROM
    inventory i
JOIN
    film f ON i.film_id = f.film_id
JOIN
    store s ON i.store_id = s.store_id
WHERE
    NOT EXISTS (
        SELECT 1
        FROM rental r
        WHERE r.inventory_id = i.inventory_id
        AND r.rental_date >= (NOW() - INTERVAL '6 months')
    )
ORDER BY
    i.last_update DESC
LIMIT 500;



--------------
SELECT
    mgr.first_name || ' ' || mgr.last_name AS manager_name,
    s.store_id,
    COUNT(r.rental_id) AS total_rentals_processed,
    SUM(p.amount) AS total_revenue
FROM
    payment p
JOIN
    rental r ON p.rental_id = r.rental_id
JOIN
    store s ON p.staff_id = s.manager_staff_id -- Corrected Join logic
JOIN
    staff mgr ON s.manager_staff_id = mgr.staff_id
GROUP BY
    s.store_id, manager_name
ORDER BY
    total_revenue DESC;


-----------
SELECT
    a1.first_name || ' ' || a1.last_name AS actor_1,
    a2.first_name || ' ' || a2.last_name AS actor_2,
    COUNT(*) AS films_in_common
FROM
    film_actor fa1
JOIN
    film_actor fa2 ON fa1.film_id = fa2.film_id AND fa1.actor_id < fa2.actor_id
JOIN
    actor a1 ON fa1.actor_id = a1.actor_id
JOIN
    actor a2 ON fa2.actor_id = a2.actor_id
GROUP BY
    actor_1, actor_2
ORDER BY
    films_in_common DESC
LIMIT 20;



--------------------4mins run-----------
-- This query will now work because the fuzzystrmatch extension is enabled.
WITH CustomerStats AS (
    -- First, get the lifetime spend for every single customer.
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(p.amount) as total_spend
    FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
),
TopSpenders AS (
    -- Identify our top 1000 customers to use as the "source" for our search.
    SELECT customer_id, total_spend
    FROM CustomerStats
    ORDER BY total_spend DESC
    LIMIT 1000
),
CustomerFavoriteActor AS (
    -- This is a very heavy CTE. It finds the single favorite actor for every customer.
    SELECT
        customer_id,
        favorite_actor_id
    FROM (
        SELECT
            r.customer_id,
            fa.actor_id as favorite_actor_id,
            -- Rank actors by how many times the customer has rented their films.
            ROW_NUMBER() OVER(PARTITION BY r.customer_id ORDER BY COUNT(f.film_id) DESC) as actor_rank
        FROM rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN film_actor fa ON f.film_id = fa.film_id
        GROUP BY r.customer_id, fa.actor_id
    ) ranked_actors
    WHERE actor_rank = 1
)
-- THE MAIN EVENT: Find "similar" customers using a massive cross join and expensive comparisons.
SELECT
    ts.customer_id AS top_customer_id,
    ts_details.first_name || ' ' || ts_details.last_name AS top_customer_name,
    cs_all.customer_id AS similar_customer_id,
    cs_all.first_name || ' ' || cs_all.last_name AS similar_customer_name,
    -- Levenshtein distance is a CPU-intensive string comparison function.
    levenshtein(ts_details.last_name, cs_all.last_name) AS name_similarity,
    ABS(ts.total_spend - cs_all.total_spend) AS spending_difference
FROM
    CustomerStats cs_all
-- This CROSS JOIN creates 1000 * 500,000 = 500,000,000 potential pairs to evaluate.
CROSS JOIN
    TopSpenders ts
-- Join to get the names and favorite actors for all customers in the cross product.
JOIN
    CustomerStats ts_details ON ts.customer_id = ts_details.customer_id
JOIN
    CustomerFavoriteActor cfa_all ON cs_all.customer_id = cfa_all.customer_id
JOIN
    CustomerFavoriteActor cfa_top ON ts.customer_id = cfa_top.customer_id
WHERE
    -- Ensure we aren't comparing a customer to themselves.
    cs_all.customer_id != ts.customer_id
    -- Condition 1: They must have the same favorite actor.
    AND cfa_all.favorite_actor_id = cfa_top.favorite_actor_id
    -- Condition 2 (Expensive): Their last names must be very similar (edit distance < 3).
    AND levenshtein(ts_details.last_name, cs_all.last_name) < 3
    -- Condition 3: Their total lifetime spending must be within $10 of each other.
    AND ABS(ts.total_spend - cs_all.total_spend) < 10
LIMIT 100;


