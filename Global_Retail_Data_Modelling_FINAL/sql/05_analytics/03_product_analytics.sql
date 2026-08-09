-- ====================================================================
-- Analytics Suite: 03_product_analytics.sql
-- Description: Top/Bottom products, Category performance, product line profitability, and margins.
-- Stage: 05_analytics
-- Dialect: MySQL 8.0+
-- ====================================================================

-- --------------------------------------------------------------------
-- Query 11: Top 10 Performing Products by Sales Revenue
-- --------------------------------------------------------------------
SELECT 
    p.product_id,
    p.product_name,
    p.category_name,
    p.subcategory_name,
    SUM(f.quantity) AS total_units_sold,
    ROUND(SUM(f.sales_amount), 2) AS total_sales_revenue,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND((SUM(f.profit_amount) / NULLIF(SUM(f.sales_amount), 0)) * 100, 2) AS margin_pct
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_id, p.product_name, p.category_name, p.subcategory_name
ORDER BY total_sales_revenue DESC
LIMIT 10;

-- --------------------------------------------------------------------
-- Query 12: Bottom 10 Products by Sales Performance (Low Performers)
-- --------------------------------------------------------------------
SELECT 
    p.product_id,
    p.product_name,
    p.category_name,
    p.subcategory_name,
    SUM(f.quantity) AS total_units_sold,
    ROUND(SUM(f.sales_amount), 2) AS total_sales_revenue,
    ROUND(SUM(f.profit_amount), 2) AS total_profit
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_id, p.product_name, p.category_name, p.subcategory_name
ORDER BY total_sales_revenue ASC
LIMIT 10;

-- --------------------------------------------------------------------
-- Query 13: Product Category & Subcategory Revenue Breakdown
-- --------------------------------------------------------------------
SELECT 
    p.category_name,
    p.subcategory_name,
    COUNT(DISTINCT f.order_number) AS order_count,
    SUM(f.quantity) AS total_units_sold,
    ROUND(SUM(f.sales_amount), 2) AS category_revenue,
    ROUND(SUM(f.profit_amount), 2) AS category_profit,
    ROUND((SUM(f.profit_amount) / NULLIF(SUM(f.sales_amount), 0)) * 100, 2) AS category_margin_pct
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.category_name, p.subcategory_name
ORDER BY p.category_name, category_revenue DESC;

-- --------------------------------------------------------------------
-- Query 14: Product Line Profitability & Cost Margin Analysis
-- --------------------------------------------------------------------
SELECT 
    p.product_line,
    COUNT(DISTINCT p.product_id) AS distinct_products_count,
    SUM(f.quantity) AS units_sold,
    ROUND(SUM(f.sales_amount), 2) AS line_revenue,
    ROUND(SUM(f.cost_amount), 2) AS line_cost,
    ROUND(SUM(f.profit_amount), 2) AS line_profit,
    ROUND((SUM(f.profit_amount) / NULLIF(SUM(f.sales_amount), 0)) * 100, 2) AS line_margin_pct
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY p.product_line
ORDER BY line_revenue DESC;

-- --------------------------------------------------------------------
-- Query 15: High Maintenance vs Low Maintenance Product Performance
-- --------------------------------------------------------------------
SELECT 
    CASE WHEN p.is_maintenance_required = 1 THEN 'Maintenance Required' ELSE 'Standard (No Maintenance)' END AS maintenance_status,
    COUNT(DISTINCT p.product_id) AS total_products,
    SUM(f.quantity) AS total_units_sold,
    ROUND(SUM(f.sales_amount), 2) AS total_revenue,
    ROUND(SUM(f.profit_amount), 2) AS total_profit,
    ROUND(AVG(f.unit_price), 2) AS avg_unit_price
FROM gold.fact_sales f
JOIN gold.dim_products p ON f.product_key = p.product_key
GROUP BY CASE WHEN p.is_maintenance_required = 1 THEN 'Maintenance Required' ELSE 'Standard (No Maintenance)' END;
