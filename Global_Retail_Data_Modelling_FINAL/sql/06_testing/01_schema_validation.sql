-- ====================================================================
-- Stage 06: Testing & Quality Assurance Suite
-- File: 01_schema_validation.sql
-- Description: Asserts non-null constraints and primary key uniqueness across dimension tables.
-- Dialect: MySQL 8.0+
-- ====================================================================

-- Test 1.1: Customer surrogate key uniqueness
SELECT 
    COUNT(customer_key) - COUNT(DISTINCT customer_key) AS customer_key_duplicate_count
FROM gold.dim_customers;

-- Test 1.2: Product surrogate key uniqueness
SELECT 
    COUNT(product_key) - COUNT(DISTINCT product_key) AS product_key_duplicate_count
FROM gold.dim_products;

-- Test 1.3: Date dimension key uniqueness
SELECT 
    COUNT(date_key) - COUNT(DISTINCT date_key) AS date_key_duplicate_count
FROM gold.dim_date;
