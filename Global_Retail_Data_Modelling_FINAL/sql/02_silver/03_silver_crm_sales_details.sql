-- Silver Layer: crm_sales_details
-- Description: Sales details cleaning, YYYYMMDD integer-to-date conversion, sales revenue recalculation, and deduplication.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS silver;

DROP TABLE IF EXISTS silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details AS
WITH parsed AS (
    SELECT 
        TRIM(sls_ord_num) AS sls_ord_num,
        TRIM(sls_prd_key) AS sls_prd_key,
        CAST(TRIM(sls_cust_id) AS SIGNED) AS sls_cust_id,
        CASE 
            WHEN TRIM(sls_order_dt) = '0' OR CHAR_LENGTH(TRIM(sls_order_dt)) != 8 THEN NULL 
            ELSE STR_TO_DATE(TRIM(sls_order_dt), '%Y%m%d')
        END AS sls_order_dt,
        CASE 
            WHEN TRIM(sls_ship_dt) = '0' OR CHAR_LENGTH(TRIM(sls_ship_dt)) != 8 THEN NULL 
            ELSE STR_TO_DATE(TRIM(sls_ship_dt), '%Y%m%d')
        END AS sls_ship_dt,
        CASE 
            WHEN TRIM(sls_due_dt) = '0' OR CHAR_LENGTH(TRIM(sls_due_dt)) != 8 THEN NULL 
            ELSE STR_TO_DATE(TRIM(sls_due_dt), '%Y%m%d')
        END AS sls_due_dt,
        COALESCE(CAST(NULLIF(TRIM(sls_quantity), '') AS SIGNED), 0) AS sls_quantity,
        COALESCE(CAST(NULLIF(TRIM(sls_price), '') AS DECIMAL(10, 2)), 0.00) AS sls_price,
        CAST(NULLIF(TRIM(sls_sales), '') AS DECIMAL(10, 2)) AS raw_sales
    FROM bronze.crm_sales_details
    WHERE sls_ord_num IS NOT NULL AND TRIM(sls_ord_num) != ''
),
calculated AS (
    SELECT 
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_quantity,
        ABS(sls_price) AS sls_price,
        -- Recalculate sales if missing, invalid, or mismatched with quantity * price
        CASE 
            WHEN raw_sales IS NULL OR raw_sales <= 0 OR raw_sales != (sls_quantity * ABS(sls_price))
                THEN (sls_quantity * ABS(sls_price))
            ELSE raw_sales
        END AS sls_sales,
        ROW_NUMBER() OVER (
            PARTITION BY sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt 
            ORDER BY sls_ord_num
        ) AS flag_dedup
    FROM parsed
)
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_quantity,
    sls_price,
    sls_sales,
    CURRENT_TIMESTAMP AS _cleaned_at
FROM calculated
WHERE flag_dedup = 1;
