-- ====================================================================
-- Analytics Suite: 04_demographics_and_shipping.sql
-- Description: Country performance, Gender demographics, Age-group analysis, and Shipping delay performance.
-- Stage: 05_analytics
-- Dialect: MySQL 8.0+
-- ====================================================================

-- --------------------------------------------------------------------
-- Query 16: Country & Regional Performance Analysis
-- --------------------------------------------------------------------
SELECT 
    c.country,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.quantity) AS total_units_sold,
    ROUND(SUM(f.sales_amount), 2) AS country_revenue,
    ROUND(SUM(f.profit_amount), 2) AS country_profit,
    ROUND(SUM(f.sales_amount) / NULLIF(COUNT(DISTINCT f.order_number), 0), 2) AS average_order_value
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY country_revenue DESC;

-- --------------------------------------------------------------------
-- Query 17: Customer Gender Demographics & Revenue Contribution
-- --------------------------------------------------------------------
SELECT 
    c.gender,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.quantity) AS units_purchased,
    ROUND(SUM(f.sales_amount), 2) AS total_revenue,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND((SUM(f.sales_amount) * 100.0 / (SELECT SUM(sales_amount) FROM gold.fact_sales)), 2) AS revenue_share_pct
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.gender
ORDER BY total_revenue DESC;

-- --------------------------------------------------------------------
-- Query 18: Customer Age-Group Demographics Sales Breakdown
-- --------------------------------------------------------------------
SELECT 
    c.age_group,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT f.order_number) AS total_orders,
    ROUND(SUM(f.sales_amount), 2) AS group_revenue,
    ROUND(AVG(f.sales_amount), 2) AS avg_item_spend
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.age_group
ORDER BY 
    CASE c.age_group
        WHEN '< 25' THEN 1
        WHEN '25 - 34' THEN 2
        WHEN '35 - 44' THEN 3
        WHEN '45 - 54' THEN 4
        WHEN '55+' THEN 5
        ELSE 6
    END;

-- --------------------------------------------------------------------
-- Query 19: Shipping Delay & Fulfillment Performance Duration Analysis
-- --------------------------------------------------------------------
WITH fulfillment AS (
    SELECT 
        f.order_number,
        f.order_date,
        f.ship_date,
        f.due_date,
        DATEDIFF(f.ship_date, f.order_date) AS days_to_ship,
        DATEDIFF(f.due_date, f.ship_date) AS days_before_due
    FROM gold.fact_sales f
    WHERE f.order_date IS NOT NULL AND f.ship_date IS NOT NULL
)
SELECT 
    CASE 
        WHEN days_to_ship <= 0 THEN 'Same Day Shipping'
        WHEN days_to_ship BETWEEN 1 AND 3 THEN '1-3 Days (Fast)'
        WHEN days_to_ship BETWEEN 4 AND 7 THEN '4-7 Days (Standard)'
        ELSE '8+ Days (Delayed)'
    END AS fulfillment_speed_tier,
    COUNT(DISTINCT order_number) AS order_count,
    ROUND(AVG(days_to_ship), 1) AS avg_shipping_days,
    ROUND(AVG(days_before_due), 1) AS avg_lead_days_before_due
FROM fulfillment
GROUP BY 
    CASE 
        WHEN days_to_ship <= 0 THEN 'Same Day Shipping'
        WHEN days_to_ship BETWEEN 1 AND 3 THEN '1-3 Days (Fast)'
        WHEN days_to_ship BETWEEN 4 AND 7 THEN '4-7 Days (Standard)'
        ELSE '8+ Days (Delayed)'
    END
ORDER BY order_count DESC;
