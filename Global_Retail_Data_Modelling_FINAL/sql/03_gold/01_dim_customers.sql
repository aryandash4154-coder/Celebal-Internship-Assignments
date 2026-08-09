-- Gold Layer: dim_customers
-- Description: Conformed Customer Dimension Table (Star Schema) with SCD Type 2 historical tracking,
-- integrating CRM & ERP customer attributes, location, birthdate, age groups, effective date ranges, and surrogate key.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS gold;

DROP TABLE IF EXISTS gold.dim_customers;

CREATE TABLE gold.dim_customers AS
WITH customer_joined AS (
    SELECT 
        c.cst_id AS customer_id,
        c.cst_key AS customer_natural_key,
        c.cst_firstname AS first_name,
        c.cst_lastname AS last_name,
        CONCAT(c.cst_firstname, ' ', c.cst_lastname) AS full_name,
        c.cst_marital_status AS marital_status,
        -- Prioritize ERP gender if available, fallback to CRM gender, default to 'n/a'
        COALESCE(
            NULLIF(e.gender, 'n/a'), 
            NULLIF(c.cst_gndr, 'n/a'), 
            'n/a'
        ) AS gender,
        e.birthdate,
        COALESCE(l.country, 'n/a') AS country,
        c.cst_create_date AS customer_since_date,
        -- Effective start date for SCD Type 2 history tracking
        COALESCE(c.cst_create_date, CAST('1900-01-01' AS DATE)) AS effective_start_date
    FROM silver.crm_cust_info c
    LEFT JOIN silver.erp_cust_az12 e ON c.cst_key = e.cst_key
    LEFT JOIN silver.erp_loc_a101 l ON c.cst_key = l.cst_key
),
scd_lead AS (
    SELECT 
        customer_id,
        customer_natural_key,
        first_name,
        last_name,
        full_name,
        marital_status,
        gender,
        birthdate,
        country,
        customer_since_date,
        effective_start_date,
        LEAD(effective_start_date) OVER (
            PARTITION BY customer_id 
            ORDER BY effective_start_date, customer_natural_key
        ) AS next_start_date
    FROM customer_joined
),
scd_window AS (
    SELECT 
        customer_id,
        customer_natural_key,
        first_name,
        last_name,
        full_name,
        marital_status,
        gender,
        birthdate,
        country,
        customer_since_date,
        effective_start_date,
        -- Lead date minus 1 day for effective end date of historical records
        DATE_SUB(next_start_date, INTERVAL 1 DAY) AS effective_end_date
    FROM scd_lead
)
SELECT 
    -- Primary Surrogate Key for Star Schema
    ROW_NUMBER() OVER (ORDER BY customer_id, effective_start_date) AS customer_key,
    customer_id,
    customer_natural_key,
    first_name,
    last_name,
    full_name,
    marital_status,
    gender,
    birthdate,
    -- Derived Age and Age Group
    CASE 
        WHEN birthdate IS NOT NULL THEN TIMESTAMPDIFF(YEAR, birthdate, CURRENT_DATE)
        ELSE NULL 
    END AS age,
    CASE 
        WHEN birthdate IS NULL THEN 'Unknown'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURRENT_DATE) < 25 THEN '< 25'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURRENT_DATE) BETWEEN 25 AND 34 THEN '25 - 34'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURRENT_DATE) BETWEEN 35 AND 44 THEN '35 - 44'
        WHEN TIMESTAMPDIFF(YEAR, birthdate, CURRENT_DATE) BETWEEN 45 AND 54 THEN '45 - 54'
        ELSE '55+'
    END AS age_group,
    country,
    customer_since_date,
    effective_start_date,
    effective_end_date,
    CASE 
        WHEN effective_end_date IS NULL THEN 1 
        ELSE 0 
    END AS is_current
FROM scd_window;
