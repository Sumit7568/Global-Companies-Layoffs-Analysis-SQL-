-- data cleaning 
select * from layoffs;

-- 1.removing duplicates 
-- 2.standardize  the data 
-- 3. Null values or blank values 
-- 4 . remove any columns

create table ly1 like layoffs;
insert  into ly1 select * from layoffs;
select * from ly1;

select *,row_number() over (partition by company,location ,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as r from ly1;





CREATE TABLE `ly3` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
   `row_num`  INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



insert into ly3  select *,row_number() over (partition by company,location ,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as r from ly1;
SET SQL_SAFE_UPDATES = 0;
delete from ly3 where row_num >1;
select * from ly3 where row_num >1;

update  ly3 set company=trim(company);

select * from ly3;

select * from ly3
where industry like 'Crypto%';

update ly3 set company='Crypto' where industry like 'Crypto';

update ly3 set country ='United States' where  country like 'United States%';
select distinct country  from ly3
order by 1 ;
select * from ly3;
select `date`,STR_TO_DATE(`date`,'%m/%d/%Y');
update ly3 set `date`= STR_TO_DATE(`date`,'%m/%d/%Y');
select * from ly3;

alter table ly3
modify column `date` DATE ;
select * from ly3;


-- NUll values and blank values 

select  * from ly3 where total_laid_off IS NULL
and percentage_laid_off is Null;

select distinct * from ly3
where industry is null or industry='';

select * from ly6 where company like 'Bally%';


select t1.industry,t2.industry from ly3 t1 join ly3 t2 on t1.company=t2.company where (t1.industry is null or t1.industry= '')
and t2.industry is not null;


delete  from ly3  where total_laid_off IS NULL
and percentage_laid_off is Null;


select * from ly3 order by 1;


select *,row_number() over (partition by company,location ,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as r from ly3;


create table ly4  like  ly3;

alter table ly6
drop column r;


CREATE TABLE `ly6` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` date DEFAULT NULL,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `r` INT 
  
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
insert into ly6  select *,row_number() over (partition by company,location ,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as r from ly3;

select *  from ly6;

delete from ly6 where r >1;

select *,row_number() over (partition by company,location ,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) as r from ly6 ;

alter table ly6
modify column `date` DATE ;


select * from ly6 order by 1;






-- exploratory data analysis 



select * from ly6;

-- maximum  total laid off  and percentage laid off
select max(total_laid_off),max(percentage_laid_off),min(total_laid_off) from ly6;  

-- total laid by each company 
select company,sum(total_laid_off) from ly6 group by company  order by 2 desc;

-- most laid off with respect to industry

select industry,sum(total_laid_off) from ly6 group by  industry  order by 2 desc;


-- date range 

select max(`date`), min(`date`) from  ly6;


-- with respect to country 

select country,sum(total_laid_off) from ly6 group by country  order by 2 desc;


-- by year

select  year(`date`),sum(total_laid_off) from ly6 group by year(`date`)  order by 1 desc;




-- by stage 
select stage,sum(total_laid_off) from ly6 group by stage  order by 2 desc;

-- by fundraised
select company,sum(funds_raised_millions) from ly6 group by company  order by 2 desc;


-- avgerage  laid off

select company,avg(total_laid_off) from ly6 group by company  order by 2 desc;

-- average laid off by country 


select country,avg(total_laid_off) from ly6 group by country  order by 2 desc;


-- by month 
select month(`date`),sum(total_laid_off) from ly6 group by month(`date`) order by 2 desc;


-- by month in each year
 with cte as(select substring(`date`,1,7) as `month`,sum(total_laid_off) as total_off from ly6   where  substring(`date`,1,7) is not null group by `month` order by 1 asc)


-- by month in each increament 

select `month`,  total_off,sum(total_off) over (order by `month`) as rl from cte;

-- with respecct ot the companies 



 with cte1 as (select company, year(`date`) as years,sum(total_laid_off)  as tl from ly6 group by company,year(`date`))
 
 , cte2 as(select *, dense_rank () over(partition by years order by tl  desc  ) as d from cte1 where years  is not null
  )
 
 select  * from cte2 where d<=5;




