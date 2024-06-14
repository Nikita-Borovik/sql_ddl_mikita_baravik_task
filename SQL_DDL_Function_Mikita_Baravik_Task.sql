1. CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
WITH current_quarter_sales AS (
    SELECT 
        f.film_id,
        c.name AS category,
        SUM(p.amount) AS revenue
    FROM 
        payment p
        JOIN rental r ON p.rental_id = r.rental_id
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN film_category fc ON f.film_id = fc.film_id
        JOIN category c ON fc.category_id = c.category_id
    WHERE 
        EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
        AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY 
        f.film_id, c.name
)
SELECT 
    category,
    SUM(revenue) AS total_revenue
FROM 
    current_quarter_sales
GROUP BY 
    category
HAVING 
    SUM(revenue) > 0;


2. CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(qtr INTEGER)
RETURNS TABLE (
    category VARCHAR,
    total_revenue NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.name AS category,
        SUM(p.amount) AS total_revenue
    FROM 
        payment p
        JOIN rental r ON p.rental_id = r.rental_id
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN film_category fc ON f.film_id = fc.film_id
        JOIN category c ON fc.category_id = c.category_id
    WHERE 
        EXTRACT(QUARTER FROM p.payment_date) = qtr
        AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY 
        c.name
    HAVING 
        SUM(p.amount) > 0;
END;
$$ LANGUAGE plpgsql;

3. CREATE OR REPLACE PROCEDURE new_movie(movie_title VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    new_film_id INTEGER;
    language_id INTEGER;
BEGIN
    -- Check if the language exists
    SELECT language_id INTO language_id FROM language WHERE name = 'Klingon';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Language Klingon does not exist in the language table';
    END IF;

    -- Generate a new unique film ID
    SELECT MAX(film_id) + 1 INTO new_film_id FROM film;

    -- Insert the new movie
    INSERT INTO film (
        film_id,
        title,
        description,
        release_year,
        language_id,
        rental_duration,
        rental_rate,
        length,
        replacement_cost,
        rating,
        special_features,
        last_update
    ) VALUES (
        new_film_id,
        movie_title,
        'Description not provided',
        EXTRACT(YEAR FROM CURRENT_DATE),
        language_id,
        3,
        4.99,
        90,  -- assuming a default length of 90 minutes
        19.99,
        'G',  -- assuming a default rating of G
        '{"Trailers"}',  -- assuming default special features
        CURRENT_TIMESTAMP
    );
END;
$$;
