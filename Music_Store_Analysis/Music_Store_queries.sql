--Basic Level Questions
-- 1. Who is the senior most employee based on job title?

select *
from employee
order by levels desc
limit 1

-- 2. Which countries have the most Invoices?

select *
from invoice
	
select billing_country,count(*) --sum(total)
from invoice
group by billing_country
order by count(*) desc 
limit 1

-- 3. What are top 3 values of total invoice?

select *
from invoice 
order by total desc
limit 3

-- 4. Which city has the best customers? 
-- Write a query that returns one city that has the highest sum of invoice totals. 


select billing_city,sum(total) as tot_invoices --sum(total)
from invoice
group by billing_city
order by sum(total) desc 
limit 1

-- 5. The customer who has spent the most money will be declared the best customer. 
--    Write a query that returns the best customer.

/* checking on the Sub-Query
select customer_id
from invoice
group by customer_id
order by sum(total) desc
limit 1
*/

	-- solution 1 using sub queries
select customer_id,first_name||' '||last_name as best customer
from customer
where customer_id in (
select customer_id
from invoice i
group by customer_id
order by sum(total) desc
limit 1
) 
	
	
	-- solution 2 using window functions
select c.customer_id,c.first_name||' '||c.last_name as best_customer,
		sum(n.total) over w as total_spent
from invoice as n
join customer as c on c.customer_id=n.customer_id 
window w as (partition by c.customer_id)
order by total_spent desc
limit 1


-- Intermediate Level Questions
-- 1. Write query to return the email, first name, last name who are Rock Music Genre listeners. 
-- 	  Return your list ordered alphabetically by email starting with A 

/* checking on the data
select *from invoice

select track_id
from track
where genre_id in (select genre_id from genre where name='Rock')
	
select *
from track
where genre_id='1' and track_id='834'
*/


select distinct c.email,c.first_name,c.last_name--,t.track_id,t.name
from customer c
join invoice i on c.customer_id=i.customer_id
join invoice_line il on i.invoice_id=il.invoice_id
join track t on t.track_id=il.track_id
join genre g on g.genre_id=t.genre_id and g.name like 'Rock'
order by c.email
	


-- 2.To invite the artists who have written the most rock music in the dataset.
--   Write a query that returns the Artist name and total track count of the top 10 rock bands. 

/* checking on the data
select *
from album

select artist_id
from artist
where artist_id in (select artist_id from album)

select distinct artist_id
from album
where artist_id not in (select artist_id from artist)
*/
	
select a.artist_id,a.name as artiwst_name,count(*) as total_Rock_tracks--t.name
from artist a
join album al on a.artist_id=al.artist_id
join track t on t.album_id=al.album_id
join genre g on g.genre_id=t.genre_id and g.name='Rock'
group by a.artist_id,a.name
order by count(*) desc
limit 10


-- 3. Write a query to return all the track names that have song length longer than the average song length. 
-- Return the Name and length in Milliseconds for each track.Order by the song length with the longest songs listed first.

	
/* checking on the subquery
select avg(milliseconds) from track
*/	

	
select name,milliseconds as dusration_ms
from track
where milliseconds>(select avg(milliseconds) from track )
order by 2 desc


-- Advanced Level Questions
-- 1. Find how much amount spent by each customer on each artist? 
--	  Write a query to return customer name, artist name and total spent.

/*checking on the data
select track_id,count(quantity)*unit_price
from invoice_line
group by track_id,unit_price

select * from artist where name='queen'
	
select  *
from invoice_line
where track_id='710'
*/

with cte1 as(
select inv.track_id,a.name,al.album_id,inv.invoice_id,inv.quantity*inv.unit_price as tot
from artist a
join album al on a.artist_id=al.artist_id
join track t on t.album_id=al.album_id
join invoice_line inv on inv.track_id=t.track_id),
cte2 as(
select c.first_name,c.last_name,i.invoice_id
from customer c 
join invoice i on c.customer_id=i.customer_id)

select c2.first_name||' '||c2.last_name as customer,
		c1.name as artist_name, round(sum(tot)::decimal,4) as spent
from cte1 c1
join cte2 c2 on c1.invoice_id=c2.invoice_id
--where c1.name='Queen'
group by c2.first_name,c2.last_name,c1.name
order by sum(tot) desc

	

---  2. Find how much amount spent by each customer on best selling artist? 
--	  Write a query to return customer name, best selling artist name and total spent on him.
 
with cte1 as(
select inv.track_id,a.name,al.album_id,inv.invoice_id,inv.quantity*inv.unit_price as tot
from artist a
join album al on a.artist_id=al.artist_id
join track t on t.album_id=al.album_id
join invoice_line inv on inv.track_id=t.track_id),
cte2 as(
select c.first_name,c.last_name,i.invoice_id
from customer c 
join invoice i on c.customer_id=i.customer_id)

select c2.first_name||' '||c2.last_name as customer,
		c1.name as artist_name, round(sum(tot)::decimal,2) as  spent
from cte1 c1
join cte2 c2 on c1.invoice_id=c2.invoice_id
where c1.name in (select name  
					from cte1
					group by name
					order by sum(tot) desc
					limit 1)
group by c2.first_name,c2.last_name,c1.name
order by sum(tot) desc

	
-- 3. Find out the most popular music Genre for each country. Most popular genre is the genre with the highest number of purchases. 
--    Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.

/* checking on the data
select * from genre
*/

	
with cte as(
select c.country,g.name as genre,sum(il.quantity) as purchases,
rank() over(partition by c.country order by sum(quantity) desc) as rn
from customer c
join invoice inv on c.customer_id=inv.customer_id
join invoice_line il on il.invoice_id=inv.invoice_id 
join track t on t.track_id=il.track_id
join genre g on g.genre_id=t.genre_id 
group by c.country,g.name
order by c.country)

select *
from cte 
where rn=1
order by country


-- 4.Write a query that determines the customer that has spent the most on music for each country. 
--	Write a query that returns the country along with the top customer and how much they spent. 
--	For countries where the top amount spent is shared, provide all customers who spent this amount

/* checking on the data
select *
from media_type
*/
	
with cte as(
select c.customer_id,c.country,c.first_name ||' '|| c.last_name as customer,
	round(sum(il.quantity*il.unit_price)::decimal ,2) as spent,
rank() over(partition by c.country order by sum(quantity) desc) as rn
from customer c
join invoice inv on c.customer_id=inv.customer_id
join invoice_line il on il.invoice_id=inv.invoice_id 
group by 1,2,3)

select *
from cte 
where rn=1


