-- Silver Layer: erp_px_cat_g1v2
-- Description: Cleans ERP Product Category table and converts maintenance flag to boolean.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS silver;

DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 AS
SELECT 
    TRIM(ID) AS cat_id,
    TRIM(CAT) AS category,
    TRIM(SUBCAT) AS subcategory,
    CASE 
        WHEN UPPER(TRIM(MAINTENANCE)) IN ('YES', 'TRUE', '1') THEN 1 
        ELSE 0 
    END AS is_maintenance_required,
    CURRENT_TIMESTAMP AS _cleaned_at
FROM bronze.erp_px_cat_g1v2
WHERE ID IS NOT NULL AND TRIM(ID) != '';
