-- Gold Layer: dim_date
-- Description: Calendar Dimension Table generated automatically spanning order dates.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS gold;

DROP TABLE IF EXISTS gold.dim_date;

SET SESSION cte_max_recursion_depth = 10000;

CREATE TABLE gold.dim_date AS
WITH RECURSIVE seq AS (
    SELECT CAST('2010-01-01' AS DATE) AS full_date
    UNION ALL
    SELECT DATE_ADD(full_date, INTERVAL 1 DAY)
    FROM seq
    WHERE full_date < '2016-12-31'
)
SELECT 
    CAST(DATE_FORMAT(full_date, '%Y%m%d') AS SIGNED) AS date_key,
    full_date,
    YEAR(full_date) AS year,
    QUARTER(full_date) AS quarter,
    MONTH(full_date) AS month_number,
    DATE_FORMAT(full_date, '%M') AS month_name,
    DATE_FORMAT(full_date, '%b') AS month_short,
    DAYOFMONTH(full_date) AS day_of_month,
    DAYOFWEEK(full_date) AS day_of_week,
    DATE_FORMAT(full_date, '%W') AS day_name,
    CASE WHEN DAYOFWEEK(full_date) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    YEAR(full_date) AS fiscal_year,
    CONCAT('Q', QUARTER(full_date)) AS fiscal_quarter
FROM seq;
