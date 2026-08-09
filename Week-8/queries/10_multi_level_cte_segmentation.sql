-- 10: CTE with Multiple Levels for Monthly Revenue Customer Tiering
WITH customer_monthly_revenue AS (
    SELECT 
        o.customer_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_percent / 100.0)) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id != 'UNASSIGNED' AND o.status != 'CANCELLED'
    GROUP BY o.customer_id, DATE_FORMAT(o.order_date, '%Y-%m')
),
customer_categories AS (
    SELECT 
        customer_id,
        order_month,
        monthly_revenue,
        CASE 
            WHEN monthly_revenue > 10000 THEN 'High'
            WHEN monthly_revenue BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS revenue_category
    FROM customer_monthly_revenue
)
SELECT 
    order_month,
    revenue_category,
    COUNT(DISTINCT customer_id) AS customer_count
FROM customer_categories
GROUP BY order_month, revenue_category
ORDER BY order_month, revenue_category;
