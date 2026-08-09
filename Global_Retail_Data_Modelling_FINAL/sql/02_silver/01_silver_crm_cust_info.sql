-- Silver Layer: crm_cust_info
-- Description: Data cleansing, whitespace trimming, categorical standardization, and customer record preservation.
-- Retains all historical records per customer to enable SCD Type 2 tracking in Gold layer.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS silver;

DROP TABLE IF EXISTS silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info AS
SELECT 
    CAST(TRIM(cst_id) AS SIGNED) AS cst_id,
    TRIM(cst_key) AS cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END AS cst_marital_status,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS cst_gndr,
    CASE 
        WHEN TRIM(cst_create_date) LIKE '%-%' THEN STR_TO_DATE(TRIM(cst_create_date), '%Y-%m-%d')
        WHEN TRIM(cst_create_date) LIKE '%/%' THEN STR_TO_DATE(TRIM(cst_create_date), '%Y/%m/%d')
        ELSE CAST(TRIM(cst_create_date) AS DATE)
    END AS cst_create_date,
    CURRENT_TIMESTAMP AS _cleaned_at
FROM bronze.crm_cust_info
WHERE cst_id IS NOT NULL AND TRIM(cst_id) != '';
