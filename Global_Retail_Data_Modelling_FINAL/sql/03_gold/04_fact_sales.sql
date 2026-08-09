-- Gold Layer: fact_sales
-- Description: Core Sales Fact Table (Star Schema) linking sales transaction records to conformed 
-- dimension tables (dim_customers, dim_products, dim_date) via foreign surrogate keys. Includes calculated financial metrics.
-- Grain of fact_sales: one row per sales order line/product transaction.
-- Product Integration Rule: sls_prd_key in sales details matches the conformed item_key in gold.dim_products.
-- Dialect: MySQL 8.0+

CREATE DATABASE IF NOT EXISTS gold;

DROP TABLE IF EXISTS gold.fact_sales;

CREATE TABLE gold.fact_sales AS
WITH cust_curr AS (
    SELECT customer_id, MIN(customer_key) AS customer_key
    FROM gold.dim_customers
    WHERE is_current = 1
    GROUP BY customer_id
),
cust_any AS (
    SELECT customer_id, MIN(customer_key) AS customer_key
    FROM gold.dim_customers
    GROUP BY customer_id
),
prd_curr AS (
    SELECT item_key, MIN(product_key) AS product_key, MIN(unit_cost) AS unit_cost
    FROM gold.dim_products
    WHERE is_current = 1
    GROUP BY item_key
),
prd_any AS (
    SELECT item_key, MIN(product_key) AS product_key, MIN(unit_cost) AS unit_cost
    FROM gold.dim_products
    GROUP BY item_key
),
sales_enriched AS (
    SELECT 
        s.sls_ord_num AS order_number,
        s.sls_prd_key AS product_natural_key,
        s.sls_cust_id AS customer_natural_key,
        -- Surrogate Foreign Keys (Point-in-Time SCD Type 2 Lookup with active/fallback defaults)
        COALESCE(c_scd.customer_key, c_curr.customer_key, c_any.customer_key) AS customer_key,
        COALESCE(p_scd.product_key, p_curr.product_key, p_any.product_key) AS product_key,
        CAST(DATE_FORMAT(s.sls_order_dt, '%Y%m%d') AS SIGNED) AS order_date_key,
        CAST(DATE_FORMAT(s.sls_ship_dt, '%Y%m%d') AS SIGNED) AS ship_date_key,
        CAST(DATE_FORMAT(s.sls_due_dt, '%Y%m%d') AS SIGNED) AS due_date_key,
        -- Transaction Dates
        s.sls_order_dt AS order_date,
        s.sls_ship_dt AS ship_date,
        s.sls_due_dt AS due_date,
        -- Measures
        s.sls_quantity AS quantity,
        s.sls_price AS unit_price,
        s.sls_sales AS sales_amount,
        COALESCE(p_scd.unit_cost, p_curr.unit_cost, p_any.unit_cost, 0.00) AS unit_cost,
        (s.sls_quantity * COALESCE(p_scd.unit_cost, p_curr.unit_cost, p_any.unit_cost, 0.00)) AS cost_amount,
        (s.sls_sales - (s.sls_quantity * COALESCE(p_scd.unit_cost, p_curr.unit_cost, p_any.unit_cost, 0.00))) AS profit_amount
    FROM silver.crm_sales_details s
    -- SCD Type 2 Customer Point-in-time Join
    LEFT JOIN gold.dim_customers c_scd
      ON s.sls_cust_id = c_scd.customer_id
     AND s.sls_order_dt BETWEEN c_scd.effective_start_date AND COALESCE(c_scd.effective_end_date, CAST('9999-12-31' AS DATE))
    LEFT JOIN cust_curr c_curr
      ON s.sls_cust_id = c_curr.customer_id
    LEFT JOIN cust_any c_any
      ON s.sls_cust_id = c_any.customer_id
    -- SCD Type 2 Product Point-in-time Join (supports product_natural_key and item_key)
    LEFT JOIN gold.dim_products p_scd 
      ON s.sls_prd_key = p_scd.item_key
     AND s.sls_order_dt BETWEEN p_scd.effective_start_date AND COALESCE(p_scd.effective_end_date, CAST('9999-12-31' AS DATE))
    LEFT JOIN prd_curr p_curr 
      ON s.sls_prd_key = p_curr.item_key
    LEFT JOIN prd_any p_any 
      ON s.sls_prd_key = p_any.item_key
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY order_date, order_number) AS sales_key,
    order_number,
    customer_key,
    product_key,
    order_date_key,
    ship_date_key,
    due_date_key,
    order_date,
    ship_date,
    due_date,
    quantity,
    unit_price,
    sales_amount,
    unit_cost,
    cost_amount,
    profit_amount,
    CASE 
        WHEN sales_amount > 0 THEN ROUND((profit_amount / sales_amount) * 100, 2)
        ELSE 0.00 
    END AS margin_pct
FROM sales_enriched;
