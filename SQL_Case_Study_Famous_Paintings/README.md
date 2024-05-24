#### SQL Case Study

This repository contains solutions to 22 SQL questions that serve as a case study for learning SQL. These questions were provided as problem statements by [techTFQ](https://www.youtube.com/@techTFQ), in his [SQL_CASE_STUDY_PROJECT](https://youtu.be/AZ29DXaJ1Ts?si=psEg5MkUdwwiR3Bl) video, and the solutions provided here can be used for reference and learning purposes.

#### Questions

The SQL questions cover a variety of topics including:

1. Basic SELECT statements
2. Joins
3. Subqueries
4. Aggregation functions
5. Intermediate to Advanced SQL concepts

#### Usage

To use these solutions:

1. Ensure you have a SQL database management system installed (e.g., MySQL, PostgreSQL, SQLite).
2. You can load the dataset using the python script provided or you can do it in your own way.
3. Add an `id` column for each data table. This will act as the primary key.
4. Execute the SQL scripts provided for each question in your preferred SQL environment.
5. Review the solutions and compare them with your own answers.
6. Experiment with modifying the queries to further understand SQL concepts.

#### Solutions

Below are the solutions to each SQL question:

1. **Q1**: Fetch all the paintings which are not displayed on any museums?
   ```sql
   select name as list_of_paintings_not_displayed
   from work
   where museum_id is null;
2. **Q2**: Are there museums without any paintings?
   ```sql
   select m.name as Museums_with_no_paintings
   from museum as m
   where not exists (select 1 
                      from work as w
                      where w.museum_id = m.museum_id);
3. **Q3**: How many paintings have an asking price of more than their regular price?
   ```sql
   select count(distinct p.work_id) as number_of_paintings_with_higher_asking_price
   from product_size as p
   where p.sale_price > p.regular_price;
4. **Q4**: Identify the paintings whose asking price is less than 50% of its regular price
   ```sql
   select w.work_id as id, w.name as painting_name
   from work as w
   where exists (select 1
                 from product_size as p
                 where p.sale_price < (0.5 * p.regular_price));
5. **Q5**: Which canva size costs the most?
   ```sql
   select c.size_id, c.label as size_specifics,sum(p.sale_price) as total_sale_price
   from product_size as p inner join canvas_size as c on p.size_id = c.size_id 
   group by c.size_id,c.label
   order by total_sale_price DESC 
   limit 1;
6. **Q6**: Delete duplicate records from work, product_size, subject and image_link tables
   ```sql
   SET SQL_SAFE_UPDATES = 0;
   delete from work
   where id in(select id
               from(select *,row_number() over (partition by work_id) as rn
                    from work) as x
               where x.rn>1);
	-- product_size
    delete from product_size
    where id in(select id
                from(select *,row_number() over (partition by work_id,size_id) as rn
                    from product_size) as x
		            where x.rn>1);
	-- subject
	delete from subject
   where id in(select id
                from(select *,row_number() over (partition by work_id,subject) as rn
                    from subject) as x
				       where x.rn>1);
	-- image_link
    delete from image_link
    where id in(select id
                from(select *,row_number() over (partition by work_id) as rn
                     from image_link) as x
				        where x.rn>1);
    SET SQL_SAFE_UPDATES = 1;
7. **Q7**: Identify the museums with invalid city information in the given dataset
   ```sql
   select m.museum_id,m.name,m.city
   from museum as m
   where city regexp '^[0-9]';
8. **Q8**: Museum_Hours table has 1 invalid entry. Identify it and remove it.
   ```sql
   SET SQL_SAFE_UPDATES = 0;
    delete from museum_hours
    where id in(select id
                from(select *,row_number() over (partition by museum_id,day) as rn
                    from museum_hours) as x
				where x.rn>1);
	SET SQL_SAFE_UPDATES = 1;
9. **Q9**: Fetch the top 10 most famous painting subject
   ```sql
   select s.subject, count(*) as num_of_paintings
   from subject as s inner join work as w on s.work_id = w.work_id
   group by s.subject
   order by num_of_paintings desc
   limit 10;
10. **Q10**: Identify the museums which are open on both Sunday and Monday. Display museum name, city.
    ```sql
    select distinct m.museum_id, m.name, count(m_h.day)
    from museum_hours as m_h inner join museum as m on m_h.museum_id=m.museum_id
    where m_h.day in ('Sunday','Monday')
    group by m.name,m.id
    having count(m_h.day) = 2;
11. **Q11**: How many museums are open every single day?
    ```sql
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
12. **Q12**: Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
    ```sql
    select m.name as museum_name, count(*) as num_of_paintings
		from work as w inner join museum as m on w.museum_id = m.museum_id
		group by m.museum_id,m.name
		order by num_of_paintings desc
		limit 5;
13. **Q13**: Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
    ```sql
    select a.full_name as artist_name, count(*) as num_of_paintings_done
		from artist as a inner join work as w on a.artist_id = w.artist_id
		group by a.artist_id,a.full_name
		order by num_of_paintings_done desc
		limit 5;
14. **Q14**: Display the 3 least popular canva sizes
    ```sql
    select cs.size_id,cs.label, count(*) as num_of_paintings
		from canvas_size as cs 
        inner join product_size as ps on cs.size_id = ps.size_id
        inner join work as w on ps.work_id = w.work_id
		group by cs.size_id,cs.label
		order by num_of_paintings asc
		limit 3;
15. **Q15**: Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
    ```sql
    select m.museum_id, m.name,timediff(str_to_date(close,'%h:%i:%p'),str_to_date(open,'%h:%i:%p')) as duration
        from museum as m inner join museum_hours as m_h on m.museum_id=m_h.museum_id
        order by duration desc
        limit 1;
16. **Q16**: Which museum has the most no of most popular painting style?
    ```sql
    select m.name as museum_name, w.style as style_of_work, count(*) as paintings_shown
    from museum as m inner join work as w on m.museum_id = w.museum_id
    group by m.museum_id,m.name,w.style
    order by paintings_shown desc
    limit 1;
17. **Q17**: Identify the artists whose paintings are displayed in multiple countries. 
    ```sql
    SELECT a.full_name AS artist,COUNT(DISTINCT m.country) AS num_of_countries_displayed_in
		FROM artist AS a
		INNER JOIN work AS w ON a.artist_id = w.artist_id
		INNER JOIN museum AS m ON w.museum_id = m.museum_id
		GROUP BY a.artist_id, a.full_name
		HAVING COUNT(DISTINCT m.country) > 1
		ORDER BY num_of_countries_displayed_in DESC;
18. **Q18**: Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma. 
    ```sql
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
19. **Q19**: Identify the artist and the museum where the most expensive and least expensive painting is placed. 
    ```sql
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
20. **Q20**: Which country has the 5th highest no of paintings?  
    ```sql
    with cte_ctry as (select m.country,count(*) as total_paintings_in_country, rank() over (order by count(*) desc) as rn
				  from museum as m join work as w on m.museum_id=w.museum_id
				  group by m.country)
	select country,total_paintings_in_country
	from cte_ctry
	where rn=5;
21. **Q21**: Which are the 3 most popular and 3 least popular painting styles? 
    ```sql
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
22. **Q22**: Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality. 
    ```sql
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
