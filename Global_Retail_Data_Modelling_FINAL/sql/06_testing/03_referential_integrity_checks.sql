-- ====================================================================
-- Stage 06: Testing & Quality Assurance Suite
-- File: 03_referential_integrity_checks.sql
-- Description: Asserts foreign key surrogate key matching and zero orphan records in fact_sales.
-- Dialect: MySQL 8.0+
-- ====================================================================

-- Test 3.1: Assert 0 orphan customer keys in fact_sales
SELECT 
    COUNT(*) AS orphan_customer_keys
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

-- Test 3.2: Assert 0 orphan product keys in fact_sales
SELECT 
    COUNT(*) AS orphan_product_keys
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p ON f.product_key = p.product_key
WHERE p.product_key IS NULL;

-- Test 3.3: Assert non-negative sales amounts and quantities
SELECT 
    COUNT(*) AS invalid_sales_records
FROM gold.fact_sales
WHERE sales_amount < 0 OR quantity <= 0 OR unit_price < 0;
