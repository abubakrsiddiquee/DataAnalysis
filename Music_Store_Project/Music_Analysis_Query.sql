/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */

SELECT Top 1 title, last_name, first_name 
FROM employee
ORDER BY levels DESC



/* Q2: Which top 5 countries have the most Invoices? */

SELECT Top 5 COUNT(*) AS c, billing_country 
FROM invoice
GROUP BY billing_country 
ORDER BY c DESC


/* Q3: What are top 2 values of total invoice? */

SELECT Top 2 total 
FROM invoice
ORDER BY total DESC


/* Q4: Which 2 cities has the best customers? We would like to throw a promotional Music Festival in these cities we made the most money. 
Write a query that returns two cities that has the highest sum of invoice totals. 
Return both the cities name & sum of all invoice totals */

SELECT Top 2 billing_city,SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
;


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

SELECT Top 2
    c.first_name,
    c.last_name,
    c.customer_id,
    SUM(i.total) AS total_spending
FROM
    customer c
JOIN
    invoice i ON c.customer_id = i.customer_id
GROUP BY
    c.first_name,
    c.last_name,
    c.customer_id
ORDER BY
    total_spending DESC;






/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

/*Method 1 */

SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;


/* Method 2 */

SELECT DISTINCT email AS Email,first_name AS FirstName, last_name AS LastName, genre.name AS Name
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY email;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT Top 10 artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id, artist.name
ORDER BY number_of_songs DESC
;


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT name,milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track )
ORDER BY milliseconds DESC;




/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    bsa.artist_name,
    SUM(il.unit_price * il.quantity) AS amount_spent
FROM
    invoice i
JOIN
    customer c ON c.customer_id = i.customer_id
JOIN
    invoice_line il ON il.invoice_id = i.invoice_id
JOIN
    track t ON t.track_id = il.track_id
JOIN
    album alb ON alb.album_id = t.album_id
JOIN (
    SELECT Top 1
        artist.artist_id AS artist_id,
        artist.name AS artist_name
    FROM
        invoice_line
    JOIN
        track ON track.track_id = invoice_line.track_id
    JOIN
        album ON album.album_id = track.album_id
    JOIN
        artist ON artist.artist_id = album.artist_id
    GROUP BY
        artist.artist_id, artist.name
    ORDER BY
        SUM(invoice_line.unit_price * invoice_line.quantity) DESC
    
) bsa ON bsa.artist_id = alb.artist_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    bsa.artist_name
ORDER BY
    amount_spent DESC;



/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

/* Method 1: Using CTE */

WITH popular_genre AS 
(
    SELECT
        COUNT(invoice_line.quantity) AS purchases,
        customer.country,
        genre.name AS genre_name,
        genre.genre_id,
        ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM
        invoice_line 
    JOIN
        invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN
        customer ON customer.customer_id = invoice.customer_id
    JOIN
        track ON track.track_id = invoice_line.track_id
    JOIN
        genre ON genre.genre_id = track.genre_id
    GROUP BY
        customer.country,
        genre.name,
        genre.genre_id
)
SELECT
    purchases,
    country,
    genre_name,
    genre_id
FROM
    popular_genre
WHERE
    RowNo = 1;


/* Method 2: : Using Recursive */

WITH sales_per_country AS (
    SELECT
        COUNT(*) AS purchases_per_genre,
        customer.country,
        genre.name,
        genre.genre_id
    FROM
        invoice_line
    JOIN
        invoice ON invoice.invoice_id = invoice_line.invoice_id
    JOIN
        customer ON customer.customer_id = invoice.customer_id
    JOIN
        track ON track.track_id = invoice_line.track_id
    JOIN
        genre ON genre.genre_id = track.genre_id
    GROUP BY
        customer.country,
        genre.name,
        genre.genre_id
),
max_genre_per_country AS (
    SELECT
        MAX(purchases_per_genre) AS max_genre_number,
        country
    FROM
        sales_per_country
    GROUP BY
        country
)
SELECT
    sales_per_country.* 
FROM
    sales_per_country
JOIN
    max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE
    sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number
ORDER BY
    sales_per_country.country, sales_per_country.purchases_per_genre DESC;



/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

/* Method 1: using CTE */

WITH Customter_with_country AS (
    SELECT
        customer.customer_id,
        first_name,
        last_name,
        billing_country,
        SUM(total) AS total_spending,
        ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
    FROM
        invoice
    JOIN
        customer ON customer.customer_id = invoice.customer_id
    GROUP BY
        customer.customer_id,
        first_name,
        last_name,
        billing_country
),
Top_Customers_Per_Country AS (
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY total_spending DESC) AS RowNum
    FROM
        Customter_with_country
)
SELECT
    customer_id,
    first_name,
    last_name,
    billing_country,
    total_spending
FROM
    Top_Customers_Per_Country
WHERE
    RowNum = 1;


/* Thank You :) */
