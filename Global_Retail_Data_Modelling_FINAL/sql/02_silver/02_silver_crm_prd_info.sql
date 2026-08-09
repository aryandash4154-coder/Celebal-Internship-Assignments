-- Silver Layer: crm_prd_info
-- Description: Product cleaning, category code extraction, cost validation, and SCD status flag.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS silver;

DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info AS
SELECT 
    CAST(TRIM(prd_id) AS SIGNED) AS prd_id,
    TRIM(prd_key) AS prd_key,
    -- Category ID extracted from prd_key prefix (e.g. CO-RF -> CO_RF; CO-PE -> CO_PD)
    CASE 
        WHEN REPLACE(SUBSTRING(TRIM(prd_key), 1, 5), '-', '_') = 'CO_PE' THEN 'CO_PD'
        ELSE REPLACE(SUBSTRING(TRIM(prd_key), 1, 5), '-', '_')
    END AS cat_id,
    -- Item key suffix used in sales table (e.g. BK-R93R-62)
    SUBSTRING(TRIM(prd_key), 7) AS item_key,
    TRIM(prd_nm) AS prd_nm,
    COALESCE(CAST(NULLIF(TRIM(prd_cost), '') AS DECIMAL(10, 2)), 0.00) AS prd_cost,
    CASE 
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    CASE 
        WHEN TRIM(prd_start_dt) LIKE '%-%' THEN STR_TO_DATE(TRIM(prd_start_dt), '%Y-%m-%d')
        WHEN TRIM(prd_start_dt) LIKE '%/%' THEN STR_TO_DATE(TRIM(prd_start_dt), '%Y/%m/%d')
        ELSE CAST(NULLIF(TRIM(prd_start_dt), '') AS DATE)
    END AS prd_start_dt,
    CASE 
        WHEN TRIM(prd_end_dt) LIKE '%-%' THEN STR_TO_DATE(TRIM(prd_end_dt), '%Y-%m-%d')
        WHEN TRIM(prd_end_dt) LIKE '%/%' THEN STR_TO_DATE(TRIM(prd_end_dt), '%Y/%m/%d')
        ELSE CAST(NULLIF(TRIM(prd_end_dt), '') AS DATE)
    END AS prd_end_dt,
    CASE 
        WHEN prd_end_dt IS NULL OR TRIM(prd_end_dt) = '' THEN 1 
        ELSE 0 
    END AS is_current,
    CURRENT_TIMESTAMP AS _cleaned_at
FROM bronze.crm_prd_info
WHERE prd_id IS NOT NULL AND TRIM(prd_id) != '';
