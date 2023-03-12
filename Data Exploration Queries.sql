/*
the data consist of contents added to Netflix from 2008 to 2021. 
The oldest content is as old as 1925 and the newest as 2021.

kaggle link - https://www.kaggle.com/datasets/ariyoomotade/netflix-data-cleaning-analysis-and-visualization
*/


/*
Skills used: Multiple CTE's, Subqueries, Aggregate functions, Update table, Convert and cast, Multiple string functions,
Dates calculation, Cross apply, Case when statments
*/

/*
Showing the data: Show_id - unique id for each title. type - either a movie or TV show
				  title - the title of the show/movie. director - the name of the director of the show/movie.
				  country - at which country the show/movie was made. date_added - the date the show/movie
				  added to netflix. release_year - in what year the show/movie was released.
				  rating - age rating. duration - the duration of the show/movie, where if it was a show
				  it is listed how many seasons, and for a movie how long the movie in minutes.
				  listed_in - the category of the show/movie.			
*/


select *
from netflix

-- Checking show_id Duplicates: Result - No duplicates

select count(show_id)
from netflix
group by show_id
having count(show_id) = 2

-- changing the date_added from varchar to date format

update netflix
set date_added = CONVERT(date , date_added, 105)

-- 1-VARIATE ANALYSIS

-- distribuion of type in netflix. Result: 6126 movies, 2664 TV shows, 69.7% movies and 30.3% TV shows

with typetable as (
select type , count(*) as NumberOfShows
from netflix
group by type
) select * , round(cast(NumberOfShows as float) / (select sum(NumberOfShows) from typetable) , 3)
from typetable

-- Most active director 

select director , count(*) as NumberOfShows
from netflix
group by director
order by NumberOfShows desc

/*
Does netflix upload a bulk of shows/movies each day? Results: about 10% of date_added have 10 or more shows/movies
that were added, and over 50% have 2 or more. this suggest that netflix rarely adding only 1 show/movie in a day.
*/

select date_added , count(*) as NumberOfShows
from netflix
group by date_added
order by NumberOfShows desc


-- most dominant country. Results: as expected usa at the top, together with india and uk. pakistan in fourth

select country , count(*) as NumberOfShow
from netflix
group by country
order by NumberOfShow desc


-- Most dominant category. Results: international movies takes number 1 with 2752 movies, followed by dramas and comedies

with categories as (
select case when PATINDEX('% %' , value) = 1 then SUBSTRING(value, 2 , len(value))
			else value end as category
from netflix
cross apply string_split(listed_in , ',')
) select category , count(*) as NumberOfShows
from categories
group by category
order by NumberOfShows desc

-- MULTIVARIATE ANALYSIS
/*
distribution of type of each country, does countries have specialization in movie or tv show?
Results: most of the countries have more movies than tv
*/

with CountryType as (
select country , type , count(*) as NumberOfShows
from netflix
group by country , type
) select * , round(cast(NumberOfShows as float)/(sum(NumberOfShows) over (partition by country)),3) as TypeRate
from CountryType
order by country , type

-- Trending countries, for date_added see the number of shows/movies added for each country

select country ,  date_added , count(*) as NumberOfShows
from netflix
group by country , date_added
order by country

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

/*
How long does a show/movie need to wait until added to netflix per type and counry. year difference betweern
year realsed and date_added.
*/

select country , type ,  round(avg(year(date_added) - release_year),2) as AverageYearDiff
from netflix
group by country, type
order by AverageYearDiff desc

/*
Directors who make movies for different audience - which director makes mosly kids content or adult content
for directors who made atleast 5 contents
*/

select director , rating , count(*) as NumberOfShows 
from netflix
where director in (select director from netflix group by director having count(*) >= 5)
group by director , rating
order by director

-- Rating distribution by country

with CountryRating as (
select country , rating , count(*) as NumberOfShows
from netflix
group by country , rating
) select * , round(cast(NumberOfShows as float)/(sum(NumberOfShows) over(partition by country)),3) as RatingRate
from CountryRating