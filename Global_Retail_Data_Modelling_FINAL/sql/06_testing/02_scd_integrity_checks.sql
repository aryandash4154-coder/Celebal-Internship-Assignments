-- ====================================================================
-- Stage 06: Testing & Quality Assurance Suite
-- File: 02_scd_integrity_checks.sql
-- Description: Validates SCD Type 2 integrity (effective date bounds, single current version per natural key).
-- Dialect: MySQL 8.0+
-- ====================================================================

-- Test 2.1: Assert each customer_id has exactly 1 active version (is_current = 1)
SELECT 
    customer_id,
    COUNT(*) AS active_record_count
FROM gold.dim_customers
WHERE is_current = 1
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Test 2.2: Assert effective_start_date <= effective_end_date for historical records
SELECT 
    COUNT(*) AS invalid_scd_date_ranges
FROM gold.dim_customers
WHERE effective_end_date IS NOT NULL 
  AND effective_start_date > effective_end_date;

-- Test 2.3: Assert product dimension has exactly 1 active version per item_key
SELECT 
    item_key,
    COUNT(*) AS active_product_versions
FROM gold.dim_products
WHERE is_current = 1
GROUP BY item_key
HAVING COUNT(*) > 1;
