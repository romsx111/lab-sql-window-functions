USE sakila;

-- Challenge 1
/*1. Rank films by their length and create an output table that includes
the title, length, and rank columns only. 
Filter out any rows with null or zero values in the length column.*/
SELECT
	title,
    length,
    RANK() OVER (ORDER BY length DESC) AS 'rank'
FROM film
WHERE length IS NOT NULL
	AND length > 0;

/*2. Rank films by length within the rating category and create an output table 
that includes the title, length, rating and rank columns only. 
Filter out any rows with null or zero values in the length column.
*/
SELECT
	title,
    length,
    rating,
    RANK() OVER (PARTITION BY rating ORDER BY length DESC) AS 'rank'
FROM film
WHERE length IS NOT NULL
	AND length > 0;


/* 3. Produce a list that shows for each film in the Sakila database,
the actor or actress who has acted in the greatest number of films,
as well as the total number of films in which they have acted.
Hint: Use temporary tables, CTEs, or Views when appropiate 
to simplify your queries.
*/
WITH actor_film_count AS(
SELECT
	a.actor_id,
    CONCAT(a.first_name,' ',a.last_name) AS actor_name,
    COUNT(fa.film_id) AS total_films
FROM actor a
JOIN film_actor fa
	ON a.actor_id = fa.actor_id
GROUP BY a.actor_id, actor_name
),
film_actor_rank AS(
SELECT
	f.title,
    afc.actor_name,
    afc.total_films,
    RANK() OVER( 
    PARTITION BY f.film_id
    ORDER BY afc.total_films
    ) AS actor_rank
FROM film f
JOIN film_actor fa
	ON f.film_id = fa.film_id
JOIN actor_film_count afc
	ON fa.actor_id  = afc.actor_id
    )
SELECT
	title,
    actor_name,
    total_films
FROM film_actor_rank
WHERE actor_rank = 1
ORDER BY title;

-- Challenge 2
/* Step 1. Retrieve the number of monthly active customers, 
i.e., the number of unique customers who rented a movie in each month.
*/
WITH monthly_active_customers AS (
SELECT
	DATE_FORMAT(rental_date,'%Y-%m') AS rental_month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM rental
GROUP BY rental_month
)
SELECT *
FROM monthly_active_customers;

/* Step 2. Retrieve the number of active users in the previous month.
*/
WITH monthly_active_customers AS (
SELECT
	DATE_FORMAT(rental_date,'%Y-%m') AS rental_month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM rental
GROUP BY rental_month
)
SELECT
	rental_month,
    active_customers,
LAG(active_customers) OVER (ORDER BY rental_month) AS previous_month_active_customers
FROM monthly_active_customers;


/* Step 3. Calculate the percentage change in the number of active customers 
between the current and previous month.
*/

WITH monthly_active_customers AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m') AS rental_month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m')
),

monthly_activity_with_previous AS (
    SELECT
        rental_month,
        active_customers,
        LAG(active_customers) OVER (ORDER BY rental_month)
            AS previous_month_active_customers
    FROM monthly_active_customers
)
SELECT
    rental_month,
    active_customers,
    previous_month_active_customers,
    ROUND(
		(
		(active_customers - previous_month_active_customers)/previous_month_active_customers
        )*100,
    2) AS percentaje_change
FROM monthly_activity_with_previous;

/* Step 4. Calculate the number of retained customers every month, 
i.e., customers who rented movies in the current and previous months.
Hint: Use temporary tables, CTEs, or Views when appropiate 
to simplify your queries.
*/
WITH customer_months AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(rental_date, '%Y-%m-01') AS rental_month
    FROM rental
),

retained_customers AS (
    SELECT
        current_month.rental_month,
        COUNT(DISTINCT current_month.customer_id)
            AS retained_customers
    FROM customer_months current_month
    JOIN customer_months previous_month
        ON current_month.customer_id = previous_month.customer_id
        AND previous_month.rental_month =
            DATE_SUB(current_month.rental_month, INTERVAL 1 MONTH)
    GROUP BY current_month.rental_month
)

SELECT
    DATE_FORMAT(rental_month, '%Y-%m') AS rental_month,
    retained_customers
FROM retained_customers
ORDER BY rental_month;