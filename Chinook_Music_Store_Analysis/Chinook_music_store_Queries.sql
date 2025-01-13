use chinook;
								-- Objective questions
-- 1.	Does any table have missing values or duplicates? If yes how would you handle it ?

	-- Search all the tables in the database whether they have any null values with simple query

select * from artist
where ( artist_id is null OR name is null );

select * from album
where ( album_id is null OR title is null OR artist_id is null ) is null;

	-- Above Query returns rows having atleast one null value and do it for all the tables

select * from customer
where ( customer_id is null OR first_name is null OR last_name is null OR company is null OR 
address is null OR city is null OR state is null OR country is null OR postal_code is null OR 
phone is null OR fax is null OR email is null OR support_rep_id is null );
    
select * from track
where ( name is null OR album_id is null OR media_type_id is null OR genre_id is null OR 
composer is null OR milliseconds is null OR bytes is null OR unit_price is null  ) ;
	
    -- We can see that TRACK,CUSTOMER tables are having null values   
	-- we can update those null values with 'Unknown','No fax' because both are a varchar() tye
    
update track 
set composer = 'Unknown'
where composer is null ;

update customer 
set fax='No fax'
where fax is null ;

update customer
set state='Unknown State'
where state is null;

update customer
set company='No Info'
where company is null;

-- 2.	Find the top-selling tracks and top artist in the USA and identify their most famous genres.
		
        -- top-selling tracks in usa
select t.name as track_name,sum(invline.quantity) as total_sold,
				sum(invline.quantity*invline.unit_price) as total_sales
from track t
join invoice_line invline on t.track_id=invline.track_id
join invoice inv on inv.invoice_id=invline.invoice_id
where inv.billing_country="USA"     -- Customer country is same as his invoice billing country
group by 1
order by 3 desc;

		-- top artists in the USA
select ar.artist_id,ar.name as artist_name,
		sum(invline.quantity) as total_sold,
			sum(invline.quantity*invline.unit_price) as total_sales
from track t
join invoice_line invline on t.track_id=invline.track_id
join invoice inv on inv.invoice_id=invline.invoice_id
join album a on a.album_id=t.album_id
join artist ar on a.artist_id=ar.artist_id
where inv.billing_country="USA"
group by 1,2
order by 4 desc;

		-- Famous genres of the top artist in the USA.
select g.genre_id, g.name AS genre_name, sum(il.quantity) AS total_sold
from invoice i 
join invoice_line il on il.invoice_id = i.invoice_id
join track t on il.track_id = t.track_id
join album al on t.album_id = al.album_id
join genre g on t.genre_id = g.genre_id
where i.billing_country = 'USA' and al.artist_id = 152 
group by 1,2			--  artist_id of famous artist in USA is 152
order by 3 desc;


-- 3.  What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
        -- we have only location details of customers
        -- Based on Country 
select country, count(*) as TotalCustomers
from customer
group by country
order by 2 desc;

		-- Based on Country and State
select  state , count(*) as TotalCustomers
from customer
where state != 'Unknown State'
group by 1
order by 1,2 desc;

-- 4. Calculate the total revenue and number of invoices for each country, state, and city:
		-- In Countries
select billing_country as country, sum(total) as total_revenue,
			count(invoice_id) as total_invoices
from invoice 
group by billing_country
order by total_revenue desc, total_invoices desc;
		-- In states
select billing_state as state, sum(total) as total_revenue,
			count(invoice_id) as total_invoices
from invoice
group by billing_state
order by total_revenue desc, total_invoices desc;
        -- In Cities
select billing_city as city, sum(total) as total_revenue,
			count(invoice_id) as total_invoices
from invoice 
group by billing_city
order by total_revenue desc, total_invoices desc;

-- 5. Find the top 5 customers by total revenue in each country

with cte as(
select c.customer_id,concat(c.first_name,' ',c.last_name) as full_name,
		billing_country as country,sum(total) as total_revenue,
			rank() over(partition by billing_country order by sum(total) desc) as rnk
from invoice i
join customer c on c.customer_id=i.customer_id
group by 1,2,3
order by customer_id)

select *
from cte 
where rnk<=5
order by country,rnk;

-- 6.	Identify the top-selling track for each customer

with cte as(
select c.customer_id, concat(c.first_name,' ',c.last_name) as full_name, 
	 t.name AS track_name, 
    sum(il.quantity*il.unit_price) as total_purchased,
    row_number() over (partition by i.customer_id order by sum(il.quantity*il.unit_price) desc) as rnk
from customer c
join invoice i on i.customer_id = c.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
group by 1,2,3
order by 1)

select customer_id, full_name, track_name, total_purchased
from cte
where rnk=1;

-- 7.	Are there any patterns or trends in customer purchasing behavior 
-- (e.g., frequency of purchases, preferred payment methods, average order value)?

select c.customer_id, concat(c.first_name,' ', c.last_name) as full_name,
	year(i.invoice_date) as year,count(i.invoice_id) as purchase_count,
	sum(i.total) as tot_revenue, avg(i.total) as avg_ord_value
from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id, full_name, year(i.invoice_date)
order by c.customer_id, full_name, year(i.invoice_date);

-- 8.	What is the customer churn rate?

with lastyr as (
select year(max(invoice_date))-1
from invoice
),
tot_cust as (
select c.customer_id
from customer c
join invoice i on c.customer_id=i.customer_id
group by c.customer_id
having year(max(i.invoice_date)) in ( (select * from lastyr)+1,(select * from lastyr) )
),
prev_cust as (
select c.customer_id
from customer c
join invoice i on c.customer_id=i.customer_id
group by c.customer_id
having year(max(i.invoice_date)) in ((select * from lastyr))
)

select count(*)*100/(select count(*) from tot_cust) as churn_Rate
from prev_cust;

-- 9.	Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.

select distinct g.name,
		sum(il.quantity) over w as genre_tot_sales,
		( sum(il.quantity) over w *100/sum(il.quantity) over() ) as genre_perc
from invoice i
join invoice_line il on i.invoice_id=il.invoice_id
join track t on t.track_id=il.track_id
join genre g on g.genre_id=t.genre_id
where i.billing_country='USA'
window w as (partition by g.name) 
order by 2 desc;

-- 10.	Find customers who have purchased tracks from at least 3 different genres

select concat(c.first_name,' ',c.last_name) as costumer_name,
		 count(distinct g.genre_id) as genres_purchased
from customer c
join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
group by 1
having count(distinct g.genre_id)>=3
order by 2 desc;

-- 11.	Rank genres based on their sales performance in the USA

select g.name,	
		sum(il.quantity*il.unit_price) as total_revenue,
        dense_rank() over ( order by sum(il.quantity) desc) as rnk
from invoice i
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id 
where i.billing_country='USA'
group by g.name
order by 3;

-- 12.	Identify customers who have not made a purchase in the last 3 months

with latest_billday as(
select date_add( max(date(invoice_date)),interval -3 month) as recent_day
from invoice)

select distinct c.customer_id,concat(c.first_name,' ',c.last_name) as costumer_name
from customer c
join invoice i on c.customer_id=i.customer_id
group by customer_id
having max(i.invoice_date)<(select * from latest_billday)
order by 1;


								-- Subjective questions

-- 1.	Recommend the three albums from the new record label that should be prioritised 
	 -- for advertising and promotion in the USA based on genre sales analysis.
         
with cte as(
select g.name as genre_name,
			sum(il.unit_price * il.quantity) as album_sales,
			dense_rank() over ( order by sum(il.unit_price*il.quantity) desc) rnk
 from genre g 
join track t on g.genre_id = t.genre_id
join invoice_line il on t.track_id = il.track_id
join invoice i on il.invoice_id = i.invoice_id
where i.billing_country = 'USA'
group by  g.name )

select *
from cte
where rnk<=3
order by 2 desc;

 
with cte as(
select g.name as genre_name, al.title as album_title, 
			sum(il.unit_price * il.quantity) as album_sales,
			dense_rank() over (partition by g.name order by sum(il.unit_price*il.quantity) desc) rnk
 from genre g 
join track t on g.genre_id = t.genre_id
join invoice_line il on t.track_id = il.track_id
join invoice i on il.invoice_id = i.invoice_id
join album al on t.album_id = al.album_id
where i.billing_country = 'USA'
group by  g.name, al.title
having sum(il.quantity) >4 )

select *
from cte
where rnk<=3
order by 3 desc;


-- 2.  Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.


select g.name, sum(il.unit_price * il.quantity) as genre_sum,
		dense_rank() over (order by sum(il.unit_price * il.quantity) desc) as rnk
from invoice i 
join invoice_line il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where i.billing_country = 'USA'
group by g.name ;


-- 3.  Customer Purchasing Behavior Analysis: How do the purchasing habits (frequency, basket size, 
--   spending amount) of long-term customers differ from those of new customers? What insights can 
--   these patterns provide about customer loyalty and retention strategies?

with customer_details as (
select c.customer_id, count(distinct i.invoice_id) as tot_purchases, sum(il.quantity) as basket_size, 
			sum(i.total) as total_spent, round(avg(i.total),2) as avg_order_value,
			case when datediff(max(i.invoice_date), min(i.invoice_date)) >=1050 
			 then 'long-term customers' else 'new customers' end as customer_category 
from customer c 
join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
group by c.customer_id
)

select customer_category, round(avg(tot_purchases),2) as avg_purchase_frequency,
		round(avg(basket_size),2) as avg_basket_size, round(avg(total_spent),2) as avg_spending_amount,
		 round(avg(avg_order_value),2) as avg_order_value
from customer_details
group by customer_category;


-- 4. Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together 
-- by customers? How can this information guide product recommendations and cross-selling initiatives?

-- Genre Affinity Analysis:

select distinct g1.name as genre01, g2.name as genre02,count(distinct il1.invoice_id) as combined_purchase_count
from invoice_line il1
join invoice_line il2 on il1.invoice_id = il2.invoice_id and il1.track_id < il2.track_id
join track t1 on il1.track_id = t1.track_id
join track t2 on il2.track_id = t2.track_id
join genre g1 on t1.genre_id = g1.genre_id
join genre g2 on t2.genre_id = g2.genre_id where g1.genre_id < g2.genre_id
group by 1,2
order by 3 desc ;

-- Artist Affinity Analysis:

select distinct ar1.name as artist01, ar2.name as artist02, count( distinct il1.invoice_id ) as combined_purchase_count
from invoice_line il1
join invoice_line il2 on il1.invoice_id = il2.invoice_id and il1.track_id < il2.track_id
join track t1 on il1.track_id = t1.track_id
join track t2 on il2.track_id = t2.track_id
join album a1 on t1.album_id = a1.album_id
join album a2 on t2.album_id = a2.album_id 
join artist ar1 on a1.artist_id = ar1.artist_id
join artist ar2 on a2.artist_id = ar2.artist_id and ar1.artist_id <> ar2.artist_id
group by 1,2
order by 3 desc ;

-- Album Affinity Analysis:

select distinct a1.title as album01, a2.title as album02, count( distinct il1.invoice_id ) as combined_purchase_count
from invoice_line il1
join invoice_line il2 on il1.invoice_id = il2.invoice_id and il1.track_id < il2.track_id
join track t1 on il1.track_id = t1.track_id
join track t2 on il2.track_id = t2.track_id
join album a1 on t1.album_id = a1.album_id
join album a2 on t2.album_id = a2.album_id where a1.album_id <> a2.album_id
group by 1,2
order by 3 desc ;


-- 5. Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across different 
-- geographic regions or store locations? How might these correlate with local demographic or economic factors?


select a.country,count(a.customer_id) as high_valued_customers
from customer a
join ( select (customer_id),count(quantity) as high_valued_customers
		from invoice i
        join invoice_line il on i.invoice_id = il.invoice_id
		group by customer_id 
		having count(quantity) > 90 ) b on a.customer_id=b.customer_id
group by 1
order by 2 desc;

 -- mid_valued_customers:-  between 60 and 90
 -- high_valued_customers:-  > 90
 -- low_valued_customers:-  < 70

-- 6. Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), which customer segments are 
--  more likely to churn or pose a higher risk of reduced spending? What factors contribute to this risk?


select a.country,count(a.customer_id)
from customer a
join ( select (customer_id)
		from invoice i
        join invoice_line il on i.invoice_id = il.invoice_id
		group by customer_id
		having count(quantity) > 80 ) b on a.customer_id=b.customer_id
group by 1;


-- 10.	How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER 
-- to store the release year of each album?

alter table album
add column releaseyear integer;


select * from album;


-- 11. Chinook is interested in understanding the purchasing behavior of customers based on their geographical 
-- location. They want to know the average total amount spent by customers from each country, along with the number of 
-- customers and the average number of tracks purchased per customer. Write an SQL query to provide this information.

with customer_details as(
select c.country, c.customer_id, sum(il.quantity) as total_tracks,
		sum(i.total) as total_spent, sum(il.quantity*il.unit_price) as spent2
from customer c
join invoice i on c.customer_id = i.customer_id
join invoice_line il on i.invoice_id = il.invoice_id
group by 1,2)

select Country, count(customer_id) as tot_customers,
avg(total_tracks) as avg_tracks_purchased_per_cust,
avg(spent2) as avg_amnt_spent_per_customer
from customer_details
group by 1
order by 2 desc
