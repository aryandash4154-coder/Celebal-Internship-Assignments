-- ====================================================================
-- Analytics Suite: 02_customer_insights.sql
-- Description: Customer lifetime value, purchase frequency, repeat customers, and acquisition trends.
-- Stage: 05_analytics
-- Dialect: MySQL 8.0+
-- ====================================================================

-- --------------------------------------------------------------------
-- Query 6: Top 10 Spending Customers by Lifetime Value (Revenue & Margin)
-- --------------------------------------------------------------------
SELECT 
    c.customer_key,
    c.customer_id,
    c.full_name,
    c.country,
    c.gender,
    COUNT(DISTINCT f.order_number) AS total_orders_placed,
    SUM(f.quantity) AS total_items_purchased,
    ROUND(SUM(f.sales_amount), 2) AS total_lifetime_spend,
    ROUND(SUM(f.profit_amount), 2) AS total_profit_generated,
    ROUND((SUM(f.profit_amount) / NULLIF(SUM(f.sales_amount), 0)) * 100, 2) AS avg_margin_pct
FROM gold.fact_sales f
JOIN gold.dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_id, c.full_name, c.country, c.gender
ORDER BY total_lifetime_spend DESC
LIMIT 10;

-- --------------------------------------------------------------------
-- Query 7: Customer Order Frequency & Purchase Volume Distribution
-- --------------------------------------------------------------------
WITH customer_orders AS (
    SELECT 
        customer_key,
        COUNT(DISTINCT order_number) AS order_count
    FROM gold.fact_sales
    GROUP BY customer_key
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN '1 Order (Single Buyer)'
        WHEN order_count BETWEEN 2 AND 5 THEN '2-5 Orders (Occasional)'
        WHEN order_count BETWEEN 6 AND 10 THEN '6-10 Orders (Frequent)'
        ELSE '10+ Orders (VIP Repeat)'
    END AS order_frequency_tier,
    COUNT(customer_key) AS customer_count,
    ROUND((COUNT(customer_key) * 100.0 / (SELECT COUNT(DISTINCT customer_key) FROM customer_orders)), 2) AS pct_of_total_customers
FROM customer_orders
GROUP BY 
    CASE 
        WHEN order_count = 1 THEN '1 Order (Single Buyer)'
        WHEN order_count BETWEEN 2 AND 5 THEN '2-5 Orders (Occasional)'
        WHEN order_count BETWEEN 6 AND 10 THEN '6-10 Orders (Frequent)'
        ELSE '10+ Orders (VIP Repeat)'
    END
ORDER BY customer_count DESC;

-- --------------------------------------------------------------------
-- Query 8: Repeat vs Single-Purchase Customer Revenue Breakdown
-- --------------------------------------------------------------------
WITH customer_summary AS (
    SELECT 
        f.customer_key,
        COUNT(DISTINCT f.order_number) AS order_count,
        SUM(f.sales_amount) AS customer_total_spend
    FROM gold.fact_sales f
    GROUP BY f.customer_key
)
SELECT 
    CASE WHEN order_count > 1 THEN 'Repeat Customer' ELSE 'Single-Purchase Customer' END AS customer_type,
    COUNT(customer_key) AS total_customers,
    SUM(order_count) AS total_orders,
    ROUND(SUM(customer_total_spend), 2) AS total_revenue,
    ROUND(AVG(customer_total_spend), 2) AS avg_spend_per_customer
FROM customer_summary
GROUP BY CASE WHEN order_count > 1 THEN 'Repeat Customer' ELSE 'Single-Purchase Customer' END;

-- --------------------------------------------------------------------
-- Query 9: Annual New Customer Acquisition Trends (Account Creation)
-- --------------------------------------------------------------------
SELECT 
    YEAR(c.customer_since_date) AS acquisition_year,
    COUNT(DISTINCT c.customer_id) AS new_customers_acquired,
    COUNT(DISTINCT f.order_number) AS total_orders_placed_by_cohort,
    ROUND(SUM(f.sales_amount), 2) AS total_revenue_by_cohort
FROM gold.dim_customers c
LEFT JOIN gold.fact_sales f ON c.customer_key = f.customer_key
WHERE c.is_current = 1 AND c.customer_since_date IS NOT NULL
GROUP BY YEAR(c.customer_since_date)
ORDER BY acquisition_year;

-- --------------------------------------------------------------------
-- Query 10: Regional Customer Distribution & Spending Patterns
-- --------------------------------------------------------------------
SELECT 
    c.country,
    COUNT(DISTINCT c.customer_id) AS total_unique_customers,
    COUNT(DISTINCT f.order_number) AS total_orders,
    ROUND(SUM(f.sales_amount), 2) AS regional_revenue,
    ROUND(SUM(f.sales_amount) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 2) AS revenue_per_customer
FROM gold.dim_customers c
JOIN gold.fact_sales f ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY regional_revenue DESC;
