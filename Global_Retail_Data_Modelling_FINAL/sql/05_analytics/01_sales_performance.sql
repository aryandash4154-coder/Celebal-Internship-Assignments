-- ====================================================================
-- Analytics Suite: 01_sales_performance.sql
-- Description: Core revenue trends, YoY growth, AOV, and sales volume.
-- Stage: 05_analytics
-- Dialect: MySQL 8.0+
-- ====================================================================

-- --------------------------------------------------------------------
-- Query 1: Monthly Revenue, Cost, Profit, and Profit Margin Trends
-- --------------------------------------------------------------------
SELECT 
    d.year,
    d.month_number,
    d.month_name,
    DATE_FORMAT(d.full_date, '%Y-%m') AS year_month,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.quantity) AS total_units_sold,
    ROUND(SUM(f.sales_amount), 2) AS total_revenue,
    ROUND(SUM(f.cost_amount), 2) AS total_cost,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND((SUM(f.profit_amount) / NULLIF(SUM(f.sales_amount), 0)) * 100, 2) AS profit_margin_pct
FROM gold.fact_sales f
JOIN gold.dim_date d ON f.order_date_key = d.date_key
GROUP BY d.year, d.month_number, d.month_name, DATE_FORMAT(d.full_date, '%Y-%m')
ORDER BY year_month;

-- --------------------------------------------------------------------
-- Query 2: Yearly Revenue Breakdown & Annual Cumulative Metrics
-- --------------------------------------------------------------------
SELECT 
    d.year,
    COUNT(DISTINCT f.order_number) AS total_orders,
    SUM(f.quantity) AS total_quantity,
    ROUND(SUM(f.sales_amount), 2) AS annual_revenue,
    ROUND(SUM(f.profit_amount), 2) AS annual_profit,
    ROUND(AVG(f.sales_amount), 2) AS avg_item_sale_amount
FROM gold.fact_sales f
JOIN gold.dim_date d ON f.order_date_key = d.date_key
GROUP BY d.year
ORDER BY d.year;

-- --------------------------------------------------------------------
-- Query 3: Year-over-Year (YoY) Revenue Growth Rate Analysis
-- --------------------------------------------------------------------
WITH yearly_sales AS (
    SELECT 
        d.year,
        SUM(f.sales_amount) AS current_year_revenue
    FROM gold.fact_sales f
    JOIN gold.dim_date d ON f.order_date_key = d.date_key
    GROUP BY d.year
)
SELECT 
    year,
    ROUND(current_year_revenue, 2) AS current_year_revenue,
    ROUND(LAG(current_year_revenue) OVER (ORDER BY year), 2) AS previous_year_revenue,
    ROUND(current_year_revenue - LAG(current_year_revenue) OVER (ORDER BY year), 2) AS yoy_revenue_change,
    ROUND(
        ((current_year_revenue - LAG(current_year_revenue) OVER (ORDER BY year)) / 
        NULLIF(LAG(current_year_revenue) OVER (ORDER BY year), 0)) * 100, 
        2
    ) AS yoy_growth_pct
FROM yearly_sales
ORDER BY year;

-- --------------------------------------------------------------------
-- Query 4: Average Order Value (AOV) & Units per Order by Month
-- --------------------------------------------------------------------
WITH order_aggregates AS (
    SELECT 
        f.order_number,
        d.year,
        d.month_number,
        DATE_FORMAT(d.full_date, '%Y-%m') AS year_month,
        SUM(f.sales_amount) AS order_total_sales,
        SUM(f.quantity) AS order_total_quantity
    FROM gold.fact_sales f
    JOIN gold.dim_date d ON f.order_date_key = d.date_key
    GROUP BY f.order_number, d.year, d.month_number, DATE_FORMAT(d.full_date, '%Y-%m')
)
SELECT 
    year_month,
    COUNT(order_number) AS order_count,
    ROUND(AVG(order_total_sales), 2) AS average_order_value,
    ROUND(AVG(order_total_quantity), 2) AS avg_units_per_order
FROM order_aggregates
GROUP BY year_month
ORDER BY year_month;

-- --------------------------------------------------------------------
-- Query 5: Sales Quantity & Item Demand Volume Trends over Time
-- --------------------------------------------------------------------
SELECT 
    d.year,
    d.quarter,
    CONCAT('Q', d.quarter, '-', d.year) AS quarter_year,
    SUM(f.quantity) AS units_sold,
    COUNT(DISTINCT f.order_number) AS total_orders,
    ROUND(SUM(f.sales_amount), 2) AS gross_sales
FROM gold.fact_sales f
JOIN gold.dim_date d ON f.order_date_key = d.date_key
GROUP BY d.year, d.quarter, CONCAT('Q', d.quarter, '-', d.year)
ORDER BY d.year, d.quarter;
