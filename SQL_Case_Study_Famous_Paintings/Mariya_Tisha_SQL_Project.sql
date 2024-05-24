-- Database Creation
create database painting;
use painting;

-- 1. Fetch all the paintings which are not displayed on any museums?
	-- work table has all painting names listed, so paintings with no museum_id is the target
    select name as list_of_paintings_not_displayed
    from work
    where museum_id is null;

-- 2. Are there museums without any paintings?
	-- musueam table lists all musuems, work - all paintings.  
    -- first checked if any museum is listed in the work table,if so return 1
    -- if not 1, that is the museum with no paintings, returned its names
    select m.name as Museums_with_no_paintings
    from museum as m
    where not exists (select 1 
                      from work as w
                      where w.museum_id = m.museum_id);

-- 3. How many paintings have an asking price of more than their regular price?
	-- The product_size table lists this information
    -- checked where sale_price > regular price, return the count of (unique)paintings
    select count(distinct p.work_id) as number_of_paintings_with_higher_asking_price
    from product_size as p
    where p.sale_price > p.regular_price;


-- 4. Identify the paintings whose asking price is less than 50% of its regular price
	-- selected work_id from product_size table where sale_price = (0.5 * regular_price)
    -- listed the names and id of those paintings
    select w.work_id as id, w.name as painting_name
    from work as w
    where exists (select 1
				  from product_size as p
                  where p.sale_price < (0.5 * p.regular_price));
                  
                  
-- 5. Which canva size costs the most?
	-- there are multiple instances of the size_id in product_size table
    -- unique ones are present in the canvas_size table
    -- used a table which is the inner join of both, then calculated the sum of sale_price(since multiple isntances of same canvas size,with different price points)
    -- grouped it on size_id,label and returned the result
    select c.size_id, c.label as size_specifics,sum(p.sale_price) as total_sale_price
    from product_size as p inner join canvas_size as c on p.size_id = c.size_id 
    group by c.size_id,c.label
    order by total_sale_price DESC 
    limit 1;
    
-- 6. Delete duplicate records from work, product_size, subject and image_link tables
	-- a unique identifier was added for each table, identified the duplicated columns and deleted only one of them using max(id)
    -- row_number() over (partition by) was used to identify the duplicated columns 
	-- work
    SET SQL_SAFE_UPDATES = 0;
    delete from work
    where id in(
				select id
                from(
					select *,row_number() over (partition by work_id) as rn
                    from work) as x
				where x.rn>1);
	-- product_size
    delete from product_size
    where id in(
				select id
                from(
					select *,row_number() over (partition by work_id,size_id) as rn
                    from product_size) as x
				where x.rn>1);
	-- subject
	delete from subject
    where id in(
				select id
                from(
					select *,row_number() over (partition by work_id,subject) as rn
                    from subject) as x
				where x.rn>1);
	-- image_link
    delete from image_link
    where id in(
				select id
                from(
					select *,row_number() over (partition by work_id) as rn
                    from image_link) as x
				where x.rn>1);
    SET SQL_SAFE_UPDATES = 1;

-- 7. Identify the museums with invalid city information in the given dataset
	-- there are inconsistencies in the city names due to it beginning with a number
    -- regexp is used 
    select m.museum_id,m.name,m.city
    from museum as m
    where city regexp '^[0-9]'; 

-- 8. Museum_Hours table has 1 invalid entry. Identify it and remove it.
	-- the invalid entry is a duplicate entry, which is deleted
    SET SQL_SAFE_UPDATES = 0;
    delete from museum_hours
    where id in(
				select id
                from(
					select *,row_number() over (partition by museum_id,day) as rn
                    from museum_hours) as x
				where x.rn>1);
	SET SQL_SAFE_UPDATES = 1;
-- 9 . Fetch the top 10 most famous painting subject
	-- work has all the paintings listed, subject the painting_id and subject. 
    -- created a query to find how paintings are there for each subject and listed top 10 subjects and total number of paintings on that subject by sorting in desc
    select s.subject, count(*) as num_of_paintings
    from subject as s inner join work as w on s.work_id = w.work_id
    group by s.subject
    order by num_of_paintings desc
    limit 10;

-- 10. Identify the museums which are open on both Sunday and Monday. Display museum name, city.
	-- first joined the two tables concerned - museum_hours and museum through museum_id
    -- then listed the museum names by filtering on the basis of day sunday and monday
    select distinct m.museum_id, m.name, count(m_h.day)
    from museum_hours as m_h inner join museum as m on m_h.museum_id=m.museum_id
    where m_h.day in ('Sunday','Monday')
    group by m.name,m.id
    having count(m_h.day) = 2;

-- 11. How many museums are open every single day?
	-- queried to see which are open for 7 days of the week
    -- one of the days has been mispelled as Thusday it is corrected first
	SET SQL_SAFE_UPDATES = 0;
    UPDATE museum_hours
    SET day = REPLACE(day, 'Thusday', 'Thursday')
    WHERE day = 'Thusday';
    select count(*) as num_of_museums_open_everyday
    from (select m.museum_id
		  from museum_hours as m_h inner join museum as m on m_h.museum_id=m.museum_id
          where m_h.day in ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')
		  group by m.id
          having count(m_h.day) = 7) as sq;

-- 12. Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
	-- list of museums are in museum table and list of paintings with museum on work table
    -- joining them and grouping based on museum_id and name would give the required list
		select m.name as museum_name, count(*) as num_of_paintings
		from work as w inner join museum as m on w.museum_id = m.museum_id
		group by m.museum_id,m.name
		order by num_of_paintings desc
		limit 5;

-- 13. Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
	-- list of artists are in artist table and list of paintings with artist on work table
    -- joining them and grouping based on artist_id and name would give the required list
		select a.full_name as artist_name, count(*) as num_of_paintings_done
		from artist as a inner join work as w on a.artist_id = w.artist_id
		group by a.artist_id,a.full_name
		order by num_of_paintings_done desc
		limit 5;

-- 14. Display the 3 least popular canva sizes
	-- canvas specs given on canvas_size table, painting & canvas details on both work and product_size table
    -- joining them and grouping by canvas id and label gives the required result
		select cs.size_id,cs.label, count(*) as num_of_paintings
		from canvas_size as cs 
        inner join product_size as ps on cs.size_id = ps.size_id
        inner join work as w on ps.work_id = w.work_id
		group by cs.size_id,cs.label
		order by num_of_paintings asc
		limit 3;
        
-- 15. Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
	-- joined museum and museum hours, found the time difference, sorted by time_difference
		select m.museum_id, m.name,timediff(str_to_date(close,'%h:%i:%p'),str_to_date(open,'%h:%i:%p')) as duration
        from museum as m inner join museum_hours as m_h on m.museum_id=m_h.museum_id
        order by duration desc
        limit 1;

-- 16. Which museum has the most no of most popular painting style? museum, work
	-- painting, museum details and its style can be found in museum and work tables
    -- joining them based museum_id, results are shown by grouping the museum and style, sorting by total numbers of paintings shown
    select m.name as museum_name, w.style as style_of_work, count(*) as paintings_shown
    from museum as m inner join work as w on m.museum_id = w.museum_id
    group by m.museum_id,m.name,w.style
    order by paintings_shown desc
    limit 1;

-- 17. Identify the artists whose paintings are displayed in multiple countries. artist, museum, work
	-- the concerned tables are artist with artist details, museum with museum details, work with painting details
    -- they are joined and grouped by artist id, then only distinct instances of country are counted
		SELECT a.full_name AS artist,COUNT(DISTINCT m.country) AS num_of_countries_displayed_in
		FROM artist AS a
		INNER JOIN work AS w ON a.artist_id = w.artist_id
		INNER JOIN museum AS m ON w.museum_id = m.museum_id
		GROUP BY a.artist_id, a.full_name
		HAVING COUNT(DISTINCT m.country) > 1
		ORDER BY num_of_countries_displayed_in DESC;

-- 18. Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma.
	-- firstly two seperate results for the highest number of museums in country and city are obtained.
    -- they are then ranked based on the highest number of counts
    -- cross joined as no common columns, and results are shown where the rank is 1 for highest count.
		with 
			cte_ctry as (select country,count(*) as total_museums_in_country, rank() over (order by count(*) desc) as rn
						from museum
						group by country),
			cte_cty as (select city,count(*) as total_museums_in_city, rank() over (order by count(*) desc) as rn
						from museum
						group by city)
		select group_concat(distinct country SEPARATOR ',') as top_countries_based_on_num_museums,group_concat(city SEPARATOR ',') as top_cities_based_on_num__museums
		from cte_cty as ccty cross join cte_ctry as cctry
		where ccty.rn = 1 and  cctry.rn = 1;

-- 19. Identify the artist and the museum where the most expensive and least expensive painting is placed.
	-- firstly from product_size table sale_price are queried and ranked from highest to low & from lowest to high
    -- then the cte query is joined with the necessary tables to give out the result.
    -- case statement was used to add an additional column to the output to show the paintings' popularity
    with expensive as (select *, rank() over (order by sale_price desc) as h_l_sp, rank() over (order by sale_price) as l_h_sp
					from product_size)
	select distinct a.full_name,m.name,e.sale_price,cs.label,
	CASE
        WHEN e.h_l_sp = 1 THEN 'Most Popular'
        WHEN e.l_h_sp = 1 THEN 'Least Popular'
        ELSE NULL -- Handle other cases if needed
    END AS popularity
	from expensive as e
	join work as w on w.work_id = e.work_id
	join artist as a on a.artist_id = w.artist_id
	join museum as m on m.museum_id = w.museum_id
	join canvas_size as cs on cs.size_id = e.size_id
	where h_l_sp = 1 or l_h_sp = 1;

-- 20. Which country has the 5th highest no of paintings? 
	-- query with cte to find the list of coutries with corresponding number of paintings ranked
    -- then the cte is queried to find the fifth one in the rank
    with cte_ctry as (select m.country,count(*) as total_paintings_in_country, rank() over (order by count(*) desc) as rn
				  from museum as m join work as w on m.museum_id=w.museum_id
				  group by m.country)
	select country,total_paintings_in_country
	from cte_ctry
	where rn=5;

-- 21. Which are the 3 most popular and 3 least popular painting styles?
	-- first a cte query was done to rank the painting styles based on numbers of paintings found for each style: highest to lowest as well as lowest to highest
    -- then the cte result set was queried to output least and popular painting styles.
    with expensive as (select w.style, count(*) as num_of_paintings,rank() over (order by count(*) desc) as h_l_p, rank() over (order by count(*)) as l_h_p
					from work as w 
                    where w.style is not null
                    group by w.style)
	select e.style, e.num_of_paintings,
	CASE
        WHEN e.h_l_p <=3 THEN 'Most Popular'
        WHEN e.l_h_p <=3 THEN 'Least Popular'
        ELSE null
    END AS popularity
	from expensive as e
	where e.h_l_p in (1,2,3) or e.l_h_p in (1,2,3);

-- 22. Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
	-- through a cte query the list of artists meeting the condition were fetched and ranked
    -- then with a select query the requered output was shown
    with ar_painting as (select a.full_name,a.nationality,count(*) as num_of_paintings,rank() over (order by count(*) desc) as rn
					from artist as a 
                    join work as w on w.artist_id = a.artist_id
                    join subject as s on s.work_id = w.work_id
                    join museum as m on m.museum_id = w.museum_id
                    where s.subject = 'Portraits' and m.country != 'USA'
                    group by a.full_name,a.nationality)
	select ap.full_name as artist_name,ap.nationality, ap.num_of_paintings
	from ar_painting as ap
	where rn = 1;