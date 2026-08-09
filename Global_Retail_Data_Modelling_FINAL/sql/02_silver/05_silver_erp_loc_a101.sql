-- Silver Layer: erp_loc_a101
-- Description: Cleans ERP Location data, normalizes customer key (removes hyphens), and standardizes country names.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS silver;

DROP TABLE IF EXISTS silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 AS
WITH cleaned AS (
    SELECT 
        -- Replace 'AW-' with 'AW' to match CRM cst_key format (AW00011000)
        REPLACE(TRIM(CID), '-', '') AS cst_key,
        CASE 
            WHEN UPPER(TRIM(CNTRY)) IN ('US', 'USA', 'UNITED STATES') THEN 'United States'
            WHEN UPPER(TRIM(CNTRY)) IN ('DE', 'GERMANY') THEN 'Germany'
            WHEN UPPER(TRIM(CNTRY)) = 'AUSTRALIA' THEN 'Australia'
            WHEN UPPER(TRIM(CNTRY)) = 'CANADA' THEN 'Canada'
            WHEN UPPER(TRIM(CNTRY)) = 'FRANCE' THEN 'France'
            WHEN UPPER(TRIM(CNTRY)) IN ('UK', 'UNITED KINGDOM') THEN 'United Kingdom'
            ELSE 'n/a'
        END AS country,
        ROW_NUMBER() OVER (
            PARTITION BY REPLACE(TRIM(CID), '-', '') 
            ORDER BY TRIM(CNTRY) DESC
        ) AS flag_last
    FROM bronze.erp_loc_a101
    WHERE CID IS NOT NULL AND TRIM(CID) != ''
)
SELECT 
    cst_key,
    country,
    CURRENT_TIMESTAMP AS _cleaned_at
FROM cleaned
WHERE flag_last = 1;
