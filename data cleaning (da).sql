-- =========================
-- DATA CLEANING
-- =========================

SELECT * 
FROM layoffs;

-- Steps:
-- 1. Remove duplicates
-- 2. Standardize data
-- 3. Handle NULL / blank values
-- 4. Remove unnecessary columns


-- =========================
-- CREATE WORKING TABLE
-- =========================

CREATE TABLE ly1 LIKE layoffs;

INSERT INTO ly1
SELECT *
FROM layoffs;

SELECT * 
FROM ly1;


-- =========================
-- IDENTIFY DUPLICATES
-- =========================

SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off,
                        percentage_laid_off, 'date', stage, country,
                        funds_raised_millions
       ) AS r
FROM ly1;


-- =========================
-- CREATE DEDUPLICATED TABLE
-- =========================

CREATE TABLE ly3 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off TEXT,
    `date` TEXT,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT DEFAULT NULL,
    row_num INT
) ENGINE=InnoDB 
DEFAULT CHARSET=utf8mb4 
COLLATE=utf8mb4_0900_ai_ci;


INSERT INTO ly3
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off,
                        percentage_laid_off, 'date', stage, country,
                        funds_raised_millions
       ) AS r
FROM ly1;

SET SQL_SAFE_UPDATES = 0;

DELETE
FROM ly3
WHERE row_num > 1;

SELECT *
FROM ly3
WHERE row_num > 1;


-- =========================
-- STANDARDIZE DATA
-- =========================

UPDATE ly3
SET company = TRIM(company);

SELECT *
FROM ly3;

SELECT *
FROM ly3
WHERE industry LIKE 'Crypto%';

UPDATE ly3
SET company = 'Crypto'
WHERE industry LIKE 'Crypto';

UPDATE ly3
SET country = 'United States'
WHERE country LIKE 'United States%';

SELECT DISTINCT country
FROM ly3
ORDER BY 1;


-- =========================
-- DATE FORMATTING
-- =========================

SELECT `date`,
       STR_TO_DATE(`date`, '%m/%d/%Y')
FROM ly3;

UPDATE ly3
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE ly3
MODIFY COLUMN `date` DATE;

SELECT *
FROM ly3;


-- =========================
-- NULL & BLANK VALUES
-- =========================

SELECT *
FROM ly3
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

SELECT DISTINCT *
FROM ly3
WHERE industry IS NULL
   OR industry = '';

SELECT t1.industry, t2.industry
FROM ly3 t1
JOIN ly3 t2
  ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

DELETE
FROM ly3
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

SELECT *
FROM ly3
ORDER BY 1;


-- =========================
-- FINAL CLEAN TABLE
-- =========================

CREATE TABLE ly6 (
    company TEXT,
    location TEXT,
    industry TEXT,
    total_laid_off INT DEFAULT NULL,
    percentage_laid_off TEXT,
    `date` DATE DEFAULT NULL,
    stage TEXT,
    country TEXT,
    funds_raised_millions INT DEFAULT NULL,
    r INT
) ENGINE=InnoDB 
DEFAULT CHARSET=utf8mb4 
COLLATE=utf8mb4_0900_ai_ci;


INSERT INTO ly6
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off,
                        percentage_laid_off, 'date', stage, country,
                        funds_raised_millions
       ) AS r
FROM ly3;

DELETE
FROM ly6
WHERE r > 1;

ALTER TABLE ly6
MODIFY COLUMN `date` DATE;

SELECT *
FROM ly6
ORDER BY 1;


-- =========================
-- EXPLORATORY DATA ANALYSIS
-- =========================

SELECT *
FROM ly6;


-- Maximum, Minimum & Percentage Laid Off
SELECT MAX(total_laid_off),
       MAX(percentage_laid_off),
       MIN(total_laid_off)
FROM ly6;


-- Total Laid Off by Company
SELECT company,
       SUM(total_laid_off)
FROM ly6
GROUP BY company
ORDER BY 2 DESC;


-- Total Laid Off by Industry
SELECT industry,
       SUM(total_laid_off)
FROM ly6
GROUP BY industry
ORDER BY 2 DESC;


-- Date Range
SELECT MAX(`date`),
       MIN(`date`)
FROM ly6;


-- Total Laid Off by Country
SELECT country,
       SUM(total_laid_off)
FROM ly6
GROUP BY country
ORDER BY 2 DESC;


-- Total Laid Off by Year
SELECT YEAR(`date`) AS year,
       SUM(total_laid_off)
FROM ly6
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;


-- Total Laid Off by Stage
SELECT stage,
       SUM(total_laid_off)
FROM ly6
GROUP BY stage
ORDER BY 2 DESC;


-- Funds Raised by Company
SELECT company,
       SUM(funds_raised_millions)
FROM ly6
GROUP BY company
ORDER BY 2 DESC;


-- Average Laid Off by Company
SELECT company,
       AVG(total_laid_off)
FROM ly6
GROUP BY company
ORDER BY 2 DESC;


-- Average Laid Off by Country
SELECT country,
       AVG(total_laid_off)
FROM ly6
GROUP BY country
ORDER BY 2 DESC;


-- Total Laid Off by Month
SELECT MONTH(`date`) AS month,
       SUM(total_laid_off)
FROM ly6
GROUP BY MONTH(`date`)
ORDER BY 2 DESC;


-- Monthly Trend (Cumulative)
WITH cte AS (
    SELECT SUBSTRING(`date`, 1, 7) AS `month`,
           SUM(total_laid_off) AS total_off
    FROM ly6
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `month`
    ORDER BY 1 ASC
)
SELECT `month`,
       total_off,
       SUM(total_off) OVER (ORDER BY `month`) AS rl
FROM cte;


-- Top 5 Companies by Layoffs Each Year
WITH cte1 AS (
    SELECT company,
           YEAR(`date`) AS years,
           SUM(total_laid_off) AS tl
    FROM ly6
    GROUP BY company, YEAR(`date`)
),
cte2 AS (
    SELECT *,
           DENSE_RANK() OVER (
               PARTITION BY years
               ORDER BY tl DESC
           ) AS d
    FROM cte1
    WHERE years IS NOT NULL
)
SELECT *
FROM cte2
WHERE d <= 5;
