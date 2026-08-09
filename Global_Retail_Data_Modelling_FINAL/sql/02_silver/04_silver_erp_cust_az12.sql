-- Silver Layer: erp_cust_az12
-- Description: Cleans ERP Customer Demographics data, strips CID prefix ('NAS'), normalizes gender, and parses birthdate.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS silver;

DROP TABLE IF EXISTS silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 AS
WITH cleaned AS (
    SELECT 
        -- Strip 'NAS' prefix from CID to match CRM cst_key format (AW00011000)
        CASE 
            WHEN TRIM(CID) LIKE 'NAS%' THEN SUBSTRING(TRIM(CID), 4)
            ELSE TRIM(CID)
        END AS cst_key,
        CASE 
            WHEN TRIM(BDATE) LIKE '%-%' THEN STR_TO_DATE(TRIM(BDATE), '%Y-%m-%d')
            WHEN TRIM(BDATE) LIKE '%/%' THEN STR_TO_DATE(TRIM(BDATE), '%Y/%m/%d')
            ELSE CAST(NULLIF(TRIM(BDATE), '') AS DATE)
        END AS birthdate,
        CASE 
            WHEN UPPER(TRIM(GEN)) IN ('MALE', 'M') THEN 'Male'
            WHEN UPPER(TRIM(GEN)) IN ('FEMALE', 'F') THEN 'Female'
            ELSE 'n/a'
        END AS gender,
        ROW_NUMBER() OVER (
            PARTITION BY CASE WHEN TRIM(CID) LIKE 'NAS%' THEN SUBSTRING(TRIM(CID), 4) ELSE TRIM(CID) END 
            ORDER BY TRIM(BDATE) DESC
        ) AS flag_last
    FROM bronze.erp_cust_az12
    WHERE CID IS NOT NULL AND TRIM(CID) != ''
)
SELECT 
    cst_key,
    birthdate,
    gender,
    CURRENT_TIMESTAMP AS _cleaned_at
FROM cleaned
WHERE flag_last = 1;
