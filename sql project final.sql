create database imdb_sql_proj_try;
use imdb_sql_proj_try;
######Segment 1: Database - Tables, Columns, Relationships #####
   ## B-total number of rows in each table of the schema.
select count(*) from director_mapping;
select count(*) from genre;
select count(*) from movies;
select count(*) from names;
select count(*) from ratings;
select count(*) from role_mapping;

select* from movies;

    ## C-Identify which columns in the movie table have null values.
select id from movies where id is null;
select title from movies where title is null;
select year from movies where year is null;
select date_published from movies where date_published is null;
select duration from movies where duration is null;
select country from movies where country is null;
select worlwide_gross_income from movies where worlwide_gross_income is null;
select languages from movies where languages is null;
select production_company from movies where production_company is null;

######Segment 2: Movie Release Trends#####
## A-Determine the total number of movies released each year and analyse the month-wise trend.
select
year, count(*) as number_of_movies
from movies
group by year;

## B- analyse month wise trend.
    ##converting date_published into date formate to make this into month
select month(date_published) as month,
count(*) as number_of_movies from movies
group by month(date_published)
order by month;

  ## C--Calculate the number of movies produced in the USA or India in the year 2019. 
  select count(*) from movies
  where year = 2019 and
  lower(country) like "%usa%" or
  lower(country) like "india";
  
  ######Segment 3: Production Statistics and Genre Analysis######
  ## A- -	Retrieve the unique list of genres present in the dataset.
  select distinct genre from genre;
  
  ## B- -	Identify the genre with the highest number of movies produced overall.
  select genre, count(movie_id) as movie_count
  from genre
  group by genre
  order by movie_count desc
  limit 1;
  
  ## C--	Determine the count of movies that belong to only one genre.
  select count(*) from
  (select movie_id, count(genre) as no_of_genres
  from genre
  group by movie_id
  having no_of_genres = 1) t;
  # 3289 movies belongs to only one genre.
  
  ##D--	Calculate the average duration of movies in each genre.
  select g.genre,  avg(m.duration) as avg_duration from movies m
  right join genre g on g.movie_id = m.id
  group by g.genre
  order by 2;
  
  ##E--	Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced.
  select genre, no_of_movies,
  rank() over(order by no_of_movies desc) as rnk from
  (select genre, count(movie_id) as no_of_movies
  from genre
  group by genre) t;

  #############################or#########################
 select * from
 (select genre, count(movie_id) as no_of_movies,
  rank() over(order by count(movie_id) desc) as genre_rnk
  from genre
  group by genre) t
  where genre = 'thriller';
  # so the rank of thriller is 3
  
  ######Segment 4: Ratings Analysis and Crew Members######
  ##A--	Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).
select
min(avg_rating) AS minimum_avg_rating,
max(avg_rating) AS maximum_avg_rating,
min(total_votes) AS minimum_total_votes,
max(total_votes) AS maximum_total_votes,
min(median_rating) AS minimum_median_rating,
max(median_rating) AS maximum_median_rating
from ratings;

## B--	Identify the top 10 movies based on average rating.
  select m.title,
avg(r.avg_rating) as average_rating
from movies m join ratings r on m.id = r.movie_id
GROUP BY m.title
ORDER BY average_rating DESC
LIMIT 10;

##C-- Summarise the ratings table based on movie counts by median ratings.

select median_rating,
count(movie_id)
from ratings
group by median_rating
order by median_rating;

##D--	Identify the production house that has produced the most number of hit movies (average rating > 8).
select production_company, count(id) as number_of_movies,
rank() over(order by count(id) desc) as cnt
from movies m
join ratings r on m.id = r.movie_id
where avg_rating > 8 and production_company is not null
group by production_company
order by number_of_movies desc;

##E--	Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.
SELECT g.genre,
COUNT(DISTINCT m.id) AS movie_count
FROM movies m
JOIN genre g ON m.id = g.movie_id
JOIN ratings r ON m.id = r.movie_id
WHERE m.country = 'USA' AND m.year = 2017
AND MONTH(m.date_published) = 3
AND r.total_votes > 1000
GROUP BY g.genre
ORDER BY movie_count DESC;

##F--	Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.
select m.title,r.avg_rating,g.genre
from movies m
join ratings r on m.id=r.movie_id
join genre g on m.id=g.movie_id
where m.title like "The%" and r.avg_rating > 8;

########################Segment 5: Crew Analysis######################
##A--	Identify the columns in the names table that have null values.
select count(*) from names where id is null;
select count(*) from names where name is null;
select count(*) from names where height is null;
select count(*) from names where date_of_birth is null;
select count(*) from names where known_for_movies is null;
#no null value in above names table.
##B--	Determine the top three directors in the top three genres with movies having an average rating > 8.
 with top_genre as
 (select genre, count(g.movie_id) as total_movies
 from genre g
 inner join ratings r on r.movie_id = g.movie_id
 where avg_rating > 8
 group by genre
 order by total_movies desc limit 3)
 select
 n.name as top_directors, count(m.id) as movie_count
 from names n
inner join director_mapping dm  on dm.name_id = n.id
inner join movies  m on m.id = dm.movie_id
inner join genre g on g.movie_id = m.id
inner join ratings r on r.movie_id = m.id
where avg_rating > 8 and genre in(select genre from top_genre)
group by 1
order by movie_count desc
limit 3;
#james mangold can be hired as the director, since he has the most success ate.



##C--	Find the top two actors whose movies have a median rating >= 8.
select n.name as actor_name, count(m.id) as movie_count
from
names n
inner join role_mapping rm on rm.name_id = n.id
inner join movies m on m.id = rm.movie_id
inner join ratings r on r.movie_id = m.id
where median_rating >= 8 and category = 'actor'
group by 1
order by movie_count desc limit 2;

##D--	Identify the top three production houses based on the number of votes received by their movies.
select production_company, sum(total_votes) as votes from movies m
join ratings r on m.id = r.movie_id
where production_company is not null
group by production_company
order by votes desc limit 3;
# marvel is the top production house.


##E--	Rank actors based on their average ratings in Indian movies released in India.
with actr_avg_rating as
(select n.name as actor_name,
sum(r.total_votes) as total_votes,
count(m.id) as movie_count,
round(sum(r.avg_rating*r.total_votes) / sum(r.total_votes), 2) as actor_avg_rating
from names as n
inner join role_mapping as a on n.id = a.name_id
inner join movies as m on a.movie_id = m.id
inner join ratings as r on n.id = r.movie_id
where category = 'actor' and lower(country) like "%india%"
group by actor_name)

select actor_name from actr_avg_rating
order by actor_avg_rating desc
limit 1;

##F--	Identify the top five actresses in Hindi movies released in India based on their average ratings.
(select n.name as actress_name,
sum(r.total_votes) as total_votes,
count(m.id) as movie_count,
round(sum(r.avg_rating*r.total_votes) / sum(r.total_votes), 2) as actress_avg_rating
from names as n
inner join role_mapping as a on n.id = a.name_id
inner join movies as m on a.movie_id = m.id
inner join ratings as r on n.id = r.movie_id
where category = 'actress' and lower(languages) like "%hindi%"
group by actress_name)


##################Segment 6: Broader Understanding of Data################
##A--	Classify thriller movies based on average ratings into different categories.
-- [rating > 8: superhit
-- rating between 7 and 8 : hit
-- rating between 5 and 7 : one timr watch
-- rating < 5 : flop]
-- total_votes > 25000;

select
m.title as  movie_name,
case
when r.avg_rating > 8 then 'superhit'
when r.avg_rating between 7 and 8 then 'hit'
when r.avg_rating between 5 and 7 then 'one time watch'
else 'flop'
end as movie_category
from movies m
left join ratings as r on m.id = r.movie_id
left join genre as g on m.id = g.movie_id
where lower(genre) = 'thriller'
and total_votes > 25000;
##B--	analyse the genre-wise running total and moving average of the average movie duration.
with genre_summary as
(select genre, avg(duration) as avg_duration
from genre g
left join movies m on g.movie_id = m.id
group by genre)

select genre, avg_duration,
sum(avg_duration) over(order by avg_duration desc) as running_total,
avg(avg_duration) over(order by  avg_duration desc) as moving_average
from genre_summary;
##C--	Identify the five highest-grossing movies of each year that belong to the top three genres.
with top_genre as
(select genre, count(m.id) as movie_count
from  genre g
left join movies m on g.movie_id= m.id
group by genre
order by movie_count desc
limit 3)
select * from
(select genre, year, m.title as movie_name,
worlwide_gross_income,
rank() over(partition by genre, year order by
cast(replace(trim(worlwide_gross_income), "$", "") as unsigned)
desc) as movie_rank
from movies m
inner join genre g on g.movie_id = m.id
where g.genre in (select genre from top_genre)) t
where movie_rank <= 5
##D--	Determine the top two production houses that have produced the highest number of hits among multilingual movies.
-- no. of hits among multilangual movies.
-- hit movies - mrdian rating > 8.
select m.production_company,
count(m.id) as movie_count,
rank() over(order by count(m.id) desc) as prod_rank
from movies m left join ratings r on r.movie_id = m.id
where m.production_company is not null and median_rating > 8
and languages like "%,%"
group by 1
limit 2;
##E--	Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.

with actr_avg_rating as
(select n.name as actress_name,
sum(r.total_votes) as total_votes,
count(m.id) as movie_count,
round(sum(r.avg_rating*r.total_votes) / sum(r.total_votes), 2) as actress_avg_rating
from names as n
inner join role_mapping as a on n.id = a.name_id
inner join movies as m on a.movie_id = m.id
inner join ratings as r on m.id = r.movie_id
inner join genre as g on g.movie_id = m.id
where category = 'actress' and lower(genre) like "%drama%" and avg_rating > 8
group by actress_name)

select *,
row_number() over(order by actress_avg_rating desc, total_votes desc) as actress_rank
from actr_avg_rating
limit 3



##F--	Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.

with top_directors as
(select director_id, director_name  from
(select n.id as director_id, n.name as director_name,
count(m.id) as movie_count,
row_number() over(order by count(m.id) desc) as director_rank
from names n
inner join director_mapping d on n.id = d.name_id
inner join movies m on m.id = d.movie_id
group by 1,2) t
where director_rank <=9),
movie_summary as(
select n.id as director_id, n.name as director_name,
m.id as movie_id,
r.avg_rating,
r.total_votes,
m.duration,
m.date_published,
lead(date_published) over(partition by n.id order by m.date_published) as next_date_published,
datediff(lead(date_published) over(partition by n.id order by m.date_published), m.date_published) as inter_movie_days
from names n
inner join director_mapping d on n.id = d.name_id
inner join movies m on m.id = d.movie_id
inner join ratings r on r.movie_id = m.id
where n.id in (select director_id from top_directors))
select director_id,
director_name,
count(distinct movie_id) as number_of_movies,
avg(inter_movie_days) as avg_inter_movie_days,
round(sum(avg_rating*total_votes) / sum(total_votes),2) as directors_avg_rating,
sum(total_votes) as total_votes,
min(avg_rating) as min_rating,
max(avg_rating) as max_rating,
sum(duration) as total_movie_duration
from movie_summary
group by 1,2
order by number_of_movies desc, directors_avg_rating desc;
##################Segment 7: Recommendations########################
##A--	Based on the analysis, provide recommendations for the types of content Bolly movies should focus on producing.

#AS THE PER MY ANALYSIS I CAME ACROSS A.L. VIJAY IS THE TOP DIRECTOR AS PER PUBLIC RATING  IF THE BOLLY MOVIES WANTS HITS BY PUBLIC PULSE THEY SHOULD AQUIRE KNOWLEDGE ON CONTENT ON  VIJAY MOVIES.Chiris Hemsworth, Robert Downey ,CHiris evans are the top three directors in top genres with movie count 12 
 
#>>COMINING TO PRODUCTION HOUSES Star cinema and Ave Fenix Pictures GAVE MORE HITS CAMPARE TO  THE OTHERS AS THEY ARE TOP PRODUCTION HOUSES IN MULTILANGAL SO THAT THEY WILL INTERSSTED IN PRODUCING  MORE BOLLY MOVIES.

#>>IF BOLLY MOVIES COME UP WITH ACTION ,DRAMA, COMEDY GENRE  IT WILL DEFINITELY ENTERTAIN AS THEY ARE TOP GENRES PEOPLE ARE MORE INTERESTED IN THESE GENRES COMPARATIVELY BEFORE 

#>> IN HINDI MOVIES TOP ACTRESSES WHO HITS OR ENTERTAIN PEOPLE BY THEIR PERFORMANCE ARE taapsee pannu , kriti sanon, divya dutta, Sradda Kapoor,Krithi karbanda. WITH ANY OF THOSE ACTRESSES WILL HIT SOON THE INDUSTRY.
  
  ##>>> IN INDIAN MOVIES VIJAY SEYHUPAYHI RANKED AS NUMBER ONE AND ALSO MOHAN LAL AND MAMMOTTY ARE ALSO TOP ACTORS BASED ON THEIR MEDIAN RATINGS . WE CAN CONSIDER THESE ACTORS WILL BOX OFFICES IN BOLLY MOVIES
       
####FINALLY #I CAME INTO MY CONCLUSIOn COBMINATION OF ABOVE ACTORS AND ACTRESESS AND DIRECTORS AND PRODUCTION HOUSES IN TOP GENRES WILL ENTERTAIN MORE

