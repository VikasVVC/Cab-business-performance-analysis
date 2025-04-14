select *from dim_city
select *from fact_trips
select *from dim_repeat_trip_distribution
select *from dim_date

--Top 3 and bottom 3 cities by total trips over the entire analysis period.
select top 3 a.city_name, count(b.trip_id) as total_trips from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
group by a.city_name
order by total_trips desc

select top 3 a.city_name, count(b.trip_id) as total_trips from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
group by a.city_name
order by total_trips asc

-- Avg fare per trip per km by city
select top 1 a.city_name, (sum(b.fare_amount*1.0)/sum(b.distance_travelled_km)) as avg_fare_per_km_by_city from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
group by a.city_name
order by avg_fare_per_km_by_city desc

select top 1 a.city_name, (sum(b.fare_amount*1.0)/sum(b.distance_travelled_km)) as avg_fair_per_km_by_city from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
group by a.city_name
order by avg_fair_per_km_by_city asc

--Avg ratings by city and passenger type
--ALTER TABLE fact_trips
--ALTER COLUMN passenger_rating int
select top 1 a.city_name, avg(b.passenger_rating*1.0) as avg_passenger_rating  from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
where b.passenger_type = 'new'
group by a.city_name
order by avg_passenger_rating desc

select top 1 a.city_name, avg(b.passenger_rating*1.0) as avg_passenger_rating  from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
where b.passenger_type = 'new'
group by a.city_name
order by avg_passenger_rating asc

select top 1 a.city_name, avg(b.passenger_rating*1.0) as avg_passenger_rating  from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
where b.passenger_type = 'repeated'
group by a.city_name
order by avg_passenger_rating desc

select top 1 a.city_name, avg(b.passenger_rating*1.0) as avg_passenger_rating  from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
where b.passenger_type = 'repeated'
group by a.city_name
order by avg_passenger_rating asc

-- Peak and low demand months by city
with cte as (select a.city_name, datepart(month,date) as month , count(b.trip_id) as total_trips_in_month  from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
group by a.city_name , datepart(month,date))

, cte1 as (select city_name, month, total_trips_in_month,dense_rank() over(partition by city_name order by total_trips_in_month desc) as rnk
from cte)

, cte4 as (select city_name, month as peak_demand_month  from cte1
where rnk  = 1 )

, cte2 as (select a.city_name, datepart(month,date) as month , count(b.trip_id) as total_trips_in_month  from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
group by a.city_name , datepart(month,date))

, cte3 as (select city_name, month, total_trips_in_month,dense_rank() over(partition by city_name order by total_trips_in_month asc) as rnk
from cte2)

, cte5 as (select city_name, month as lowest_demand_month  from cte3
where rnk  = 1)

select a. city_name , a.peak_demand_month, b.lowest_demand_month
from cte4 as a
inner join cte5 as b
on a.city_name = b.city_name


-- Weekday vs Weekend trip demand by city
with cte as (select a.city_name, datepart(month,b.date)as month ,DATEPART(weekday,b.date) as weekday, count(b.trip_id) as trips from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
group by a.city_name, datepart(month,b.date),DATEPART(weekday,b.date)
having datepart(month,b.date) between 1 and 6 and DATEPART(weekday,b.date) between 2 and 6 )
--order by datepart(month,date), DATEPART(weekday,date))

, cte1 as (select city_name, month, sum(trips) as total_weekdays_trips
from cte
group by city_name,month)

, cte2 as (select a.city_name, datepart(month,b.date)as month ,DATEPART(weekday,b.date) as weekday, count(b.trip_id) as trips from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
group by a.city_name, datepart(month,b.date),DATEPART(weekday,b.date)
having datepart(month,b.date) between 1 and 6 and DATEPART(weekday,b.date) = 1 or DATEPART(weekday,b.date) = 7 )
--order by datepart(month,date), DATEPART(weekday,date))

,cte3 as (select city_name, month, sum(trips) as total_weekends_trips
from cte2
group by city_name,month)

select a.city_name, a.month,a.total_weekdays_trips,b.total_weekends_trips from 
cte1 as a
inner join cte3 as b
on a.city_name = b.city_name and a.month = b.month

--Repeat passenger frequency and city contribution analysis 
with cte as (select a.city_name, b.trip_count , sum(b.repeat_passenger_count) as total_repeat_passeneger_count from 
dim_city as a
inner join dim_repeat_trip_distribution as b
on a.city_id = b.city_id
group by a.city_name, b.trip_count)

, cte1 as (select a.city_name, sum(b.repeat_passenger_count) as total_repeat_passeneger_count from 
dim_city as a
inner join dim_repeat_trip_distribution as b
on a.city_id = b.city_id
group by a.city_name)

select x.city_name,x.trip_count, cast(x.total_repeat_passeneger_count*100.0/y.total_repeat_passeneger_count as decimal(10,2)) as percentage_contribution_to_total_trips
from cte as x
inner join cte1 as y
on x.city_name = y.city_name
order by x.city_name



-- Whether Targets met 
-- trips
with cte as (select a.city_name, datepart(month,date) as month , a.city_id,count(b.trip_id) as total_trips_in_month  from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
group by a.city_name , datepart(month,date), a.city_id)

, cte1 as (select a.city_name, a.month, a.total_trips_in_month, b.total_target_trips 
from cte as a
inner join monthly_target_trips as b
on a.city_id = b.city_id and a.month = datepart(month,b.month))

, cte2 as (select *, ((total_trips_in_month-total_target_trips)*100.0/total_trips_in_month) as percentage_diff,case when total_target_trips > total_trips_in_month then 0 else 1 end as whether_target_met
from cte1)

SELECT city_name
FROM cte2
GROUP BY city_name
HAVING count(distinct (whether_target_met)) = 1

-- Targets met by : Jaipur(tourist),Lucknow(tourist+business), Mysore(tourist), Vadodra(business)

-- passenegers

with cte as (select a.city_name, datepart(month,b.month) as month , a.city_id,sum(b.new_passengers) as new_passengers  from 
dim_city as a
inner join fact_passenger_summary as b
on a.city_id = b.city_id
group by a.city_name , datepart(month,b.month), a.city_id)


, cte1 as (select a.city_name, a.month, a.new_passengers, b.target_new_passengers
from cte as a
inner join monthly_target_new_passengers as b
on a.city_id = b.city_id and a.month = datepart(month,b.month))

, cte2 as (select *, ((new_passengers-target_new_passengers)*100.0/new_passengers) as percentage_diff,case when target_new_passengers > new_passengers then '0' else '1' end as whether_target_met
from cte1)

SELECT city_name
FROM cte2
GROUP BY city_name
HAVING count(distinct (whether_target_met)) = 1

-- Targets met by : Coimbatore(business+tourist), Indore(business)

-- rating

with cte as (select a.city_name , a.city_id,avg(b.passenger_rating*1.0) as avg_passenger_rating  from 
dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
group by a.city_name , a.city_id)


, cte1 as (select a.city_name, a.avg_passenger_rating, b.target_avg_passenger_rating
from cte as a
inner join city_target_passenger_rating as b
on a.city_id = b.city_id)

, cte2 as (select *,((avg_passenger_rating-target_avg_passenger_rating)*100.0/avg_passenger_rating) as percentage_diff ,case when target_avg_passenger_rating > avg_passenger_rating then 0 else 1 end as whether_target_met
from cte1)

SELECT city_name
FROM cte2
GROUP BY city_name
HAVING count(distinct (whether_target_met)) = 1

-- Targets met by : all cities

--Highest and lowest repeat passenger rate by city and month
select top 2 a.city_name, DATEPART(month,b.month) as month, 
avg((b.repeat_passengers*100.0/b.total_passengers)) as avg_repeat_passenger_percentage
from dim_city as a
inner join fact_passenger_summary as b
on a.city_id = b.city_id
group by a.city_name, DATEPART(month,b.month)
order by avg_repeat_passenger_percentage desc


select top 2 a.city_name, DATEPART(month,b.month) as month, 
avg((b.repeat_passengers*100.0/b.total_passengers)) as avg_repeat_passenger_percentage
from dim_city as a
inner join fact_passenger_summary as b
on a.city_id = b.city_id
group by a.city_name, DATEPART(month,b.month)
order by avg_repeat_passenger_percentage asc

-- Factors influencing passenger_rates
with cte as (select a.city_name, avg((b.repeat_passengers*100.0/b.total_passengers)) as avg_repeat_passenger_rate
from dim_city as a
inner join fact_passenger_summary as b
on a.city_id = b.city_id
group by a.city_name)
,
cte1 as (select a.city_name, 
avg(b.fare_amount*1.0/b.distance_travelled_km) as avg_trip_rate, avg(passenger_rating*1.0) as avg_passenger_rate
from dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id
group by a.city_name, b.passenger_type
having passenger_type = 'repeated')

select a.city_name , a.avg_repeat_passenger_rate, b.avg_passenger_rate, b.avg_trip_rate
from cte as a
inner join cte1 as b
on a.city_name = b.city_name
order by a.avg_repeat_passenger_rate desc

-- Reasons: low avg trip rate(except Indore), Surat : toursit places, business hub, less cost of living 

-- Tourism month trips
with cte as (select a.city_name, count(b.trip_id) as total_trips
from dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id 
group by a.city_name, datepart(month,b.date)
having datepart(month,b.date) between 1 and 3
)

, cte1 as (select city_name, sum(total_trips) as trips_1_3
from cte
group by city_name)

,cte2 as (select a.city_name, count(b.trip_id) as total_trips
from dim_city as a
inner join fact_trips as b
on a.city_id = b.city_id 
group by a.city_name, datepart(month,b.date)
having datepart(month,b.date) between 4 and 6
)

, cte3 as (select city_name, sum(total_trips) as trips_4_6
from cte2
group by city_name)

select a.city_name, a.trips_1_3, b.trips_4_6 
, case when a.trips_1_3 > b.trips_4_6 then 'yes' else 'no' end as seasonal_influence_flag
from cte1 as a
inner join cte3 as b
on a.city_name = b.city_name

--Emerging mobility trends and Goodcabs adaptation
1. Electric vehicles : making signifcant 
2. Buses(public transportation)
3. Electric autos
4. Metro (VSKP)

-- Partnerships opportunities with local businesses 
Yes , there are certainly new opportunities 
reasons
1. develpoment hubs : VSKP - tourism, IT companies, pharma, manufacturing etc. : increased transportation -> need of more cab services 
2. Less traffic : people like to enjoy more in such places and hence will be travelling more : new hotels come up -> increased transportation -> need of more cab services
3. Comparitively good environemnt and less cost of living 

Chances of traffic:
1. Yes , there will be increased chances of traffic but with small car sizes and route optimization this problem can be tackled


Data collection for enhanced data-driven decisions
1. Routes which give higher fuel efficiency : less traffic , higher mileage, saves more time
2. Additional feedback from customer: about comfort etc.
3. Cab feedback : to reduce operational costs
4. Most travelled routes so that more cabs can be deployed 
5. To improve driver's rating we can provide them breaks, etc based on their feedback