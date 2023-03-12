/*
creating tables for tableau visualization
*/

-- Top 5 most active director and the country 

select top 5 director , country , count(*) as NumberOfShows
from netflix
where director not like 'not given'
group by director , country
order by NumberOfShows desc

-- most dominant country

select country , count(*) as NumberOfShow
from netflix
where country not like 'not given'
group by country
order by NumberOfShow desc

-- Most dominant category. 

with categories as (
select case when PATINDEX('% %' , value) = 1 then SUBSTRING(value, 2 , len(value))
			else value end as category
from netflix
cross apply string_split(listed_in , ',')
) select category , count(*) as NumberOfShows
from categories
group by category
order by NumberOfShows desc


-- distribution of type of each country, does countries have specialization in movie or tv show?

with CountryType as (
select country , type , count(*) as NumberOfShows
from netflix
group by country , type
) select * , round(cast(NumberOfShows as float)/(sum(NumberOfShows) over (partition by country)),3) as TypeRate
from CountryType
order by country , type


-- Trending categories

with CategoriesDate as (
select date_added ,case when PATINDEX('% %' , value) = 1 then SUBSTRING(value, 2 , len(value))
			else value end as category
from netflix
cross apply string_split(listed_in , ',')
) select date_added , category, count(*) as NumberOfShows
from CategoriesDate
group by category , date_added
order by NumberOfShows desc


-- Average duration of show/movie for each category

with CategoriesDuration as (
select type , cast(case when duration like '%min%' then REPLACE(duration , 'min' ,'') 
						   when duration like '%Seasons%' then REPLACE(duration , 'Seasons' , '')
						   when duration like '%Sea%' then REPLACE(duration , 'Season' , '')
						   end as int) as duration , 
			case when PATINDEX('% %' , value) = 1 then SUBSTRING(value, 2 , len(value))
			else value end as category
from netflix
cross apply string_split(listed_in , ',')
) select type , category , AVG(duration) as AverageDuration
from CategoriesDuration
group by type , category
order by AverageDuration desc