-- creating olympics and noc_olympics tables to import data into them
-- NOC means national olympic committee 
create table olympics(
	ID int, NAME varchar,
	SEX varchar, AGE varchar,
	HEIGHT varchar, Weight varchar, 
	TEAM varchar, NOC varchar,
	GAMES varchar, YEAR int,
	season varchar, CITY varchar,
	sport varchar, event varchar,
	medal varchar
);

create table noc_olympics(
	NOC varchar,region varchar, notes varchar
);

drop table if exists olympics;
drop table if exists noc_olympics;


select *
from noc_olympics;

select * 
from olympics ; -- ; is important to seperate queries from 1 other

select
count(*) from olympics;

select 
count(*) from noc_olympics;


copy olympics from 'D:\sql_datasets\Olympics_data\athlete_events.csv' delimiter ',' csv header;
copy noc_olympics from 'D:\sql_datasets\Olympics_data\noc_regions.csv' delimiter ',' csv header;

-- above is one of the way to copy csv into table
-- another one is right click the table name and select import/export 


/*   Analysing rowa and coloumns of the tables

select (5+60) rrr

select count (1)
from olympics op
where op.AGE > '25'

select count(1)
from olympics op
join noc_olympics noc on op.noc=noc.noc 

	
select (
select count (1)
from olympics op	
where op.AGE >= '25'
union 
select count (1)
from olympics op
where op.AGE < '25'
) total

	
select op.sport,count (*) as players
from olympics op
group by sport
order by players desc
limit 20;
--  gives top 20 sports with most no. of palyers
*/


-- 1. How many olympic games have been held?

select count(distinct games) as total_games
from olympics


-- 2. List down all Olympics games held so far.
	
/*  practice
select op.year,count(op.year)
from olympics op
group by op.year
*/

select op.year, op.season, op.city 
from olympics op
group by op.year,op.season, op.city-- all columns shld be given in "grp by" clause 
order by op.year

	-- OR
	
select distinct oh.year,oh.season,oh.city 
from olympics oh
order by year;


-- 3 .Mention the total no of nations who participated in each olympics game?
-- NOC means national olympic committee 

select games,count(distinct noc)
from olympics
group by games
order by games

---- OR
	
with all_countries as
        (select games, nr.region
        from olympics oh
        join noc_olympics nr ON nr.noc = oh.noc
        group by games, nr.region)
select games, count(1) as total_countries   
from all_countries
group by games
order by games;

	
-- 4. Which year saw the highest and lowest no of countries participating in olympics


with cntries as (select games,count(distinct noc) as total_cntries
from olympics
group by games)

select distinct 
concat((first_value(c.games) over (order by total_cntries))
,' - ',(first_value(c.total_cntries) over (order by total_cntries))) as lowest,
concat((first_value(c.games) over (order by total_cntries desc))
,' - ',(first_value(c.total_cntries) over (order by total_cntries desc))) as highest  -- NEW ONE
from cntries as c

	
-- 5. Which nation has participated in all of the olympic games

	
with tot_games as( -- total games held
select count(distinct games) as games
from olympics),
	 cntris as( -- total countries
select distinct nop.region as country, op.games 
from noc_olympics as nop
join olympics op on op.noc=nop.noc),
	 tot_games_by_cntris as( 
select country,count(*) games
from cntris t
group by country)

	
select cnt.country,cnt.games
from tot_games_by_cntris cnt
join tot_games tg on cnt.games=tg.games
order by country

	
--6. Identify the sport which was played in all summer olympics.

with tot_sum_games as (
select count(distinct games) as summer_games
from olympics
where season='Summer'),
	 summer_games as(
select distinct games,sport
from olympics
where season='Summer'),
	tot_cnt as(
select  sport, count(games)as tot_summer_games
from summer_games
group by sport)

	
select cnt.sport, cnt.tot_summer_games as played_summer_games
from tot_cnt as cnt
join tot_sum_games as s on s.summer_games=cnt.tot_summer_games

	
--7. Which Sports were just played only once in the olympics.

with cnts as(
select sport,count(distinct games) as cnt
from olympics op
group by sport )

select distinct c.sport,c.cnt,op.games
from cnts c
join olympics op on c.cnt=1 and c.sport=op.sport


--8. Fetch the total no of sports played in each olympic games.
	

select games,count(distinct sport) as cnt
from olympics
group by games
order by cnt desc


--9. Fetch oldest athletes to win a gold medal

	
with age as(
select max(age) as max_age
from olympics
where age<>'NA' and medal='Gold')

select name,sex,age,city,sport,team,games,medal
from olympics as op
join age as a on op.age=a.max_age and op.medal='Gold'


--10. Find the Ratio of male and female athletes participated in all olympic games.
	
	
with fem as(
select count(*) as cnt
from olympics
where sex='F'),
	male as(
select count(*) as cnt
from olympics
where sex='M')

select ((male.cnt*1.0)/fem.cnt) men_2_women_ratio
from male,fem

--11. Fetch the top 5 athletes who have won the most gold medals.


with gold_medal as(
select name,team,count(medal) as cnt
from olympics
where medal='Gold' 
group by name,team),
	gold_ranks as(
select *, dense_rank() over (order by cnt desc) as rnk -- NEW ONE
from gold_medal)

select name,team,cnt as total_medals
from gold_ranks
where rnk<=5

	
--12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).


with gold_medal as(
select name,team,count(medal) as cnt
from olympics
where medal='Gold' or medal='Silver' or medal='Bronze' 
group by name,team),
	gold_ranks as(
select *, dense_rank() over (order by cnt desc) as rnk -- NEW ONE
from gold_medal)

select name,team,cnt as medals
from gold_ranks
where rnk<=5

	
--13. Fetch the top 5 most successful countries in olympics. 
--		Success is defined by no of medals won.


with gold_ranks as(
select *, dense_rank() over (order by total_medals desc) as rank 							
from (
select nop.region,count(op.medal) as total_medals
from olympics op
join noc_olympics nop on op.noc=nop.noc and (op.medal<>'NA')
group by nop.region))

select region,total_medals
from gold_ranks
where rank<=5


-- 14. List down total gold, silver and bronze medals won by each country.

/* Sub Query for crosstab
select nop.region as cntry, op.medal,count(op.medal) as medals
from olympics op
join noc_olympics nop on op.noc=nop.noc and (op.medal<>'NA')
group by nop.region,op.medal--,op.medal
order by cntry
*/
	
--crosstab is to change a row into columns  
create extension tablefunc;-- coalesce is to replace NULL values with custom values

select country, coalesce(gold,0) as gold,coalesce(silver,0) as silver,coalesce(bronze,0) as bronze
from crosstab('select nop.region as cntry, op.medal,count(op.medal) as medals
			from olympics op
			join noc_olympics nop on op.noc=nop.noc and (op.medal<>''NA'')
			group by nop.region,op.medal')
		as tabl3 (country varchar,bronze bigint, gold bigint, silver bigint )
		order by gold desc

	
-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

	
/*	-- SUB QUERY for crosstab
select  op.games,nop.region ,op.medal,count(op.medal) as medals
from olympics op
join noc_olympics nop on op.noc=nop.noc and (op.medal<>'NA')
group by nop.region,op.games,op.medal
order by op.games
*/

select  game, country, coalesce(gold,0) as gold,coalesce(silver,0) as silver,coalesce(bronze,0) as bronze
from crosstab('select nop.region as cntry,op.games,op.medal,count(op.medal) as medals
			from olympics op
			join noc_olympics nop on op.noc=nop.noc and (op.medal<>''NA'')
			group by op.games,nop.region,op.medal
			order by op.games',
			'values (''Bronze''), (''Gold''), (''Silver'')') 													-- THIS LINE IS IMPORTANT
		as tabl3 (country varchar,game varchar, bronze bigint,gold bigint, silver bigint )
		

/* -- To check the solution
select medal
from olympics as op
join noc_olympics as nop on op.noc=nop.noc and op.games='1948 Summer' and nop.region='South Africa' and op.medal='Gold'
*/

	
--16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.

		-- SUB QUERY for crosstab
select op.games,nop.region as country,op.medal, count(*) +1
from olympics op
join noc_olympics nop on op.noc=nop.noc and op.medal<>'NA'
group by op.games,country,op.medal
order by op.games--,country,op.medal


with result as(	
select games,country,coalesce(Bronze,0) bronze,coalesce(Gold,0) gold,coalesce(Silver,0) silver--, (bronze + gold + silver )as ttl
from crosstab
('select nop.region as country,op.games,op.medal, (count(*))
from olympics op
join noc_olympics nop on op.noc=nop.noc and op.medal<>''NA''
group by op.games,country,op.medal
order by op.games,country,op.medal',
'values (''Bronze''),(''Gold''),(''Silver'')')
as tabl3(country text,games varchar,Bronze bigint,Gold bigint,Silver bigint)   )

select distinct games,
	(first_value(country) over x || ' - ' || first_value(bronze) over x ) as Max_Bronze,
	(first_value(country) over y || ' - ' || first_value(gold ) over y ) as Max_Gold ,
	(first_value(country) over z || ' - ' || first_value(silver ) over z ) as Max_Silver  
from result
window x as (partition by games order by bronze desc ),
	   y as (partition by games order by gold desc ),
	   z as (partition by games order by silver desc )
order by games
	
--where result.games='1900 Summer'

	
--17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

	-- SUB QUERY for crosstab
select op.games,nop.region as country,op.medal, count(*)
from olympics op
join noc_olympics nop on op.noc=nop.noc and op.medal<>'NA'
group by op.games,country,op.medal
order by op.games--,country,op.medal


with result as(
select games,country,coalesce(Bronze,0) bronze,coalesce(Gold,0) gold,coalesce(Silver,0) silver
from crosstab
('select nop.region as country,op.games,op.medal, (count(*))
from olympics op
join noc_olympics nop on op.noc=nop.noc and op.medal<>''NA''
group by op.games,country,op.medal
order by op.games,country,op.medal',
'values (''Bronze''),(''Gold''),(''Silver'')')
as tabl3(country text,games varchar,Bronze bigint,Gold bigint,Silver bigint)   ),
	tot_medals as(
	select nop.region,op.games,count(*) as cnt
	from olympics op
	join noc_olympics nop on op.noc=nop.noc and op.medal<>'NA'
	group by nop.region	,op.games
	order by op.games
	)

select distinct r.games,
	concat(first_value(country) over x ,' - ',first_value(bronze) over x ) as Max_Bronze,
	concat(first_value(country) over y ,' - ',first_value(gold ) over y ) as Max_Gold ,
	concat(first_value(country) over z ,' - ',first_value(silver ) over z ) as Max_Silver,
	concat(first_value(country) over (partition by m.games order by m.cnt desc ),' - ',first_value(m.cnt ) over (partition by m.games order by m.cnt  desc )) as Max_medals
from result r
join tot_medals m on r.games=m.games and r.country=m.region
window x as (partition by r.games order by bronze desc ),
	   y as (partition by r.games order by gold desc ),
	   z as (partition by r.games order by silver desc )
order by r.games

	--- OR 

with result as(
select games,country, coalesce(Bronze,0) bronze,
	coalesce(Gold,0) gold, coalesce(Silver,0) silver,
	( coalesce(Bronze,0)+coalesce(Gold,0)+coalesce(Silver,0) )as ttl
from crosstab
('select nop.region as country,op.games,op.medal, (count(*))
from olympics op
join noc_olympics nop on op.noc=nop.noc and op.medal<>''NA''
group by op.games,country,op.medal
order by op.games,country,op.medal',
'values (''Bronze''),(''Gold''),(''Silver'')')
as tabl3(country text,games varchar,Bronze bigint,Gold bigint,Silver bigint)   )

select distinct games,
	concat(first_value(country) over x ,' - ',first_value(bronze) over x ) as Max_Bronze,
	concat(first_value(country) over y ,' - ',first_value(gold ) over y ) as Max_Gold ,
	concat(first_value(country) over z ,' - ',first_value(silver ) over z ) as Max_Silver,
	concat(first_value(country) over a ,' - ',first_value(ttl ) over a ) as Max_medals
from result
--join tot_medals m on r.games=m.games and r.country=m.region
window x as (partition by games order by bronze desc ),
	   y as (partition by games order by gold desc ),
	   z as (partition by games order by silver desc ),
	   a as (partition by games order by ttl desc )
order by games


--18. Which countries have never won gold medal but have won silver/bronze medals?


select country,coalesce(gold,0) as gold,coalesce(silver,0) as silver,coalesce(bronze,0) as bronze
from crosstab('select nop.region as cntry,op.medal,count(*) as cnt
from olympics op
join noc_olympics nop on op.noc=nop.noc and (op.medal=''Silver'' or op.medal=''Bronze'')
group by cntry,op.medal',
'values (''Bronze''),(''Silver''),(''Gold'')')
as tabl3(country varchar,bronze bigint,silver bigint,gold bigint)
order by country--silver,bronze desc


/*	-- To check the Solution
select nop.region as cntry,op.medal,count(*) as cnt
from olympics op
join noc_olympics nop on op.noc=nop.noc and (op.medal='Silver' or op.medal='Bronze') and nop.region='Sri Lanka'
group by cntry,op.medal

select medal
from olympics op
join noc_olympics nop on op.noc=nop.noc and (op.medal<>'NA') and nop.region='Namibia'
*/
	

--19. In which Sport/event, India has won highest medals.

	
select op.sport,count(nop.region) as medals
from olympics op
join noc_olympics nop on op.noc=nop.noc and nop.region='India' and op.medal<>'NA'
group by op.sport
order by medals desc
limit 1


--20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

	
select op.sport,op.games,count(nop.region) as medals
from olympics op
join noc_olympics nop on op.noc=nop.noc and nop.region='India' and op.medal<>'NA' and op.sport='Hockey' 
group by op.sport,op.games--,op.medal
order by medals desc


/*  IGNORE
select country,coalesce(gold,0)+1 as gold,coalesce(silver,0) as silver,coalesce(bronze,0) as bronze
from crosstab('select nop.region as cntry,op.medal,count(*) as cnt
from olympics op
join noc_olympics nop on op.noc=nop.noc and (op.medal<>''NA'')
group by cntry,op.medal',
'values (''Bronze''),(''Silver''),(''Gold'')')
as tabl3(country varchar,bronze bigint,silver bigint,gold bigint)
where */